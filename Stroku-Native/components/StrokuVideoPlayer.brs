sub init()
    m.overlay = m.top.FindNode("overlay")
    m.titleLabel = m.top.FindNode("titleLabel")
    m.timeLabel = m.top.FindNode("timeLabel")
    m.progressFill = m.top.FindNode("progressFill")
    m.buttonFocus = m.top.FindNode("buttonFocus")
    m.buttonFocusTop = m.top.FindNode("buttonFocusTop")
    m.buttonFocusBottom = m.top.FindNode("buttonFocusBottom")
    m.buttonFocusLeft = m.top.FindNode("buttonFocusLeft")
    m.buttonFocusRight = m.top.FindNode("buttonFocusRight")
    m.playButton = m.top.FindNode("playButton")
    m.audioButton = m.top.FindNode("audioButton")
    m.subtitleButton = m.top.FindNode("subtitleButton")
    m.nextButton = m.top.FindNode("nextButton")
    m.speedButton = m.top.FindNode("speedButton")
    m.speedMenu = m.top.FindNode("speedMenu")
    m.speedList = m.top.FindNode("speedList")
    m.audioMenu = m.top.FindNode("audioMenu")
    m.audioList = m.top.FindNode("audioList")
    m.subtitleMenu = m.top.FindNode("subtitleMenu")
    m.subtitleList = m.top.FindNode("subtitleList")
    m.subtitleSyncLabel = m.top.FindNode("subtitleSyncLabel")
    m.customSubtitleGroup = m.top.FindNode("customSubtitleGroup")
    m.customSubtitleBackdrop = m.top.FindNode("customSubtitleBackdrop")
    m.customSubtitleLabel = m.top.FindNode("customSubtitleLabel")
    m.customSubtitleOutlineLabels = []
    for outlineIndex = 0 to 7
        outlineLabel = m.top.FindNode("customSubtitleOutline" + outlineIndex.ToStr())
        if outlineLabel <> invalid then m.customSubtitleOutlineLabels.Push(outlineLabel)
    end for
    m.hideTimer = m.top.FindNode("hideTimer")
    m.scrubGroup = m.top.FindNode("scrubGroup")
    m.scrubTooltip = m.top.FindNode("scrubTooltip")
    m.scrubTooltipTitle = m.top.FindNode("scrubTooltipTitle")
    m.scrubTooltipTime = m.top.FindNode("scrubTooltipTime")
    m.scrubCursor = m.top.FindNode("scrubCursor")
    m.controlButtonsGroup = m.top.FindNode("controlButtonsGroup")
    m.progressGroup = m.top.FindNode("progressGroup")
    m.panelBg = m.top.FindNode("panelBg")
    m.playerUiRoot = m.top.FindNode("playerUiRoot")

    ' The overlay menu headings are authored in English in the XML so the layout
    ' stays readable; the active language wins as soon as the player is created.
    ApplyPlayerChromeText()

    m.buttons = [
        ["play", "next"],
        ["subtitles", "speed", "audio"]
    ]
    m.buttonTranslations = [
        [[100, 860], [200, 860]],
        [[100, 985], [180, 985], [260, 985]]
    ]
    m.buttonSizes = [
        [[80, 80], [80, 80]],
        [[50, 50], [50, 50], [50, 50]]
    ]
    m.focusedRow = 0
    m.focusedCol = 0
    m.currentPlaybackSpeed = 1.0
    m.mode = "hidden"
    m.scrubTarget = -1
    m.speedMenuOpen = false
    m.audioMenuOpen = false
    m.subtitleMenuOpen = false
    m.customSubtitleCues = []
    m.customSubtitleText = ""
    m.subtitleLoadSequence = 0
    m.subtitleDefaultsApplied = false

    if m.top.subtitleOptions = invalid then m.top.subtitleOptions = []
    m.top.enableUI = false
    m.top.enableTrickPlay = false
    m.top.notificationInterval = 1

    m.top.ObserveField("position", "onPositionChanged")
    m.top.ObserveField("duration", "onDurationChanged")
    m.top.ObserveField("state", "onPlayerStateChanged")
    m.top.ObserveField("availableAudioTracks", "onAudioTracksChanged")
    m.top.ObserveField("currentAudioTrack", "onAudioTracksChanged")
    m.top.ObserveField("audioTrack", "onAudioTracksChanged")
    m.top.ObserveField("subtitleOptions", "onSubtitleOptionsChanged")
    m.speedList.ObserveField("itemSelected", "onSpeedSelected")
    m.audioList.ObserveField("itemSelected", "onAudioSelected")
    m.subtitleList.ObserveField("itemSelected", "onSubtitleSelected")
    m.hideTimer.ObserveField("fire", "onHideTimerFire")
    applyCustomSubtitleStyle()
    updateButtons()
end sub

' Called by MainScene once the scene has resolved the device scale, and again
' whenever the user changes the manual scale. The player's own init runs before
' the scene has published anything, so the work cannot happen there.
sub ApplyUiScale(args as object)
    if m.playerUiRoot = invalid then return
    m.playerUiRoot.translation = [UiScaleOffsetX(), UiScaleOffsetY()]
    EnsureUiScale(m.playerUiRoot)
    applyCustomSubtitleStyle()
    updateProgress()
    updateButtons()
end sub

' The player is part of the scene tree, so its init() runs before MainScene has
' read the stored language. MainScene calls this once the language is published,
' and again whenever Settings changes it.
sub ApplyLocale(args as object)
    ApplyPlayerChromeText()
    if m.top.subtitleOptions <> invalid then rebuildSubtitleMenu()
    rebuildAudioMenu()
end sub

' Translates the overlay chrome the XML authored in English. Only the headings
' are Stroku's own; every list row below them is add-on or stream metadata.
sub ApplyPlayerChromeText()
    speedTitle = m.top.FindNode("speedMenuTitle")
    if speedTitle <> invalid then speedTitle.text = TrText("player.menu.speed")
    audioTitle = m.top.FindNode("audioMenuTitle")
    if audioTitle <> invalid then audioTitle.text = TrText("player.menu.audio")
    subtitleTitle = m.top.FindNode("subtitleMenuTitle")
    if subtitleTitle <> invalid then subtitleTitle.text = TrText("player.menu.subtitles")
    updateSubtitleSyncLabel()
end sub

sub onSubtitleOptionsChanged()
    if m.top.subtitleOptions = invalid then return
    rebuildSubtitleMenu()
end sub

