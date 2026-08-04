sub Main(args as object)
    screen = CreateObject("roSGScreen")
    port = CreateObject("roMessagePort")
    screen.SetMessagePort(port)

    scene = screen.CreateScene("MainScene")
    scene.ObserveField("exitApp", port)
    screen.Show()
    scene.SignalBeacon("AppLaunchComplete")

    setupServer = StartSetupServer(port)
    if setupServer <> invalid
        scene.CallFunc("ShowSetupAddress", { url: setupServer.url })
    else
        scene.CallFunc("ShowSetupAddress", { url: "" })
    end if

    if args <> invalid and args.DoesExist("contentId")
        contentId = args.contentId
        if contentId <> invalid and Left(LCase(contentId), 4) = "http"
            scene.CallFunc("PlayExternal", {
                url: contentId
                title: "External stream"
            })
        end if
    end if

    while true
        message = Wait(0, port)
        if Type(message) = "roSGScreenEvent" and message.IsScreenClosed()
            CloseSetupServer(setupServer)
            return
        else if Type(message) = "roSGNodeEvent" and message.GetField() = "exitApp"
            if scene.exitApp = true
                CloseSetupServer(setupServer)
                return
            end if
        else if Type(message) = "roSocketEvent" and setupServer <> invalid
            HandleSetupSocketEvent(message, setupServer, scene)
        end if
    end while
end sub

function StartSetupServer(port as object) as dynamic
    listenSocket = CreateObject("roStreamSocket")
    listenSocket.SetMessagePort(port)

    address = CreateObject("roSocketAddress")
    address.SetPort(8324)
    listenSocket.SetAddress(address)
    listenSocket.NotifyReadable(true)
    listenSocket.Listen(4)
    if not listenSocket.EOK()
        listenSocket.Close()
        return invalid
    end if

    ipAddress = GetLanIpAddress()
    if ipAddress = "" then
        listenSocket.Close()
        return invalid
    end if

    return {
        listener: listenSocket
        connections: {}
        port: port
        url: "http://" + ipAddress + ":8324"
    }
end function

function GetLanIpAddress() as string
    deviceInfo = CreateObject("roDeviceInfo")
    addresses = deviceInfo.GetIPAddrs()
    for each interfaceName in addresses
        address = addresses[interfaceName]
        if address <> invalid and address <> "" and Left(address, 4) <> "127." and Instr(1, address, ":") = 0
            return address
        end if
    end for
    return ""
end function

sub HandleSetupSocketEvent(event as object, server as object, scene as object)
    socketId = event.GetSocketID()
    if socketId = server.listener.GetID()
        if not server.listener.IsReadable() then return

        connection = server.listener.Accept()
        if connection = invalid then return

        connection.SetMessagePort(server.port)
        connection.NotifyReadable(true)
        server.connections[socketIdKey(connection.GetID())] = {
            socket: connection
            request: ""
        }
        return
    end if

    key = socketIdKey(socketId)
    if not server.connections.DoesExist(key) then return

    state = server.connections[key]
    connection = state.socket
    if connection.IsReadable()
        buffer = CreateObject("roByteArray")
        buffer[16383] = 0
        received = connection.Receive(buffer, 0, 16384)
        if received > 0
            state.request = state.request + Left(buffer.ToAsciiString(), received)
            if IsCompleteHttpRequest(state.request)
                HandleSetupHttpRequest(connection, state.request, scene)
                connection.Close()
                server.connections.Delete(key)
                return
            end if
        else if received = 0
            connection.Close()
            server.connections.Delete(key)
            return
        end if
    end if

    if not connection.EOK()
        connection.Close()
        server.connections.Delete(key)
    end if
end sub

function socketIdKey(socketId as integer) as string
    return socketId.ToStr()
end function

function IsCompleteHttpRequest(request as string) as boolean
    separator = Chr(13) + Chr(10) + Chr(13) + Chr(10)
    headerEnd = Instr(1, request, separator)
    if headerEnd = 0 then return false

    contentLength = GetContentLength(Left(request, headerEnd - 1))
    bodyStart = headerEnd + Len(separator)
    bodyLength = Len(request) - bodyStart + 1
    return bodyLength >= contentLength
end function

function GetContentLength(headers as string) as integer
    for each line in headers.Tokenize(Chr(13) + Chr(10))
        lowerLine = LCase(line)
        if Left(lowerLine, 15) = "content-length:"
            return Val(line.Mid(15).Trim())
        end if
    end for
    return 0
end function

