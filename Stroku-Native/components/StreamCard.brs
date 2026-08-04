sub init()
    m.focusFrame = m.top.FindNode("focusFrame")
    m.focusAccent = m.top.FindNode("focusAccent")
    m.sourceBadge = m.top.FindNode("sourceBadge")
    m.addonName = m.top.FindNode("addonName")
    m.quality = m.top.FindNode("quality")
    m.title = m.top.FindNode("title")
    m.seeds = m.top.FindNode("seeds")
    m.seedsIcon = m.top.FindNode("seedsIcon")
    m.size = m.top.FindNode("size")
    m.sizeIcon = m.top.FindNode("sizeIcon")
    m.tracker = m.top.FindNode("tracker")
    m.trackerIcon = m.top.FindNode("trackerIcon")
end sub

sub onContentChanged()
    EnsureUiScale(m.top)

    content = m.top.itemContent
    if content = invalid then return

    m.sourceBadge.text = SafeText(content, "sourceBadge")
    m.addonName.text = SafeText(content, "addonName")
    m.quality.text = SafeText(content, "quality")
    m.title.text = SafeText(content, "title")

    ' Dynamically position and toggle metadata elements
    seedsText = SafeText(content, "seeds")
    sizeText = SafeText(content, "sizeText")
    trackerText = SafeText(content, "tracker")

    ' startX walks along the row in design space; only the assignments are scaled.
    startX = 280

    if seedsText <> ""
        m.seeds.text = seedsText
        m.seedsIcon.visible = true
        m.seeds.visible = true
        m.seedsIcon.translation = ScaleUiXY(startX, 84)
        m.seeds.translation = ScaleUiXY(startX + 28, 82)
        startX = startX + 28 + UnscaleUi(m.seeds.width) + 24
    else
        m.seeds.text = ""
        m.seedsIcon.visible = false
        m.seeds.visible = false
    end if

    if sizeText <> ""
        m.size.text = sizeText
        m.sizeIcon.visible = true
        m.size.visible = true
        m.sizeIcon.translation = ScaleUiXY(startX, 84)
        m.size.translation = ScaleUiXY(startX + 28, 82)
        startX = startX + 28 + UnscaleUi(m.size.width) + 24
    else
        m.size.text = ""
        m.sizeIcon.visible = false
        m.size.visible = false
    end if

    if trackerText <> ""
        m.tracker.text = trackerText
        m.trackerIcon.visible = true
        m.tracker.visible = true
        m.trackerIcon.translation = ScaleUiXY(startX, 84)
        m.tracker.translation = ScaleUiXY(startX + 28, 82)
    else
        m.tracker.text = ""
        m.trackerIcon.visible = false
        m.tracker.visible = false
    end if
end sub

sub onFocusChanged()
    focused = m.top.itemHasFocus
    m.focusFrame.visible = focused
    m.focusAccent.visible = focused
end sub

function SafeText(content as object, key as string) as string
    if content = invalid then return ""
    if not content.DoesExist(key) then return ""
    value = content[key]
    if value = invalid then return ""
    return value.ToStr()
end function