sub rebuildSubtitleMenu()
    content = CreateObject("roSGNode", "ContentNode")
    if m.top.subtitleOptions.Count() = 0
        empty = content.CreateChild("ContentNode")
        empty.title = TrText("player.subtitles.none")
    else
        child = content.CreateChild("ContentNode")
        if m.top.selectedSubtitleIndex = -1
            child.title = "* " + TrText("common.off")
        else
            child.title = TrText("common.off")
        end if
        for index = 0 to m.top.subtitleOptions.Count() - 1
            subtitle = m.top.subtitleOptions[index]
            child = content.CreateChild("ContentNode")
            if index = m.top.selectedSubtitleIndex
                child.title = "* " + subtitle.label
            else
                child.title = subtitle.label
            end if
        end for
    end if
    m.subtitleList.content = content
    updateSubtitleSyncLabel()
    updateButtons()
end sub

sub ApplyDefaultSubtitle()
    if m.subtitleDefaultsApplied then return
    if m.top.subtitleOptions = invalid then return
    if m.top.subtitleDefaultMode = "Last selected"
        m.subtitleDefaultsApplied = true
        if m.top.lastSubtitleSelection <> "off" and m.top.subtitleOptions.Count() > 0
            preferredIndex = PreferredSubtitleIndex(m.top.lastSubtitleSelection)
            if preferredIndex >= 0
                enableSubtitle(preferredIndex)
                rebuildSubtitleMenu()
            end if
        end if
        return
    end if
    if m.top.subtitlesEnabledByDefault and m.top.defaultSubtitleLanguage <> "None" and m.top.selectedSubtitleIndex = -1 and m.top.subtitleOptions.Count() > 0
        m.subtitleDefaultsApplied = true
        enableSubtitle(DefaultSubtitleIndex())
        rebuildSubtitleMenu()
    end if
end sub

sub onAudioTracksChanged()
    ApplyDefaultAudioTrack()
    if m.audioMenuOpen then rebuildAudioMenu()
    updateButtons()
end sub

sub rebuildAudioMenu()
    content = CreateObject("roSGNode", "ContentNode")
    tracks = m.top.availableAudioTracks
    if tracks = invalid or tracks.Count() = 0
        empty = content.CreateChild("ContentNode")
        empty.title = TrText("player.audio.none")
    else
        currentTrack = CurrentAudioTrackName()
        for index = 0 to tracks.Count() - 1
            track = tracks[index]
            child = content.CreateChild("ContentNode")
            label = AudioTrackLabel(track, index)
            if AudioTrackName(track, index) = currentTrack
                child.title = "* " + label
            else
                child.title = label
            end if
        end for
    end if
    m.audioList.content = content
end sub

sub onPlayerStateChanged()
    state = m.top.state
    if state = "playing"
        ApplyDefaultSubtitle()
        m.playButton.uri = "pkg:/images/icon_pause.png"
    else if state = "paused"
        m.playButton.uri = "pkg:/images/icon_play.png"
        if m.mode = "hidden" then showOverlay()
    else if state = "finished" or state = "stopped"
        m.scrubGroup.visible = false
        m.overlay.visible = false
        m.speedMenu.visible = false
        m.speedMenuOpen = false
        m.audioMenu.visible = false
        m.audioMenuOpen = false
        m.subtitleMenu.visible = false
        m.subtitleMenuOpen = false
        m.subtitleDefaultsApplied = false
        clearCustomSubtitle()
    end if
end sub


sub onPositionChanged()
    updateProgress()
    updateCustomSubtitle()
end sub

sub onDurationChanged()
    updateProgress()
end sub

sub updateProgress()
    if m.mode = "scrubbing"
        updateScrubPreview()
        return
    end if
    position = m.top.position
    duration = m.top.duration
    if position < 0 then position = 0
    if duration < 0 then duration = 0

    width = 0
    if duration > 0
        width = Int(1720 * position / duration)
        if width > 1720 then width = 1720
    end if
    m.progressFill.width = ScaleUi(width)
    m.timeLabel.text = FormatPlaybackTime(position) + " / " + FormatPlaybackTime(duration)
end sub

sub showOverlay()
    m.speedMenu.visible = false
    m.speedMenuOpen = false
    m.audioMenu.visible = false
    m.audioMenuOpen = false
    m.subtitleMenu.visible = false
    m.subtitleMenuOpen = false
    m.scrubGroup.visible = false
    m.overlay.visible = true
    if m.controlButtonsGroup <> invalid then m.controlButtonsGroup.visible = true
    if m.progressGroup <> invalid then m.progressGroup.translation = [0, 0]
    if m.titleLabel <> invalid then m.titleLabel.visible = true
    m.mode = "overlay"
    if m.top.content <> invalid then m.titleLabel.text = m.top.content.title
    updateProgress()
    updateButtons()
    restartHideTimer()
end sub

sub hideOverlay()
    if m.top.state = "paused" then return
    m.overlay.visible = false
    m.scrubGroup.visible = false
    m.mode = "hidden"
end sub

sub onHideTimerFire()
    if m.mode = "overlay" then hideOverlay()
end sub

sub restartHideTimer()
    m.hideTimer.control = "stop"
    m.hideTimer.control = "start"
end sub

sub enterScrubMode()
    m.hideTimer.control = "stop"
    m.mode = "scrubbing"
    m.scrubTarget = m.top.position
    m.scrubGroup.visible = true
    m.overlay.visible = true
    if m.controlButtonsGroup <> invalid then m.controlButtonsGroup.visible = false
    if m.progressGroup <> invalid then m.progressGroup.translation = [0, 0]
    if m.titleLabel <> invalid then m.titleLabel.visible = false
    updateProgress()
    updateScrubPreview()
end sub

sub exitScrubMode(commit as boolean)
    if commit and m.scrubTarget >= 0
        target = m.scrubTarget
        if m.top.duration > 0 and target > m.top.duration then target = m.top.duration
        if target < 0 then target = 0
        m.top.seek = target
    end if
    m.scrubGroup.visible = false
    m.scrubCursor.visible = false
    m.scrubTarget = -1
    if m.controlButtonsGroup <> invalid then m.controlButtonsGroup.visible = true
    if m.progressGroup <> invalid then m.progressGroup.translation = [0, 0]
    if m.titleLabel <> invalid then m.titleLabel.visible = true
    m.mode = "overlay"
    updateProgress()
    restartHideTimer()
end sub

sub commitScrub()
    if m.scrubTarget < 0 then return
    target = m.scrubTarget
    if m.top.duration > 0 and target > m.top.duration then target = m.top.duration
    if target < 0 then target = 0
    m.top.seek = target
    m.scrubTarget = target
    if m.scrubPreview <> invalid and m.scrubPreview.content <> invalid
        m.scrubPreview.seek = target
    end if
end sub

sub scrubBy(seconds as integer)
    if m.scrubTarget < 0 then m.scrubTarget = m.top.position
    m.scrubTarget = m.scrubTarget + seconds
    if m.scrubTarget < 0 then m.scrubTarget = 0
    if m.top.duration > 0 and m.scrubTarget > m.top.duration then m.scrubTarget = m.top.duration
    updateScrubPreview()
