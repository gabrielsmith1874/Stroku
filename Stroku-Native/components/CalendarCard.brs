' One row of the Calendar screen.
'
' A single component draws every row kind so the screen stays one MarkupList:
' section captions, dated episode cards, inert copy, and the signed-out call to
' action. Which nodes are visible is decided by the content node's rowKind.

sub init()
    m.focusFrame = m.top.FindNode("focusFrame")
    m.card = m.top.FindNode("card")
    m.dateChip = m.top.FindNode("dateChip")
    m.dayLabel = m.top.FindNode("dayLabel")
    m.monthLabel = m.top.FindNode("monthLabel")
    m.thumbnail = m.top.FindNode("thumbnail")
    m.seriesLabel = m.top.FindNode("seriesLabel")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.metaLabel = m.top.FindNode("metaLabel")
    m.chevron = m.top.FindNode("chevron")
    m.headerLabel = m.top.FindNode("headerLabel")
    m.headerRule = m.top.FindNode("headerRule")
    m.messageLabel = m.top.FindNode("messageLabel")
    m.ctaPill = m.top.FindNode("ctaPill")
    m.ctaLabel = m.top.FindNode("ctaLabel")
end sub

sub onContentChanged()
    ' Recycled cards can outlive a scale change, so every binding re-checks.
    EnsureUiScale(m.top)

    content = m.top.itemContent
    if content = invalid then return

    kind = content.rowKind
    ShowCalendarEpisodeNodes(kind = "episode")
    m.headerLabel.visible = kind = "header"
    m.headerRule.visible = kind = "header"
    m.messageLabel.visible = kind = "message"
    m.ctaPill.visible = kind = "cta"
    m.ctaLabel.visible = kind = "cta"
    m.card.visible = kind = "episode"
    m.focusFrame.visible = false

    if kind = "header"
        m.headerLabel.text = UCase(content.title)
        return
    end if

    if kind = "message"
        m.messageLabel.text = content.title
        return
    end if

    if kind = "cta"
        m.ctaLabel.text = content.title
        onStateChanged()
        return
    end if

    m.dayLabel.text = content.dayText
    m.monthLabel.text = content.monthText
    m.thumbnail.uri = content.thumbnailUrl
    m.seriesLabel.text = content.seriesName
    m.titleLabel.text = content.title
    m.metaLabel.text = content.metaText
    m.chevron.visible = content.selectable
    onStateChanged()
end sub

sub ShowCalendarEpisodeNodes(visible as boolean)
    m.dateChip.visible = visible
    m.dayLabel.visible = visible
    m.monthLabel.visible = visible
    m.thumbnail.visible = visible
    m.seriesLabel.visible = visible
    m.titleLabel.visible = visible
    m.metaLabel.visible = visible
    m.chevron.visible = visible
end sub

sub onStateChanged()
    content = m.top.itemContent
    if content = invalid then return

    kind = content.rowKind
    if kind = "header" or kind = "message" then return

    focused = m.top.itemHasFocus
    if kind = "cta"
        if focused
            m.ctaPill.color = "0x9D86FFFF"
        else
            m.ctaPill.color = "0x7657FFFF"
        end if
        return
    end if

    m.focusFrame.visible = focused
    if focused
        m.card.color = "0x2A2450FF"
        m.titleLabel.color = "0xFFFFFFFF"
        m.metaLabel.color = "0xE7E3FFFF"
        m.chevron.color = "0xC7BCFFFF"
    else
        m.card.color = "0x1B1934FF"
        m.titleLabel.color = "0xEDEBF5FF"
        m.metaLabel.color = "0xB4B0C1FF"
        m.chevron.color = "0x6F6A8AFF"
    end if

    ' Today's episodes keep the accent chip whether or not they are focused; it
    ' is the one date on the screen that is worth finding without reading.
    if content.accent
        m.dateChip.color = "0x7657FFFF"
        m.monthLabel.color = "0xFFFFFFFF"
    else if focused
        m.dateChip.color = "0x352E63FF"
        m.monthLabel.color = "0xC7BCFFFF"
    else
        m.dateChip.color = "0x241F45FF"
        m.monthLabel.color = "0x9D86FFFF"
    end if
end sub
