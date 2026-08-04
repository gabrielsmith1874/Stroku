sub init()
    m.top.functionName = "execute"
end sub

sub execute()
    result = {
        ok: false
        requestId: m.top.requestId
        statusCode: 0
        text: ""
        error: ""
    }

    transfer = CreateObject("roUrlTransfer")
    transfer.SetUrl(m.top.url.Replace("|", "%7C"))
    transfer.SetCertificatesFile("common:/certs/ca-bundle.crt")
    transfer.InitClientCertificates()
    transfer.RetainBodyOnError(true)
    transfer.EnableEncodings(true)
    transfer.AddHeader("Accept", "text/plain, application/x-subrip, */*")
    transfer.AddHeader("User-Agent", "Stroku/0.1 Roku")

    port = CreateObject("roMessagePort")
    transfer.SetMessagePort(port)
    if not transfer.AsyncGetToString()
        result.error = "The Roku could not start the subtitle request."
        m.top.response = result
        return
    end if

    event = Wait(20000, port)
    if Type(event) <> "roUrlEvent"
        transfer.AsyncCancel()
        result.error = "The subtitle request timed out."
        m.top.response = result
        return
    end if

    result.statusCode = event.GetResponseCode()
    body = event.GetString()
    if result.statusCode < 200 or result.statusCode >= 300
        reason = event.GetFailureReason()
        if reason = invalid or reason = "" then reason = "HTTP " + result.statusCode.ToStr()
        result.error = reason
        m.top.response = result
        return
    end if

    if body = invalid or body = ""
        result.error = "The subtitle response was empty."
        m.top.response = result
        return
    end if

    result.ok = true
    result.text = body
    m.top.response = result
end sub