end sub

sub updateScrubPreview()
    duration = m.top.duration
    position = m.scrubTarget
    if position < 0 then position = m.top.position
    if duration <= 0 then duration = 1

    progressWidth = Int(1720 * position / duration)
    if progressWidth < 0 then progressWidth = 0
    if progressWidth > 1720 then progressWidth = 1720
    m.scrubCursor.translation = ScaleUiXY(100 + progressWidth - 2, 953)
    m.scrubCursor.height = ScaleUi(20)
    m.scrubCursor.visible = true

    cursorCenter = 100 + progressWidth
    tooltipWidth = 320
    tooltipX = cursorCenter - 160
    if tooltipX < 100 then tooltipX = 100
    if tooltipX + tooltipWidth > 1820 then tooltipX = 1820 - tooltipWidth
    m.scrubTooltip.translation = ScaleUiXY(tooltipX, 870)
    m.scrubTooltip.width = ScaleUi(tooltipWidth)

    m.scrubTooltipTime.text = FormatPlaybackTime(position) + " / " + FormatPlaybackTime(duration)

    delta = position - m.top.position
    if delta > 0
        m.scrubTooltipTitle.text = TrFormat("player.scrub.ahead", "+" + FormatPlaybackTime(delta))
    else if delta < 0
        m.scrubTooltipTitle.text = TrFormat("player.scrub.back", "-" + FormatPlaybackTime(-delta))
    else
        m.scrubTooltipTitle.text = TrText("player.scrub.currentPosition")
    end if
end sub

sub updateButtons()
    focusTranslation = m.buttonTranslations[m.focusedRow][m.focusedCol]
    m.buttonFocus.translation = ScaleUiXY(focusTranslation[0], focusTranslation[1])
    focusWidth = m.buttonSizes[m.focusedRow][m.focusedCol][0]
    focusHeight = m.buttonSizes[m.focusedRow][m.focusedCol][1]
    updateButtonFocusBorder(focusWidth, focusHeight)
    hasAudioTracks = HasAlternateAudioTracks()
    if hasAudioTracks
        m.audioButton.blendColor = "0xFFFFFFFF"
    else
        m.audioButton.blendColor = "0x9D92C7FF"
    end if
    hasSubs = m.top.subtitleOptions <> invalid and m.top.subtitleOptions.Count() > 0
    if hasSubs
        m.subtitleButton.blendColor = "0xFFFFFFFF"
    else
        m.subtitleButton.blendColor = "0x9D92C7FF"
    end if
    if m.top.hasNextEpisode
        m.nextButton.blendColor = "0xFFFFFFFF"
    else
        m.nextButton.blendColor = "0x9D92C7FF"
    end if
    
    ' Speed button is always active
    m.speedButton.blendColor = "0xFFFFFFFF"
end sub

' width and height arrive in design space; the 3px stroke matches the XML.
sub updateButtonFocusBorder(width as integer, height as integer)
    m.buttonFocusTop.width = ScaleUi(width)
    m.buttonFocusBottom.translation = ScaleUiXY(0, height - 3)
    m.buttonFocusBottom.width = ScaleUi(width)
    m.buttonFocusLeft.height = ScaleUi(height)
    m.buttonFocusRight.translation = ScaleUiXY(width - 3, 0)
    m.buttonFocusRight.height = ScaleUi(height)
end sub

sub moveButton(direction as integer)
    row = m.buttons[m.focusedRow]
    index = m.focusedCol
    for attempt = 1 to row.Count()
        index = index + direction
        if index < 0 then index = row.Count() - 1
        if index >= row.Count() then index = 0
        if ButtonEnabled(m.focusedRow, index)
            m.focusedCol = index
            updateButtons()
            restartHideTimer()
            return
        end if
    end for
end sub

sub switchRow(newRow as integer)
    if newRow < 0 or newRow >= m.buttons.Count() then return
    
    m.focusedRow = newRow
    m.focusedCol = 0
    
    row = m.buttons[m.focusedRow]
    for i = 0 to row.Count() - 1
        if ButtonEnabled(m.focusedRow, i)
            m.focusedCol = i
            exit for
        end if
    end for
    updateButtons()
    restartHideTimer()
end sub

function ButtonEnabled(rowIndex as integer, colIndex as integer) as boolean
    button = m.buttons[rowIndex][colIndex]
    if button = "audio" then return HasAlternateAudioTracks()
    if button = "subtitles" then return m.top.subtitleOptions <> invalid and m.top.subtitleOptions.Count() > 0
    if button = "next" then return m.top.hasNextEpisode
    return true
end function

sub activateButton()
    button = m.buttons[m.focusedRow][m.focusedCol]
    if button = "play"
        togglePlayPause()
    else if button = "speed"
        openSpeedMenu()
    else if button = "audio"
        openAudioMenu()
    else if button = "subtitles"
        openSubtitleMenu()
    else if button = "next"
        m.top.action = { type: "next" }
    end if
end sub

sub togglePlayPause()
    if m.top.state = "paused"
        m.top.control = "resume"
        m.playButton.uri = "pkg:/images/icon_pause.png"
    else
        m.top.control = "pause"
        m.playButton.uri = "pkg:/images/icon_play.png"
    end if
    restartHideTimer()
end sub

sub openSpeedMenu()
    m.hideTimer.control = "stop"
    m.overlay.visible = false
    m.scrubGroup.visible = false
    rebuildSpeedMenu()
    m.speedMenu.visible = true
    m.speedMenuOpen = true
    m.mode = "speed"
    m.speedList.SetFocus(true)
end sub

sub closeSpeedMenu()
    m.speedList.SetFocus(false)
    m.speedMenu.visible = false
    m.speedMenuOpen = false
    showOverlay()
    m.top.SetFocus(true)
end sub

sub rebuildSpeedMenu()
    content = CreateObject("roSGNode", "ContentNode")
    speeds = PlaybackSpeeds()
    
    currentSpeed = CurrentPlaybackSpeed()
    
    focusedIndex = 1 ' Default to 1.0x
    for i = 0 to speeds.Count() - 1
        speed = speeds[i]
        child = content.CreateChild("ContentNode")
        
        label = speed.ToStr() + "x"
        ' The speed value itself is a number, not translatable text; only the
        ' "(Normal)" annotation around it is.
        if speed = 1.0 then label = TrFormat("player.speed.normal", "1.0x")
        
        if Abs(speed - currentSpeed) < 0.1
            child.title = "* " + label
            focusedIndex = i
        else
            child.title = label
        end if
    end for
    
    m.speedList.content = content
    m.speedList.JumpToItem = focusedIndex
end sub

