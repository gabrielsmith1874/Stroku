sub init()
    m.thumbnail = m.top.FindNode("thumbnail")
    m.thumbnailScrim = m.top.FindNode("thumbnailScrim")
    m.number = m.top.FindNode("number")
    m.title = m.top.FindNode("title")
    m.date = m.top.FindNode("date")
    m.description = m.top.FindNode("description")
    m.focusFrame = m.top.FindNode("focusFrame")
end sub

sub onContentChanged()
    EnsureUiScale(m.top)

    content = m.top.itemContent
    if content = invalid then return

    m.thumbnail.uri = content.HDPosterUrl
    if m.thumbnailScrim <> invalid
        m.thumbnailScrim.visible = content.DoesExist("blurThumbnail") and content.blurThumbnail
    end if
    m.number.text = content.episodeLabel
    m.title.text = content.title
    m.date.text = formatDate(content.shortDescriptionLine1)
    m.description.text = content.description

    progressBarBg = m.top.FindNode("progressBarBg")
    progressBarFill = m.top.FindNode("progressBarFill")
    if progressBarBg <> invalid and progressBarFill <> invalid
        if content.DoesExist("progress") and content.progress > 0.0 and content.progress < 1.0
            progressBarBg.visible = true
            progressBarFill.visible = true
            progressBarFill.width = ScaleUi(260 * content.progress)
        else
            progressBarBg.visible = false
            progressBarFill.visible = false
        end if
    end if
end sub

' The air date is an ISO string from the add-on. The month name and the order of
' the three parts are Stroku's own presentation, so both come from the locale
' table rather than from this file.
function formatDate(value as string) as string
    if Len(value) < 10 then return value
    months = ["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"]
    month = Val(Mid(value, 6, 2))
    day = Val(Mid(value, 9, 2))
    if month < 1 or month > 12 then return value

    text = TrText("calendar.dateLong")
    text = LocaleReplace(text, "{month}", TrText("calendar.month." + months[month - 1]))
    text = LocaleReplace(text, "{day}", day.ToStr())
    text = LocaleReplace(text, "{year}", Left(value, 4))
    return text
end function

sub onFocusChanged()
    m.focusFrame.visible = m.top.itemHasFocus
end sub