sub HandleSetupHttpRequest(connection as object, request as string, scene as object)
    firstLineEnd = Instr(1, request, Chr(13) + Chr(10))
    if firstLineEnd = 0
        SendHttpResponse(connection, 400, "Bad Request", ErrorPage("Invalid request."))
        return
    end if

    requestLine = Left(request, firstLineEnd - 1)
    if Left(requestLine, 4) = "GET "
        SendHttpResponse(connection, 200, "OK", SetupPage())
        return
    end if

    if Left(requestLine, 5) <> "POST "
        SendHttpResponse(connection, 405, "Method Not Allowed", ErrorPage("Use the setup form to submit the URL."))
        return
    end if

    separator = Chr(13) + Chr(10) + Chr(13) + Chr(10)
    headerEnd = Instr(1, request, separator)
    body = request.Mid(headerEnd + Len(separator) - 1)
    manifestUrl = ReadFormValue(body, "manifest")
    if manifestUrl = ""
        SendHttpResponse(connection, 400, "Bad Request", ErrorPage("A manifest URL is required."))
        return
    end if

    manifestUrl = manifestUrl.Trim()
    if not IsValidSetupManifestUrl(manifestUrl)
        SendHttpResponse(connection, 400, "Bad Request", ErrorPage("Enter a complete HTTPS URL ending in /manifest.json."))
        return
    end if

    scene.configurationUrl = manifestUrl
    SendHttpResponse(connection, 200, "OK", SuccessPage())
end sub

function IsValidSetupManifestUrl(url as string) as boolean
    return Left(LCase(url), 8) = "https://" and Right(LCase(url), 14) = "/manifest.json"
end function

function ReadFormValue(body as string, key as string) as string
    transfer = CreateObject("roUrlTransfer")
    for each pair in body.Tokenize("&")
        equalsAt = Instr(1, pair, "=")
        if equalsAt > 0 and Left(pair, equalsAt - 1) = key
            encoded = pair.Mid(equalsAt)
            return transfer.Unescape(encoded.Replace("+", " "))
        end if
    end for
    return ""
end function

sub SendHttpResponse(connection as object, statusCode as integer, statusText as string, body as string)
    bodyBytes = CreateObject("roByteArray")
    bodyBytes.FromAsciiString(body)
    headers = "HTTP/1.1 " + statusCode.ToStr() + " " + statusText + Chr(13) + Chr(10)
    headers = headers + "Content-Type: text/html; charset=utf-8" + Chr(13) + Chr(10)
    headers = headers + "Content-Length: " + bodyBytes.Count().ToStr() + Chr(13) + Chr(10)
    headers = headers + "Cache-Control: no-store" + Chr(13) + Chr(10)
    headers = headers + "Connection: close" + Chr(13) + Chr(10) + Chr(13) + Chr(10)

    responseBytes = CreateObject("roByteArray")
    responseBytes.FromAsciiString(headers + body)
    connection.Send(responseBytes, 0, responseBytes.Count())
end sub

function SetupPage() as string
    return PageStart("Configure Stroku") + "<h1>Add a Stremio add-on</h1><p>Paste a complete HTTPS Stremio add-on manifest URL below. It is sent directly to this Roku over your local network.</p><form method='post' action='/configure'><label for='manifest'>Add-on manifest URL</label><textarea id='manifest' name='manifest' rows='6' required autofocus placeholder='https://.../manifest.json'></textarea><button type='submit'>Add to Roku</button></form>" + PageEnd()
end function

function SuccessPage() as string
    return PageStart("Sent to Roku") + "<h1>Sent to Roku</h1><p>Stroku is verifying the add-on and will save it if the manifest is supported. Check the TV for the result.</p>" + PageEnd()
end function

function ErrorPage(message as string) as string
    return PageStart("Stroku setup error") + "<h1>Could not save</h1><p>" + message + "</p><p><a href='/'>Return to setup</a></p>" + PageEnd()
end function

function PageStart(title as string) as string
    return "<!doctype html><html><head><meta charset='utf-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>" + title + "</title><style>body{margin:0;background:#0f0f23;color:#fff;font:18px system-ui,sans-serif}main{max-width:680px;margin:0 auto;padding:36px 22px}h1{color:#66d9e8}p{line-height:1.55;color:#d4d2e5}label{display:block;margin:28px 0 10px;font-weight:700}textarea{box-sizing:border-box;width:100%;padding:14px;border:2px solid #555577;border-radius:8px;background:#1a1a2e;color:#fff;font:16px monospace}button{width:100%;margin-top:18px;padding:15px;border:0;border-radius:8px;background:#9966ff;color:#fff;font-size:18px;font-weight:700}a{color:#66d9e8}</style></head><body><main>"
end function

function PageEnd() as string
    return "</main></body></html>"
end function

sub CloseSetupServer(server as dynamic)
    if server = invalid then return
    for each key in server.connections
        server.connections[key].socket.Close()
    end for
    server.listener.Close()
end sub