sub moveSpeedFocus(direction as integer)
    speedsCount = PlaybackSpeeds().Count()
    index = m.speedList.itemFocused
    if index < 0 then index = 0
    index = index + direction
    if index < 0 then index = 0
    if index >= speedsCount then index = speedsCount - 1
    m.speedList.JumpToItem = index
end sub

sub selectSpeed()
    if not m.speedMenuOpen then return
    
    itemIndex = m.speedList.itemFocused
    if itemIndex < 0 then itemIndex = 0
    
    speeds = PlaybackSpeeds()
    if itemIndex < speeds.Count()
        applyPlaybackSpeed(speeds[itemIndex])
    end if
    
    rebuildSpeedMenu()
    closeSpeedMenu()
end sub

sub onSpeedSelected()
    selectSpeed()
end sub

function PlaybackSpeeds() as object
    return [0.5, 1.0, 1.25, 1.5, 2.0]
end function

function CurrentPlaybackSpeed() as float
    speed = m.currentPlaybackSpeed
    if m.top.HasField("playbackSpeed")
        fieldSpeed = m.top.playbackSpeed
        if fieldSpeed <> invalid and fieldSpeed > 0 then speed = fieldSpeed
    end if
    if speed <= 0 then speed = 1.0
    return speed
end function

sub applyPlaybackSpeed(speed as float)
    if speed <= 0 then speed = 1.0
    m.currentPlaybackSpeed = speed
    if m.top.HasField("playbackSpeed")
        m.top.playbackSpeed = speed
        if m.top.state = "playing"
            m.top.control = "pause"
            m.top.control = "resume"
        end if
    end if
end sub

sub openAudioMenu()
    m.hideTimer.control = "stop"
    m.overlay.visible = false
    m.scrubGroup.visible = false
    rebuildAudioMenu()
    m.audioMenu.visible = true
    m.audioMenuOpen = true
    m.mode = "audio"
    focused = CurrentAudioTrackIndex()
    if focused < 0 then focused = 0
    m.audioList.JumpToItem = focused
    m.audioList.SetFocus(true)
end sub

sub closeAudioMenu()
    m.audioList.SetFocus(false)
    m.audioMenu.visible = false
    m.audioMenuOpen = false
    showOverlay()
    m.top.SetFocus(true)
end sub

sub moveAudioFocus(direction as integer)
    tracks = m.top.availableAudioTracks
    itemCount = 1
    if tracks <> invalid and tracks.Count() > 0 then itemCount = tracks.Count()

    index = m.audioList.itemFocused
    if index < 0 then index = 0
    index = index + direction
    if index < 0 then index = 0
    if index >= itemCount then index = itemCount - 1
    m.audioList.JumpToItem = index
end sub

sub selectAudioTrack()
    if not m.audioMenuOpen then return
    tracks = m.top.availableAudioTracks
    if tracks = invalid or tracks.Count() = 0
        closeAudioMenu()
        return
    end if

    itemIndex = m.audioList.itemFocused
    if itemIndex < 0 then itemIndex = 0
    if itemIndex >= tracks.Count()
        rebuildAudioMenu()
        return
    end if

    m.top.audioTrack = AudioTrackName(tracks[itemIndex], itemIndex)
    rebuildAudioMenu()
    closeAudioMenu()
end sub

sub onAudioSelected()
    selectAudioTrack()
end sub

sub openSubtitleMenu()
    m.hideTimer.control = "stop"
    m.overlay.visible = false
    m.scrubGroup.visible = false
    rebuildSubtitleMenu()
    m.subtitleMenu.visible = true
    m.subtitleMenuOpen = true
    m.mode = "subtitles"
    if m.top.subtitleOptions.Count() = 0
        m.subtitleList.SetFocus(true)
    else if m.top.selectedSubtitleIndex < 0
        m.subtitleList.JumpToItem = 0
        m.subtitleList.SetFocus(true)
    else
        m.subtitleList.JumpToItem = m.top.selectedSubtitleIndex + 1
        m.subtitleList.SetFocus(true)
    end if
    updateSubtitleSyncLabel()
end sub

sub closeSubtitleMenu()
    m.subtitleList.SetFocus(false)
    m.subtitleMenu.visible = false
    m.subtitleMenuOpen = false
    showOverlay()
    m.top.SetFocus(true)
end sub

sub moveSubtitleFocus(direction as integer)
    itemCount = 1
    if m.top.subtitleOptions <> invalid and m.top.subtitleOptions.Count() > 0
        itemCount = m.top.subtitleOptions.Count() + 1
    end if

    index = m.subtitleList.itemFocused
    if index < 0 then index = 0
    index = index + direction
    if index < 0 then index = 0
    if index >= itemCount then index = itemCount - 1
    m.subtitleList.JumpToItem = index
end sub

sub selectSubtitle()
    if not m.subtitleMenuOpen then return
    if m.top.subtitleOptions.Count() = 0
        closeSubtitleMenu()
        return
    end if
    itemIndex = m.subtitleList.itemFocused
    if itemIndex < 0
        itemIndex = 0
    end if

    index = itemIndex - 1
    m.subtitleDefaultsApplied = true
    if index < 0
        m.top.subtitleTrack = ""
        m.top.globalCaptionMode = "Off"
        m.top.selectedSubtitleIndex = -1
        clearCustomSubtitle()
        m.top.action = {
            type: "subtitleSelection"
            selection: "off"
        }
    else if index < m.top.subtitleOptions.Count()
        enableSubtitle(index)
        subtitle = m.top.subtitleOptions[index]
        if subtitle <> invalid and subtitle.DoesExist("language")
            m.top.action = {
                type: "subtitleSelection"
                selection: subtitle.language
            }
        end if
    end if
    rebuildSubtitleMenu()
    closeSubtitleMenu()
end sub

sub enableSubtitle(index as integer)
    subtitle = m.top.subtitleOptions[index]
    m.top.selectedSubtitleIndex = index
    if m.top.subtitleRenderMode = "Below video"
        m.top.subtitleTrack = ""
        m.top.globalCaptionMode = "Off"
        loadCustomSubtitle(subtitle.trackName)
    else
        clearCustomSubtitle()
        m.top.subtitleTrack = subtitle.trackName
        m.top.globalCaptionMode = "On"
    end if
end sub

sub onSubtitleSelected()
    selectSubtitle()
end sub

