sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    result = {
        ok: false
        requestId: m.top.requestId
        statusCode: 0
        data: invalid
        error: ""
    }

    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(NormalizeRequestUrl(m.top.url))
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.RetainBodyOnError(true)
    transfer.EnableEncodings(true)
    transfer.AddHeader("Accept", "application/json")
    transfer.AddHeader("User-Agent", "Stroku/0.1 Roku")
    if UCase(m.top.method) = "POST"
        transfer.AddHeader("Content-Type", "application/json")
    end if
    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)

    requestStarted = false
    if UCase(m.top.method) = "POST"
        requestStarted = transfer.AsyncPostFromString(m.top.body)
    else
        requestStarted = transfer.AsyncGetToString()
    end if

    if not requestStarted
        result.error = "The Roku could not start the addon request."
        m.top.response = result
        return
    end if

    timeoutMs = m.top.timeoutMs
    if timeoutMs <= 0 then timeoutMs = 15000
    event = Wait(timeoutMs, port)
    if Type(event) <> "roUrlEvent"
        transfer.AsyncCancel()
        timeoutSeconds = Int(timeoutMs / 1000)
        result.error = AppendRequestHost("The addon request timed out after " + timeoutSeconds.ToStr() + " seconds.", m.top.url)
        m.top.response = result
        return
    end if

    result.statusCode = event.GetResponseCode()
    body = event.GetString()

    if result.statusCode < 200 or result.statusCode >= 300
        reason = event.GetFailureReason()
        if reason = invalid or reason = ""
            reason = "HTTP " + result.statusCode.ToStr()
        else
            reason = "HTTP " + result.statusCode.ToStr() + ": " + reason
        end if
        ' Name the host. Several add-ons and Stremio services are queried for one
        ' search, so an unattributed status code says nothing about which to fix.
        result.error = AppendRequestHost(reason, m.top.url)
        m.top.response = result
        return
    end if

    if body = invalid or body = ""
        result.error = "The addon returned an empty HTTP " + result.statusCode.ToStr() + " response."
        m.top.response = result
        return
    end if

    parsed = ParseJson(body)
    if parsed = invalid
        result.error = "The addon returned invalid JSON with HTTP " + result.statusCode.ToStr() + "."
        m.top.response = result
        return
    end if

    result.ok = true
    result.data = parsed
    m.top.response = result
end sub

function NormalizeRequestUrl(url as string) as string
    return url.Replace("|", "%7C")
end function

' Host only, never the full URL: a configured add-on path can carry a private
' debrid token, and this string reaches the on-screen status message.
function RequestHost(url as string) as string
    marker = "://"
    start = Instr(1, url, marker)
    if start <= 0 then return ""
    rest = Mid(url, start + Len(marker))
    slash = Instr(1, rest, "/")
    if slash > 0 then rest = Left(rest, slash - 1)
    return rest
end function

function AppendRequestHost(message as string, url as string) as string
    host = RequestHost(url)
    if host = "" then return message
    return message + " (" + host + ")"
end function
