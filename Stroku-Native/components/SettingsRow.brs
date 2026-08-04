' One row of the Settings screen.
'
' The same component draws every row kind so the list stays a single MarkupList:
' section headers, plain value rows, on/off toggles, informational rows, and
' actions. Which nodes are visible is decided by the content node's rowKind.

sub init()
    m.focusFrame = m.top.FindNode("focusFrame")
    m.card = m.top.FindNode("card")
    m.accentBar = m.top.FindNode("accentBar")
    m.label = m.top.FindNode("label")
    m.value = m.top.FindNode("value")
    m.togglePill = m.top.FindNode("togglePill")
    m.toggleLabel = m.top.FindNode("toggleLabel")
    m.chevron = m.top.FindNode("chevron")
    m.headerLabel = m.top.FindNode("headerLabel")
    m.headerRule = m.top.FindNode("headerRule")
end sub

sub onContentChanged()
    EnsureUiScale(m.top)

    content = m.top.itemContent
    if content = invalid then return

    kind = content.rowKind
    if kind = "header"
        m.headerLabel.text = UCase(content.title)
        m.headerLabel.visible = true
        m.headerRule.visible = true
        m.card.visible = false
        m.accentBar.visible = false
        m.focusFrame.visible = false
        m.label.visible = false
        m.value.visible = false
        m.togglePill.visible = false
        m.toggleLabel.visible = false
        m.chevron.visible = false
        return
    end if

    m.headerLabel.visible = false
    m.headerRule.visible = false
    m.card.visible = true
    m.label.visible = true
    m.label.text = content.title

    isToggle = kind = "toggle"
    m.togglePill.visible = isToggle
    m.toggleLabel.visible = isToggle
    m.value.visible = not isToggle
    if isToggle
        m.toggleLabel.text = UCase(content.value)
        if content.toggleOn
            m.togglePill.color = "0x2E9E76FF"
        else
            m.togglePill.color = "0x3A3660FF"
        end if
    else
        m.value.text = content.value
    end if

    ' Only rows that do something on OK advertise it.
    m.chevron.visible = content.selectable and not isToggle

    onStateChanged()
end sub

sub onStateChanged()
    content = m.top.itemContent
    if content = invalid then return
    if content.rowKind = "header" then return

    focused = m.top.itemHasFocus
    m.focusFrame.visible = focused
    m.accentBar.visible = focused
    if focused
        m.card.color = "0x2A2450FF"
        m.label.color = "0xFFFFFFFF"
        m.value.color = "0xE7E3FFFF"
        m.chevron.color = "0xC7BCFFFF"
    else
        m.card.color = "0x1B1934FF"
        if content.selectable
            m.label.color = "0xEDEBF5FF"
        else
            m.label.color = "0xB4B0C1FF"
        end if
        m.value.color = "0xB4B0C1FF"
        m.chevron.color = "0x6F6A8AFF"
    end if
end sub