sub onSubtitleStyleChanged()
    ' The style always gets applied to the custom renderer's nodes so that they
    ' are already correct the moment the renderer is used again.
    applyCustomSubtitleStyle()
    if m.top.subtitleRenderMode <> "Below video"
        ' "Native" hands rendering to Roku's system closed-caption engine. Roku
        ' does not let an app override the system caption appearance (the
        ' Video.captionStyle-style overrides are not honoured), so font, size,
        ' colour, outline colour, backdrop and position are inert by design in
        ' this mode: the viewer's device-level caption settings win. Nothing is
        ' faked here on purpose.
        clearCustomSubtitle()
        if m.top.selectedSubtitleIndex >= 0 and m.top.subtitleOptions <> invalid and m.top.selectedSubtitleIndex < m.top.subtitleOptions.Count()
            m.top.subtitleTrack = m.top.subtitleOptions[m.top.selectedSubtitleIndex].trackName
            m.top.globalCaptionMode = "On"
        end if
    else if m.top.selectedSubtitleIndex >= 0 and m.top.subtitleOptions <> invalid and m.top.selectedSubtitleIndex < m.top.subtitleOptions.Count()
        m.top.subtitleTrack = ""
        m.top.globalCaptionMode = "Off"
        if m.customSubtitleCues.Count() = 0
            loadCustomSubtitle(m.top.subtitleOptions[m.top.selectedSubtitleIndex].trackName)
        end if
        ' Coming back from "Native": the full custom style has already been
        ' re-applied above, so re-run the layout/visibility pass for whatever cue
        ' is current instead of waiting for the next cue boundary.
        m.customSubtitleText = ""
        updateCustomSubtitle()
    end if
end sub

sub onSubtitleSyncOffsetChanged()
    updateCustomSubtitle()
    updateSubtitleSyncLabel()
end sub

sub adjustSubtitleSyncOffset(delta as float)
    setSubtitleSyncOffset(m.top.subtitleSyncOffset + delta)
end sub

sub setSubtitleSyncOffset(offset as float)
    if Abs(offset) < 0.01 then offset = 0.0
    if offset > 30.0 then offset = 30.0
    if offset < -30.0 then offset = -30.0

    m.top.subtitleSyncOffset = offset
    updateCustomSubtitle()
    updateSubtitleSyncLabel()
    m.top.action = {
        type: "subtitleSyncOffset"
        offset: offset
    }
end sub

sub updateSubtitleSyncLabel()
    if m.subtitleSyncLabel = invalid then return
    m.subtitleSyncLabel.text = FormatSubtitleSyncOffset(m.top.subtitleSyncOffset)
end sub

sub loadCustomSubtitle(url as string)
    clearCustomSubtitle()
    if url = "" then return

    m.subtitleLoadSequence = m.subtitleLoadSequence + 1
    task = CreateObject("roSGNode", "SubtitleTextTask")
    task.url = url
    task.requestId = "subtitleText|" + m.subtitleLoadSequence.ToStr()
    task.ObserveField("response", "onSubtitleTextResponse")
    m.subtitleTextTask = task
    task.control = "RUN"
end sub

sub onSubtitleTextResponse(event as object)
    response = event.GetData()
    if response = invalid or not response.DoesExist("requestId") then return
    expectedId = "subtitleText|" + m.subtitleLoadSequence.ToStr()
    if response.requestId <> expectedId then return
    if not response.ok
        print "[Stroku] Custom subtitle load failed: " ; response.error
        return
    end if

    m.customSubtitleCues = ParseSrtCues(response.text)
    updateCustomSubtitle()
end sub

sub clearCustomSubtitle()
    m.subtitleLoadSequence = m.subtitleLoadSequence + 1
    m.customSubtitleCues = []
    m.customSubtitleText = ""
    setCustomSubtitleLabelText("")
    if m.customSubtitleGroup <> invalid then m.customSubtitleGroup.visible = false
end sub

' Keeps the fill label and every outline copy carrying the same string.
sub setCustomSubtitleLabelText(text as string)
    rendered = text
    if SubtitleFontSpec(m.top.customSubtitleFont).upperCase then rendered = UCase(text)
    if m.customSubtitleLabel <> invalid then m.customSubtitleLabel.text = rendered
    if m.customSubtitleOutlineLabels = invalid then return
    for each outlineLabel in m.customSubtitleOutlineLabels
        outlineLabel.text = rendered
    end for
end sub

sub updateCustomSubtitle()
    if m.top.subtitleRenderMode <> "Below video" then return
    if m.customSubtitleCues = invalid or m.customSubtitleCues.Count() = 0 then return

    position = m.top.position - m.top.subtitleSyncOffset
    if position < 0 then position = 0
    text = ""
    for each cue in m.customSubtitleCues
        if position >= cue.start and position <= cue.finish
            text = cue.text
            exit for
        end if
    end for

    if text = m.customSubtitleText then return
    m.customSubtitleText = text
    setCustomSubtitleLabelText(text)
    updateCustomSubtitleLayout(text)
    m.customSubtitleGroup.visible = text <> ""
end sub

function FormatSubtitleSyncOffset(offset as dynamic) as string
    value = 0.0
    if offset <> invalid then value = offset

    if Abs(value) < 0.01
        return TrFormat("player.subtitles.sync", "0.0s")
    else if value > 0
        return TrFormat("player.subtitles.sync", "+" + FormatDecimalTenths(value) + "s")
    end if
    return TrFormat("player.subtitles.sync", "-" + FormatDecimalTenths(-value) + "s")
end function

function FormatDecimalTenths(value as float) as string
    tenths = Int((value * 10.0) + 0.5)
    whole = Int(tenths / 10)
    decimal = tenths mod 10
    return whole.ToStr() + "." + decimal.ToStr()
end function

sub applyCustomSubtitleStyle()
    if m.customSubtitleLabel = invalid then return

    ' Family and size compose: the font choice picks a weight plus a step on the
    ' Roku system-font ladder, the size choice picks the base rung.
    fontUri = SubtitleFontUri(m.top.customSubtitleTextSize, m.top.customSubtitleFont)
    m.customSubtitleLabel.font = fontUri

    ' Assigning a system font URI hands back a fresh node sized for the device
    ' design resolution, so the manual scale has to be re-applied to it.
    ScaleUiFont(m.customSubtitleLabel.font, UiScaleFontFactor())

    m.customSubtitleLabel.color = SubtitleColorValue(m.top.customSubtitleTextColor)
    outlineColor = SubtitleColorValue(m.top.customSubtitleOutlineColor)
    if m.customSubtitleOutlineLabels <> invalid
        for each outlineLabel in m.customSubtitleOutlineLabels
            outlineLabel.font = fontUri
            ScaleUiFont(outlineLabel.font, UiScaleFontFactor())
            outlineLabel.color = outlineColor
        end for
    end if
    setCustomSubtitleLabelText(m.customSubtitleText)

    alpha = BackdropAlpha(m.top.customSubtitleBackdropOpacity)
    m.customSubtitleBackdrop.visible = alpha <> "00"
    m.customSubtitleBackdrop.color = "0x000000" + alpha
    updateCustomSubtitleLayout(m.customSubtitleText)
