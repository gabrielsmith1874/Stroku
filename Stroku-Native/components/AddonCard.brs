' One card of the Addons screen.
'
' The layout follows Stremio's web add-on rows: logo, name, version, type line,
' one line of description, and a status control on the right. The same component
' also draws the screen's empty, loading and call-to-action rows, picked by
' rowKind on AddonCardContent, so the list stays a single MarkupList.

sub init()
    m.focusFrame = m.top.FindNode("focusFrame")
    m.card = m.top.FindNode("card")
    m.accentBar = m.top.FindNode("accentBar")
    m.logoTile = m.top.FindNode("logoTile")
    m.logoLetter = m.top.FindNode("logoLetter")
    m.logo = m.top.FindNode("logo")
    m.name = m.top.FindNode("name")
    m.version = m.top.FindNode("version")
    m.types = m.top.FindNode("types")
    m.description = m.top.FindNode("description")
    m.badgePill = m.top.FindNode("badgePill")
    m.badgeLabel = m.top.FindNode("badgeLabel")
    m.messageLabel = m.top.FindNode("messageLabel")
end sub

sub onContentChanged()
    ' Cards are created and recycled by the list long after the scene resolved
    ' its scale, so the check happens on every content binding.
    EnsureUiScale(m.top)

    content = m.top.itemContent
    if content = invalid then return

    if content.rowKind = "message"
        m.messageLabel.visible = true
        m.messageLabel.text = content.description
        m.logoTile.visible = false
        m.logoLetter.visible = false
        m.logo.visible = false
        m.name.visible = false
        m.version.visible = false
        m.types.visible = false
        m.description.visible = false
        m.badgePill.visible = false
        m.badgeLabel.visible = false
        onStateChanged()
        return
    end if

    m.messageLabel.visible = false
    m.logoTile.visible = true
    m.name.visible = true
    m.version.visible = true
    m.types.visible = true
    m.description.visible = true
    m.badgePill.visible = true
    m.badgeLabel.visible = true

    m.name.text = content.title
    m.version.text = content.version
    m.types.text = content.types
    m.description.text = content.description

    logoUri = content.logoUri
    if logoUri <> ""
        m.logo.uri = logoUri
        m.logo.visible = true
        m.logoLetter.visible = false
    else
        m.logo.uri = ""
        m.logo.visible = false
        m.logoLetter.visible = true
        m.logoLetter.text = AddonInitial(content.title)
    end if

    m.badgeLabel.text = UCase(content.badge)
    if content.badgeKind = "installed"
        m.badgePill.color = "0x2E9E76FF"
    else
        m.badgePill.color = "0x4C3FA0FF"
    end if

    onStateChanged()
end sub

' The first letter of the add-on name, which is manifest text and stays as the
' add-on author wrote it.
function AddonInitial(name as string) as string
    trimmed = name.Trim()
    if trimmed = "" then return "?"
    return UCase(Left(trimmed, 1))
end function

sub onStateChanged()
    content = m.top.itemContent
    if content = invalid then return

    focused = m.top.itemHasFocus
    m.focusFrame.visible = focused
    ' The accent bar marks a row OK can act on. A loading row is a placeholder,
    ' so it never gets one even while focus is resting on it.
    m.accentBar.visible = focused and content.selectable
    if focused
        m.card.color = "0x2A2450FF"
        m.name.color = "0xFFFFFFFF"
        m.description.color = "0xD6D2E4FF"
        m.messageLabel.color = "0xFFFFFFFF"
    else
        m.card.color = "0x1B1934FF"
        if content.selectable
            m.name.color = "0xEDEBF5FF"
        else
            m.name.color = "0xB4B0C1FF"
        end if
        m.description.color = "0x9895AAFF"
        ' An actionable empty state ("Load the collection", "Add addon") is drawn
        ' in the accent colour so it does not read as inert copy.
        if content.selectable
            m.messageLabel.color = "0xC7BCFFFF"
        else
            m.messageLabel.color = "0xB4B0C1FF"
        end if
    end if
end sub