end sub

sub updateCustomSubtitleLayout(text as string)
    if m.customSubtitleLabel = invalid then return

    position = CustomSubtitlePosition(m.top.customSubtitlePosition)
    lineCount = SubtitleLineCount(text)
    longestLine = LongestSubtitleLineLength(text)
    metrics = SubtitleMetrics(SubtitleEffectiveSizeIndex(m.top.customSubtitleTextSize, m.top.customSubtitleFont))

    labelHeight = metrics.lineHeight * lineCount
    if labelHeight < metrics.lineHeight then labelHeight = metrics.lineHeight
    labelHeight = labelHeight + 8

    labelY = position.bottom - labelHeight
    backdropHeight = labelHeight + 14
    backdropY = labelY - 7

    backdropWidth = (longestLine * metrics.charWidth) + 72
    if backdropWidth < 360 then backdropWidth = 360
    if backdropWidth > 1540 then backdropWidth = 1540
    backdropX = Int((1920 - backdropWidth) / 2)

    m.customSubtitleLabel.translation = ScaleUiXY(250, labelY + 20)
    m.customSubtitleLabel.height = ScaleUi(labelHeight)

    if m.customSubtitleOutlineLabels <> invalid
        offsets = SubtitleOutlineOffsets()
        for offsetIndex = 0 to m.customSubtitleOutlineLabels.Count() - 1
            offset = offsets[offsetIndex mod offsets.Count()]
            outlineLabel = m.customSubtitleOutlineLabels[offsetIndex]
            outlineLabel.translation = ScaleUiXY(250 + offset[0], labelY + 20 + offset[1])
            outlineLabel.height = ScaleUi(labelHeight)
        end for
    end if

    m.customSubtitleBackdrop.translation = ScaleUiXY(backdropX, backdropY + 20)
    m.customSubtitleBackdrop.width = ScaleUi(backdropWidth)
    m.customSubtitleBackdrop.height = ScaleUi(backdropHeight)
end sub

sub seekBy(seconds as integer)
    target = m.top.position + seconds
    if target < 0 then target = 0
    if m.top.duration > 0 and target > m.top.duration then target = m.top.duration
    m.top.seek = target
end sub

function HasAlternateAudioTracks() as boolean
    tracks = m.top.availableAudioTracks
    return tracks <> invalid and tracks.Count() > 1
end function

function CurrentAudioTrackIndex() as integer
    tracks = m.top.availableAudioTracks
    if tracks = invalid then return -1

    currentTrack = CurrentAudioTrackName()
    if currentTrack = "" then return -1
    for index = 0 to tracks.Count() - 1
        if AudioTrackName(tracks[index], index) = currentTrack then return index
    end for
    return -1
end function

function CurrentAudioTrackName() as string
    current = m.top.currentAudioTrack
    if current <> invalid
        name = AudioTrackName(current, -1)
        if name <> "" then return name
    end if
    if m.top.audioTrack <> invalid then return m.top.audioTrack.ToStr()
    return ""
end function

function AudioTrackName(track as dynamic, index as integer) as string
    if track <> invalid and GetInterface(track, "ifAssociativeArray") <> invalid
        if track.DoesExist("TrackName") and track.TrackName <> invalid then return track.TrackName.ToStr()
        if track.DoesExist("Name") and track.Name <> invalid then return track.Name.ToStr()
        if track.DoesExist("Language") and track.Language <> invalid then return track.Language.ToStr()
    else if track <> invalid
        return track.ToStr()
    end if
    if index >= 0 then return index.ToStr()
    return ""
end function

function AudioTrackLabel(track as dynamic, index as integer) as string
    name = ""
    language = ""
    description = ""

    if track <> invalid and GetInterface(track, "ifAssociativeArray") <> invalid
        if track.DoesExist("Language") and track.Language <> invalid then language = track.Language.ToStr()
        if track.DoesExist("Name") and track.Name <> invalid then name = track.Name.ToStr()
        if track.DoesExist("Description") and track.Description <> invalid then description = track.Description.ToStr()
    else if track <> invalid
        name = track.ToStr()
    end if

    label = ""
    if language <> "" then label = language
    if description <> ""
        if label <> "" then label = label + " | "
        label = label + description
    end if
    if name <> "" and name <> language and name <> description
        if label <> "" then label = label + " | "
        label = label + name
    end if
    if label = "" then label = TrFormat("player.audio.trackNumber", (index + 1).ToStr())
    return label
end function

function DefaultSubtitleIndex() as integer
    preferred = m.top.defaultSubtitleLanguage
    if preferred = invalid or preferred = "" or preferred = "None" then return 0
    preferredIndex = PreferredSubtitleIndex(preferred)
    if preferredIndex >= 0 then return preferredIndex
    return 0
end function

function PreferredSubtitleIndex(preferred as string) as integer
    if preferred = invalid or preferred = "" then return -1
    aliases = SubtitleLanguageAliases(preferred)
    for index = 0 to m.top.subtitleOptions.Count() - 1
        option = m.top.subtitleOptions[index]
        if option <> invalid and option.DoesExist("language") and option.language <> invalid
            candidate = NormalizeSubtitleLanguage(option.language.ToStr())
            if candidate <> ""
                for each alias in aliases
                    if candidate = alias then return index
                end for
            end if
        end if
    end for
    return -1
end function

' Add-ons report a subtitle language as a display name ("English"), an ISO 639-1
' code ("en"), an ISO 639-2 code ("eng"), or an endonym ("Espanol"). Comparing
' raw strings meant the Default Subtitles Language setting never matched anything
' but a display name, so both sides are folded to lower case and stripped of
' accents and separators before comparison.
function NormalizeSubtitleLanguage(value as dynamic) as string
    if value = invalid then return ""
    text = LCase(value.ToStr())
    result = ""
    for i = 1 to Len(text)
        char = Mid(text, i, 1)
        if char = "á" or char = "à" or char = "â" or char = "ã" or char = "ä"
            result = result + "a"
        else if char = "é" or char = "è" or char = "ê" or char = "ë"
            result = result + "e"
        else if char = "í" or char = "ì" or char = "î" or char = "ï"
            result = result + "i"
        else if char = "ó" or char = "ò" or char = "ô" or char = "õ" or char = "ö"
            result = result + "o"
        else if char = "ú" or char = "ù" or char = "û" or char = "ü"
            result = result + "u"
        else if char = "ñ"
            result = result + "n"
        else if char = "ç"
            result = result + "c"
        else if char = " " or char = "-" or char = "_" or char = "." or char = "(" or char = ")"
            ' separators are dropped
        else
            result = result + char
        end if
    end for
    return result
end function

' Every spelling of a supported language that should satisfy the setting:
' display name, ISO 639-1, ISO 639-2 (both bibliographic and terminologic where
' they differ), and the common endonym.
function SubtitleLanguageAliases(preferred as dynamic) as object
    normalized = NormalizeSubtitleLanguage(preferred)
    table = {
        english: ["english", "en", "eng"]
        spanish: ["spanish", "es", "spa", "esp", "espanol", "castellano"]
        french: ["french", "fr", "fra", "fre", "francais"]
        german: ["german", "de", "deu", "ger", "deutsch"]
        italian: ["italian", "it", "ita", "italiano"]
        portuguese: ["portuguese", "pt", "por", "portugues", "brazilian"]
    }
    for each key in table
        for each alias in table[key]
            if alias = normalized then return table[key]
        end for
    end for
    if normalized = "" then return []
    return [normalized]
end function

sub ApplyDefaultAudioTrack()
    preferred = m.top.defaultAudioTrack
    if preferred = invalid or preferred = "" or preferred = "Any" then return
    if m.top.audioTrack <> invalid and m.top.audioTrack <> "" then return
    tracks = m.top.availableAudioTracks
    if tracks = invalid or tracks.Count() = 0 then return
    for index = 0 to tracks.Count() - 1
        label = AudioTrackLabel(tracks[index], index)
        if preferred = "Original" and index = 0
            m.top.audioTrack = AudioTrackName(tracks[index], index)
            return
        else if Instr(1, LCase(label), LCase(preferred)) > 0
            m.top.audioTrack = AudioTrackName(tracks[index], index)
            return
        end if
    end for
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    if not press then return false

    if m.mode = "speed" or m.speedMenu.visible
        if key = "back"
            closeSpeedMenu()
            return true
        else if key = "OK"
            selectSpeed()
            return true
        else if key = "up"
            moveSpeedFocus(-1)
            return true
        else if key = "down"
            moveSpeedFocus(1)
            return true
        end if
        return false
    end if

    if m.mode = "audio" or m.audioMenu.visible
        if key = "back"
            closeAudioMenu()
            return true
        else if key = "OK"
            selectAudioTrack()
            return true
        else if key = "up"
            moveAudioFocus(-1)
            return true
        else if key = "down"
            moveAudioFocus(1)
            return true
        end if
        return false
    end if

    if m.mode = "subtitles" or m.subtitleMenu.visible
        if key = "back"
            closeSubtitleMenu()
            return true
        else if key = "OK"
            selectSubtitle()
            return true
        else if key = "up"
            moveSubtitleFocus(-1)
            return true
        else if key = "down"
            moveSubtitleFocus(1)
            return true
        else if key = "left"
            adjustSubtitleSyncOffset(-0.5)
            return true
        else if key = "right"
            adjustSubtitleSyncOffset(0.5)
            return true
        else if key = "replay"
            setSubtitleSyncOffset(0.0)
            return true
        end if
        return false
    end if

    if key = "back"
        if m.mode = "overlay"
            m.overlay.visible = false
            m.scrubGroup.visible = false
            m.mode = "hidden"
            return true
        else if m.mode = "scrubbing"
            exitScrubMode(false)
            m.overlay.visible = false
            m.scrubGroup.visible = false
            m.mode = "hidden"
            return true
        end if
        m.top.action = { type: "close" }
        return true
    else if key = "play"
        togglePlayPause()
        return true
    else if key = "replay"
        if m.mode = "scrubbing"
            scrubBy(-10)
        else
            enterScrubMode()
            scrubBy(-10)
        end if
        return true
    else if key = "fastforward"
        if m.mode = "scrubbing"
            scrubBy(30)
        else
            seekBy(30)
            if m.mode = "overlay"
                m.overlay.visible = false
                m.scrubGroup.visible = false
                m.mode = "hidden"
                m.hideTimer.control = "stop"
            end if
        end if
        return true
    else if key = "rewind"
        if m.mode = "scrubbing"
            scrubBy(-30)
        else
            enterScrubMode()
            scrubBy(-30)
        end if
        return true
    end if

    if m.mode = "hidden"
        if key = "left"
            enterScrubMode()
            scrubBy(-10)
            return true
        else if key = "right"
            enterScrubMode()
            scrubBy(10)
            return true
        else if key = "OK" or key = "down" or key = "up"
            showOverlay()
            return true
        end if
        return false
    end if

    if m.mode = "scrubbing"
        if key = "left"
            scrubBy(-10)
        else if key = "right"
            scrubBy(10)
        else if key = "OK"
            commitScrub()
        else if key = "up"
            exitScrubMode(false)
            switchRow(0) ' Top Row
        else if key = "down"
            exitScrubMode(false)
            switchRow(1) ' Bottom Row
        else if key = "back"
            exitScrubMode(false)
            m.overlay.visible = false
            m.scrubGroup.visible = false
            m.mode = "hidden"
        else
            return false
        end if
        return true
    end if

    if key = "up"
        if m.focusedRow = 1
            enterScrubMode()
        else if m.focusedRow = 0
            hideOverlay()
        end if
    else if key = "down"
        if m.focusedRow = 0
            enterScrubMode()
        end if
    else if key = "left"
        moveButton(-1)
    else if key = "right"
        moveButton(1)
    else if key = "OK"
        activateButton()
    else
        return false
    end if
    return true
end function

function FormatPlaybackTime(seconds as dynamic) as string
    total = Int(seconds)
    if total < 0 then total = 0
    hours = Int(total / 3600)
    minutes = Int((total mod 3600) / 60)
    remainingSeconds = total mod 60

    minuteText = minutes.ToStr()
    secondText = remainingSeconds.ToStr()
    if Len(secondText) = 1 then secondText = "0" + secondText
    if hours > 0
        if Len(minuteText) = 1 then minuteText = "0" + minuteText
        return hours.ToStr() + ":" + minuteText + ":" + secondText
    end if
    return minuteText + ":" + secondText
end function

function ParseSrtCues(text as string) as object
    cues = []
    normalized = text.Replace(Chr(13), "")
    blockLines = []
    for each rawLine in normalized.Split(Chr(10))
        line = rawLine.Trim()
        if line = ""
            AddSrtCue(cues, blockLines)
            blockLines = []
        else
            blockLines.Push(line)
        end if
    end for
    AddSrtCue(cues, blockLines)
    return cues
end function

sub AddSrtCue(cues as object, lines as object)
    if lines = invalid or lines.Count() = 0 then return

    timeIndex = -1
    for i = 0 to lines.Count() - 1
        if Instr(1, lines[i], "-->") > 0
            timeIndex = i
            exit for
        end if
    end for
    if timeIndex < 0 then return

    arrowIndex = Instr(1, lines[timeIndex], "-->")
    if arrowIndex <= 0 then return
    startSec = ParseSrtTime(Left(lines[timeIndex], arrowIndex - 1).Trim())
    finishSec = ParseSrtTime(Mid(lines[timeIndex], arrowIndex + 3).Trim())
    if finishSec <= startSec then return

    cueText = ""
    for i = timeIndex + 1 to lines.Count() - 1
        cleanLine = CleanSubtitleText(lines[i])
        if cleanLine <> ""
            if cueText <> "" then cueText = cueText + Chr(10)
            cueText = cueText + cleanLine
        end if
    end for
    if cueText = "" then return

    cues.Push({
        start: startSec
        finish: finishSec
        text: cueText
    })
end sub

function ParseSrtTime(value as string) as float
    clean = value
    spaceIndex = Instr(1, clean, " ")
    if spaceIndex > 0 then clean = Left(clean, spaceIndex - 1)
    clean = clean.Replace(",", ".")
    parts = clean.Split(":")
    if parts.Count() < 3 then return 0.0

    hours = Val(parts[0])
    minutes = Val(parts[1])
    seconds = Val(parts[2])
    return (hours * 3600.0) + (minutes * 60.0) + seconds
end function

function CleanSubtitleText(value as string) as string
    text = StripTaggedText(value)
    text = StripBraceTags(text)
    text = text.Replace("&amp;", "&")
    text = text.Replace("&lt;", "<")
    text = text.Replace("&gt;", ">")
    text = text.Replace("&quot;", Chr(34))
    return text.Trim()
end function

function StripTaggedText(value as string) as string
    result = ""
    inTag = false
    for i = 1 to Len(value)
        char = Mid(value, i, 1)
        if char = "<"
            inTag = true
        else if char = ">"
            inTag = false
        else if not inTag
            result = result + char
        end if
    end for
    return result
end function

function StripBraceTags(value as string) as string
    result = ""
    inTag = false
    for i = 1 to Len(value)
        char = Mid(value, i, 1)
        if char = "{"
            inTag = true
        else if char = "}"
            inTag = false
        else if not inTag
            result = result + char
        end if
    end for
    return result
end function

function CustomSubtitlePosition(positionName as string) as object
    if positionName = "Higher"
        return { bottom: 900 }
    else if positionName = "Low"
        return { bottom: 995 }
    end if
    return { bottom: 1042 }
end function

function SubtitleLineCount(text as string) as integer
    if text = "" then return 1
    count = 1
    for i = 1 to Len(text)
        if Mid(text, i, 1) = Chr(10) then count = count + 1
    end for
    if count > 3 then count = 3
    return count
end function

function LongestSubtitleLineLength(text as string) as integer
    if text = "" then return 12
    longest = 0
    current = 0
    for i = 1 to Len(text)
        if Mid(text, i, 1) = Chr(10)
            if current > longest then longest = current
            current = 0
        else
            current = current + 1
        end if
    end for
    if current > longest then longest = current
    if longest > 70 then longest = 70
    return longest
end function

' Layout metrics per rung of the Roku system-font ladder, in design-space units.
function SubtitleMetrics(sizeIndex as integer) as object
    if sizeIndex <= 0 then return { lineHeight: 27, charWidth: 12 }
    if sizeIndex = 1 then return { lineHeight: 34, charWidth: 16 }
    if sizeIndex = 3 then return { lineHeight: 50, charWidth: 24 }
    if sizeIndex >= 4 then return { lineHeight: 58, charWidth: 28 }
    return { lineHeight: 42, charWidth: 20 }
end function

' The offsets, in design-space units, of the eight outline copies around the
' fill label. Always scaled through ScaleUiXY before being assigned.
function SubtitleOutlineOffsets() as object
    return [[-2, -2], [0, -2], [2, -2], [-2, 0], [2, 0], [-2, 2], [0, 2], [2, 2]]
end function

' Roku exposes exactly one system typeface - a sans-serif proportional face - in
' a regular and a bold weight across five sizes (font:SmallestSystemFont through
' font:LargestBoldSystemFont). There is no serif, casual, or small-caps face in
' the registry, and this app deliberately ships no font files, so three of the
' five choices are documented approximations rather than real families:
'
'   Default                 bold weight, no size step (the original look)
'   Sans Serif Proportional regular weight, no size step - this is genuinely the
'                           system face, only lighter than Default
'   Serif Proportional      APPROXIMATION: no serif face exists on Roku. Rendered
'                           as the bold system face one rung larger.
'   Casual                  APPROXIMATION: no casual/handwriting face exists on
'                           Roku. Rendered as the regular system face one rung
'                           larger.
'   Small Caps              APPROXIMATION: no small-caps face and no per-run
'                           sizing inside a Label. Rendered as uppercased text in
'                           the bold system face one rung smaller.
'
' `delta` is applied on top of the user's size choice, so Small/Medium/Large keep
' working for every family.
function SubtitleFontSpec(fontName as dynamic) as object
    name = ""
    if fontName <> invalid then name = fontName.ToStr()

    if name = "Sans Serif Proportional" then return { bold: false, delta: 0, upperCase: false }
    if name = "Serif Proportional" then return { bold: true, delta: 1, upperCase: false }
    if name = "Casual" then return { bold: false, delta: 1, upperCase: false }
    if name = "Small Caps" then return { bold: true, delta: -1, upperCase: true }
    return { bold: true, delta: 0, upperCase: false }
end function

function SubtitleSizeIndex(sizeName as dynamic) as integer
    if sizeName = "Small" then return 1
    if sizeName = "Large" then return 3
    return 2
end function

function SubtitleEffectiveSizeIndex(sizeName as dynamic, fontName as dynamic) as integer
    index = SubtitleSizeIndex(sizeName) + SubtitleFontSpec(fontName).delta
    if index < 0 then index = 0
    if index > 4 then index = 4
    return index
end function

function SubtitleFontUri(sizeName as dynamic, fontName as dynamic) as string
    rungs = ["Smallest", "Small", "Medium", "Large", "Largest"]
    uri = "font:" + rungs[SubtitleEffectiveSizeIndex(sizeName, fontName)]
    if SubtitleFontSpec(fontName).bold then uri = uri + "Bold"
    return uri + "SystemFont"
end function

function SubtitleColorValue(colorName as string) as string
    if colorName = "Yellow" then return "0xFFFF00FF"
    if colorName = "Cyan" then return "0x00FFFFFF"
    if colorName = "Green" then return "0x00FF66FF"
    if colorName = "Black" then return "0x000000FF"
    return "0xFFFFFFFF"
end function

function BackdropAlpha(opacity as string) as string
    if opacity = "100%" then return "FF"
    if opacity = "75%" then return "BF"
    if opacity = "50%" then return "80"
    if opacity = "25%" then return "40"
    return "00"
end function
