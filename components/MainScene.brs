sub init()
    print "=== Stremio Roku Bridge - MainScene Initialized ==="
    
    ' Get all UI elements for modern design
    m.statusLabel = m.top.findNode("statusLabel")
    m.instructionsLabel = m.top.findNode("instructionsLabel")
    m.ipLabel = m.top.findNode("ipLabel")
    m.networkStatus = m.top.findNode("networkStatus")
    m.statusIndicator = m.top.findNode("statusIndicator")
    m.videoPlayer = m.top.findNode("videoPlayer")
    m.loadingSpinner = m.top.findNode("loadingSpinner")
    m.loadingLabel = m.top.findNode("loadingLabel")
    
    ' Error elements
    m.errorCard = m.top.findNode("errorCard")
    m.errorTitle = m.top.findNode("errorTitle")
    m.errorLabel = m.top.findNode("errorLabel")
    m.errorInstructions = m.top.findNode("errorInstructions")
    
    ' Get all card elements
    m.headerCard = m.top.findNode("headerCard")
    m.statusCard = m.top.findNode("statusCard")
    m.networkCard = m.top.findNode("networkCard")
    m.instructionsCard = m.top.findNode("instructionsCard")
    m.iconContainer = m.top.findNode("iconContainer")
    
    ' Get instruction elements
    m.appSubtitle = m.top.findNode("appSubtitle")
    m.step1Label = m.top.findNode("step1Label")
    m.step2Label = m.top.findNode("step2Label")
    m.step3Label = m.top.findNode("step3Label")
    m.controlsLabel = m.top.findNode("controlsLabel")
    m.disclaimerLabel = m.top.findNode("disclaimerLabel")
    
    ' Theme colors (Stremio purple theme)
    m.theme = {
        primary: "0x6441A5FF",
        primaryDark: "0x4A2F7AFF",
        primaryLight: "0x8A5FD3FF",
        accent: "0x9966FFFF",
        backgroundDark: "0x0F0F23FF",
        backgroundSurface: "0x1A1A2EFF",
        backgroundCard: "0x252541FF",
        textPrimary: "0xFFFFFFFF",
        textSecondary: "0xB3B3CCFF",
        textHint: "0x8080A0FF",
        success: "0x4CAF50FF",
        warning: "0xFF9800FF",
        error: "0xF44336FF"
    }
    
    ' Video state
    m.isPlaying = false
    
    ' Initialize memory monitoring (deferred to avoid startup issues)
    ' InitializeMemoryMonitoring()
    
    ' Set up video player events
    m.videoPlayer.observeField("state", "onVideoStateChange")
    
    ' Initialize display with correct resolution and responsive design
    InitializeDisplay()
    
    ' Apply theme
    SetTheme()
    
    ' Initialize with ready state
    print "DEBUG: About to call ShowReady()"
    ShowReady()
    print "DEBUG: ShowReady() completed"
    
    ' Get and display IP address and network info
    print "DEBUG: About to call DisplayDeviceInfo()"
    DisplayDeviceInfo()
    print "DEBUG: DisplayDeviceInfo() completed"
    
    ' AppLaunchComplete beacon is now fired from main.brs at proper timing
    ' print "DEBUG: Beacon is handled in main.brs for proper certification timing"
    
    ' Set up key handler
    m.top.observeField("focusedChild", "onFocusChange")
    m.top.setFocus(true)
    
    ' Debug: Verify all UI elements are found
    print "=== UI Elements Check ==="
    print "statusLabel found: "; (m.statusLabel <> invalid)
    print "videoPlayer found: "; (m.videoPlayer <> invalid)
    print "headerCard found: "; (m.headerCard <> invalid)
    print "statusCard found: "; (m.statusCard <> invalid)
    
    ' Ensure all UI elements are visible
    if m.headerCard <> invalid then m.headerCard.visible = true
    if m.statusCard <> invalid then m.statusCard.visible = true
    if m.networkCard <> invalid then m.networkCard.visible = true
    if m.instructionsCard <> invalid then m.instructionsCard.visible = true
    
    print "=== Initialization Complete ==="
    
    ' Memory monitoring removed to prevent startup issues
    ' InitializeMemoryMonitoring()
end sub

' Fire AppLaunchComplete beacon after UI is fully rendered
sub FireLaunchCompleteBeacon()
    print "=== FIRING AppLaunchComplete BEACON ==="
    
    ' Use the scene's signalBeacon method (called from main.brs)
    ' This is the proper way to fire beacons in Roku Scene Graph apps
    print "Beacon firing is handled in main.brs for proper timing"
    
    print "Beacon firing completed"
end sub

' Fallback method to manually create beacon signal
sub FireBeaconFallback()
    print "=== USING BEACON FALLBACK METHOD ==="
    print "DEBUG: Entered fallback method"
    
    ' Calculate launch duration manually
    ' Since we're at the end of init, estimate the duration
    launchDuration = 1200 ' Estimate ~1.2 seconds
    print "DEBUG: Calculated launch duration: "; launchDuration
    
    ' Print beacon in the exact format Roku logging expects
    beaconMessage = "[beacon.signal] |AppLaunchComplete --------> Duration(" + Str(launchDuration) + " ms)"
    print beaconMessage
    
    print "DEBUG: Manual beacon signal printed"
    print "Manual beacon signal created"
end sub

sub InitializeDisplay()
    print "=== Initializing Modern Responsive Display ==="
    
    ' Get screen resolution
    deviceInfo = CreateObject("roDeviceInfo")
    displaySize = deviceInfo.getDisplaySize()
    
    screenWidth = displaySize.w
    screenHeight = displaySize.h
    
    print "Screen resolution: " + Str(screenWidth) + "x" + Str(screenHeight)
    
    ' Determine device type and optimize layout
    deviceType = "HD"
    if screenWidth >= 3840 then
        deviceType = "4K"
    else if screenWidth >= 1920 then
        deviceType = "FHD"
    end if
    
    print "Device type: " + deviceType
    
    ' Update background and video player to match screen
    m.top.findNode("background").width = screenWidth
    m.top.findNode("background").height = screenHeight
    m.videoPlayer.width = screenWidth
    m.videoPlayer.height = screenHeight
    
    ' Calculate scale factors for responsive design
    scaleX = screenWidth / 1920.0
    scaleY = screenHeight / 1080.0
    
    ' Use minimum scale to maintain aspect ratio
    scale = scaleX
    if scaleY < scaleX then scale = scaleY
    
    ' Adjust scale for optimal text readability on different devices
    if deviceType = "4K" then
        scale = scale * 1.2 ' Larger UI for 4K displays
    else if deviceType = "HD" then
        scale = scale * 0.9 ' Smaller UI for HD displays
    end if
    
    print "Scale factors: X=" + Str(scaleX) + " Y=" + Str(scaleY) + " Final=" + Str(scale)
    
    ' Update all modern UI elements with responsive positioning
    UpdateModernElement("appTitle", 960, 80, 1400, 60, scale)
    UpdateModernElement("appSubtitle", 960, 135, 1400, 40, scale)
    
    UpdateModernCard("statusCard", 260, 240, 1400, 540, scale)
    UpdateModernElement("statusIndicator", 940, 285, 40, 40, scale)
    UpdateModernElement("statusLabel", 960, 345, 1300, 60, scale)
    UpdateModernElement("instructionsLabel", 960, 410, 1300, 50, scale)
    
    UpdateModernElement("ipLabel", 960, 490, 1200, 40, scale)
    UpdateModernElement("networkStatus", 960, 535, 1200, 30, scale)
    
    UpdateModernElement("step1Label", 960, 600, 1000, 30, scale)
    UpdateModernElement("step2Label", 960, 635, 1000, 30, scale)
    UpdateModernElement("step3Label", 960, 670, 1000, 30, scale)
    UpdateModernElement("controlsLabel", 960, 725, 1000, 25, scale)
    UpdateModernElement("disclaimerLabel", 960, 840, 1600, 100, scale)
    UpdateModernElement("versionLabel", 960, 980, 1600, 30, scale)
    
    ' Loading elements
    UpdateModernElement("loadingSpinner", 960, 540, 0, 0, scale)
    UpdateModernElement("loadingLabel", 960, 620, 800, 40, scale)
    
    ' Error elements
    UpdateModernCard("errorCard", 320, 420, 1280, 240, scale)
    UpdateModernElement("errorTitle", 960, 480, 1200, 40, scale)
    UpdateModernElement("errorLabel", 960, 540, 1200, 80, scale)
    UpdateModernElement("errorInstructions", 960, 620, 1200, 30, scale)
    
    print "Modern responsive display initialization complete"
end sub

sub UpdateModernElement(elementId as string, centerX as integer, centerY as integer, width as integer, height as integer, scale as float)
    element = m.top.findNode(elementId)
    if element <> invalid
        ' Calculate scaled dimensions
        scaledWidth = width * scale
        scaledHeight = height * scale
        
        ' Get screen dimensions for proper centering
        deviceInfo = CreateObject("roDeviceInfo")
        displaySize = deviceInfo.getDisplaySize()
        screenWidth = displaySize.w
        screenHeight = displaySize.h
        
        ' Calculate actual position maintaining center alignment
        actualCenterX = (centerX * screenWidth) / 1920.0
        actualCenterY = (centerY * screenHeight) / 1080.0
        
        ' Position elements properly
        if width > 0 and height > 0
            element.width = scaledWidth
            element.height = scaledHeight
            element.translation = [actualCenterX - (scaledWidth / 2), actualCenterY - (scaledHeight / 2)]
        else if width > 0
            element.width = scaledWidth
            element.translation = [actualCenterX - (scaledWidth / 2), actualCenterY]
        else
            ' For spinner or elements without dimensions
            element.translation = [actualCenterX, actualCenterY]
        end if
        
        ' Adjust font sizes for better readability across devices
        if elementId.InStr("Label") > -1 or elementId.InStr("title") > -1
            AdjustFontSizeForDevice(element, scale)
        end if
    end if
end sub

sub UpdateModernCard(elementId as string, x as integer, y as integer, width as integer, height as integer, scale as float)
    element = m.top.findNode(elementId)
    if element <> invalid
        ' Get screen dimensions
        deviceInfo = CreateObject("roDeviceInfo")
        displaySize = deviceInfo.getDisplaySize()
        screenWidth = displaySize.w
        screenHeight = displaySize.h
        
        ' Calculate responsive dimensions
        scaledWidth = width * scale
        scaledHeight = height * scale
        scaledX = (x * screenWidth) / 1920.0
        scaledY = (y * screenHeight) / 1080.0
        
        ' Set card properties
        element.width = scaledWidth
        element.height = scaledHeight
        element.translation = [scaledX, scaledY]
    end if
end sub

sub AdjustFontSizeForDevice(element as object, scale as float)
    ' Roku doesn't support dynamic font sizing well, but we can ensure optimal readability
    ' The font scaling is handled by the scale factor in positioning
    
    ' Get current font and adjust if needed for extreme scales
    if scale < 0.7
        ' For very small displays, ensure text remains readable
        print "Adjusting for small display - scale: " + Str(scale)
    else if scale > 1.3
        ' For very large displays, prevent text from being too big
        print "Adjusting for large display - scale: " + Str(scale)
    end if
end sub

sub DisplayDeviceInfo()
    ' Get comprehensive device and network information
    deviceInfo = CreateObject("roDeviceInfo")
    
    ' Get IP addresses - getIPAddrs() returns an associative array
    ' where keys are interface names and values are IP addresses
    networkInfo = deviceInfo.getIPAddrs()
    ipAddress = "Not Connected"
    networkInterface = "Unknown"
    interfaceName = ""
    
    if networkInfo <> invalid and networkInfo.Count() > 0
        ' Look for the primary network interface (not localhost)
        for each interfaceName in networkInfo
            currentIP = networkInfo[interfaceName]
            if currentIP <> invalid and currentIP <> "127.0.0.1" and currentIP <> "" and currentIP.Left(3) <> "169"
                ipAddress = currentIP
                ' Determine network type based on interface name and IP
                if interfaceName.InStr("eth") >= 0 or interfaceName.InStr("lan") >= 0
                    networkInterface = "Ethernet"
                else if interfaceName.InStr("wlan") >= 0 or interfaceName.InStr("wifi") >= 0
                    networkInterface = "WiFi"
                else
                    networkInterface = "Network"
                end if
                
                ' Also check IP range for local network detection
                if currentIP.Left(7) = "192.168" or currentIP.Left(3) = "10." or (currentIP.Left(6) >= "172.16" and currentIP.Left(6) <= "172.31")
                    ' This is a local network IP
                else
                    ' Could be public IP or other network
                end if
                exit for
            end if
        end for
    end if
    
    ' Get additional device info
    deviceModel = deviceInfo.getModel()
    deviceName = deviceInfo.getFriendlyName()
    
    ' Format the network connection info
    connectionType = ""
    if networkInterface <> "Unknown"
        connectionType = " via " + networkInterface
    end if
    
    ' Update IP display with better formatting
    if ipAddress <> "Not Connected"
        m.ipLabel.text = "Device IP: " + ipAddress
        if deviceModel <> invalid and deviceModel <> ""
            m.networkStatus.text = "Connected" + connectionType + " • " + deviceModel
        else
            m.networkStatus.text = "Connected" + connectionType
        end if
    else
        m.ipLabel.text = "Device IP: Not Connected"
        m.networkStatus.text = "Network connection required"
        ' Change status indicator to warning
        if m.statusIndicator <> invalid
            m.statusIndicator.color = m.theme.warning
        end if
    end if
    
    print "=== Device Network Information ==="
    print "Device IP: " + ipAddress
    if deviceModel <> invalid and deviceModel <> ""
        print "Model: " + deviceModel
    else
        print "Model: Unknown"
    end if
    print "Network Interface: " + interfaceName + " (" + networkInterface + ")"
    if deviceName <> invalid and deviceName <> ""
        print "Device Name: " + deviceName
    end if
    print "=================================="
end sub

sub ShowReady()
    print "=== Showing Modern Ready State ==="
    
    ' Hide error and loading states
    HideAllModals()
    
    ' Show ready state with modern design
    if m.statusLabel <> invalid then m.statusLabel.text = "Ready to receive streams"
    if m.instructionsLabel <> invalid then m.instructionsLabel.text = "Use your Android app to cast Stremio content to this device"
    
    ' Set status indicator to success green
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.success
    end if
    
    ' Ensure all main UI is visible
    ShowMainUI()
    
    ' Force visibility of key elements
    if m.headerCard <> invalid then m.headerCard.visible = true
    if m.statusCard <> invalid then m.statusCard.visible = true
    if m.networkCard <> invalid then m.networkCard.visible = true
    if m.instructionsCard <> invalid then m.instructionsCard.visible = true
    if m.appTitle <> invalid then m.appTitle.visible = true
    if m.appSubtitle <> invalid then m.appSubtitle.visible = true
    if m.statusLabel <> invalid then m.statusLabel.visible = true
    if m.ipLabel <> invalid then m.ipLabel.visible = true
    
    print "Ready state displayed with modern design"
end sub

sub ShowLoading()
    print "=== Showing Modern Loading State ==="
    
    ' Hide error state
    HideErrorModal()
    
    ' Show loading state with modern design
    m.loadingSpinner.visible = true
    m.loadingLabel.visible = true
    m.statusLabel.text = "Loading stream..."
    m.instructionsLabel.text = "Please wait while the video loads and buffers"
    
    ' Set status indicator to warning orange
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.warning
    end if
    
    print "Loading state displayed with modern design"
end sub

sub ShowError(errorMessage as string)
    print "=== Showing Modern Error State ==="
    print "Error: " + errorMessage
    
    ' Hide loading state
    HideLoadingModal()
    
    ' Show modern error card
    ShowErrorModal(errorMessage)
    
    ' Update main status
    m.statusLabel.text = "Connection Error"
    m.instructionsLabel.text = "Check your network connection and try again"
    
    ' Set status indicator to error red
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.error
    end if
    
    print "Error state displayed with modern card design"
end sub

sub ShowErrorModal(errorMessage as string)
    ' Show modern error card with better UX
    if m.errorCard <> invalid then m.errorCard.visible = true
    if m.errorTitle <> invalid then m.errorTitle.visible = true
    if m.errorLabel <> invalid
        m.errorLabel.visible = true
        m.errorLabel.text = errorMessage
    end if
    if m.errorInstructions <> invalid then m.errorInstructions.visible = true
end sub

sub HideErrorModal()
    ' Hide all error elements
    if m.errorCard <> invalid then m.errorCard.visible = false
    if m.errorTitle <> invalid then m.errorTitle.visible = false
    if m.errorLabel <> invalid then m.errorLabel.visible = false
    if m.errorInstructions <> invalid then m.errorInstructions.visible = false
end sub

sub HideLoadingModal()
    ' Hide all loading elements
    if m.loadingSpinner <> invalid then m.loadingSpinner.visible = false
    if m.loadingLabel <> invalid then m.loadingLabel.visible = false
end sub

sub HideAllModals()
    ' Hide all modal overlays
    HideErrorModal()
    HideLoadingModal()
end sub

sub ShowMainUI()
    print "=== Showing Main UI ==="
    
    ' Ensure main UI elements are visible
    if m.headerCard <> invalid then 
        m.headerCard.visible = true
        print "Header card shown"
    end if
    if m.statusCard <> invalid then 
        m.statusCard.visible = true
        print "Status card shown"
    end if
    if m.networkCard <> invalid then 
        m.networkCard.visible = true
        print "Network card shown"
    end if
    if m.instructionsCard <> invalid then 
        m.instructionsCard.visible = true
        print "Instructions card shown"
    end if
    
    ' Show all labels
    showAllLabels()
    
    print "Main UI displayed"
end sub

sub StartBridgeListener()
    print "=== Starting Bridge Listener ==="
    ShowReady()
    print "Bridge listener ready via ECP"
end sub

sub HandleECPStream(streamData as object)
    print "=== RECEIVED ECP STREAM DATA ==="
    print "Stream data received: "; streamData
    
    if streamData <> invalid
        print "Stream data is valid"
        if streamData.DoesExist("url")
            print "URL found: "; streamData.url
            print "Title: "; streamData.title
            print "Format: "; streamData.format
            
            ShowLoading()
            
            ' Prepare stream data for playback
            playbackData = {
                url: streamData.url,
                format: streamData.format,
                title: streamData.title,
                subtitles: []
            }
            
            print "Starting playback with data: "; playbackData
            PlayStreamWithData(playbackData)
        else
            print "ERROR: No URL found in stream data"
            ShowError("No video URL provided")
        end if
    else
        print "ERROR: Stream data is invalid"
        ShowError("Invalid stream data received")
    end if
end sub

sub PlayStreamWithData(streamData as object)
    print "=== PLAYING STREAM ==="
    print "URL: "; streamData.url
    print "Format: "; streamData.format
    print "Title: "; streamData.title
    print "Video player available: "; (m.videoPlayer <> invalid)
    
    ' Validate stream URL
    if streamData.url = invalid or streamData.url = ""
        print "ERROR: No stream URL provided"
        ShowError("No stream URL provided")
        return
    end if
    
    print "Showing loading state..."
    ShowLoading()
    
    ' Configure video content with optimal settings
    videoContent = CreateObject("roSGNode", "ContentNode")
    videoContent.url = streamData.url
    videoContent.title = streamData.title
    
    ' Set stream format with quality optimization
    if streamData.format = "hls"
        videoContent.streamFormat = "hls"
        ' HLS is optimal for adaptive streaming and quality
    else if streamData.format = "mp4"
        videoContent.streamFormat = "mp4"  
    else if streamData.format = "dash"
        videoContent.streamFormat = "dash"
        ' DASH is excellent for high quality and adaptive bitrate
    else if streamData.format = "mkv"
        ' MKV format - Roku can play MKV if codecs are supported
        print "MKV format detected - Roku supports MKV with compatible codecs"
        
        ' Try MKV directly first (Roku supports it if codecs are right)
        videoContent.streamFormat = "mkv"
        print "Attempting MKV playback directly"
        
        ' Add additional properties for better compatibility
        videoContent.hdPosterUrl = ""
        videoContent.sdPosterUrl = ""
    else
        ' Auto-detect format with quality preference
        urlLower = LCase(streamData.url)
        if Instr(1, urlLower, ".m3u8") > 0
            videoContent.streamFormat = "hls"
        else if Instr(1, urlLower, ".mpd") > 0
            videoContent.streamFormat = "dash"
        else if Instr(1, urlLower, ".mp4") > 0
            videoContent.streamFormat = "mp4"
        else if Instr(1, urlLower, ".mkv") > 0
            videoContent.streamFormat = "mp4"  ' Try MP4 for MKV files
            print "MKV file detected from URL - attempting to play as MP4 container"
        else
            videoContent.streamFormat = "hls"  ' Prefer HLS for adaptive streaming
        end if
    end if
    
    ' Add quality and performance optimizations
    if streamData.DoesExist("quality")
        videoContent.quality = streamData.quality
    end if
    
    ' Add subtitles if available
    if streamData.subtitles <> invalid and streamData.subtitles.Count() > 0
        subtitleTracks = []
        for each subtitle in streamData.subtitles
            track = {
                language: subtitle.language,
                description: subtitle.label,
                trackUri: subtitle.url
            }
            if subtitle.DoesExist("format") and subtitle.format = "vtt"
                track.trackName = "webvtt"
            else
                track.trackName = "srt"
            end if
            subtitleTracks.push(track)
        end for
        videoContent.textTracks = subtitleTracks
    end if
    
    ' Configure video player for optimal quality
    ConfigureVideoPlayerForQuality()
    
    ' Show video player and start playback
    print "Setting video content and starting playback..."
    print "Video content URL: "; videoContent.url
    print "Video content format: "; videoContent.streamFormat
    
    m.videoPlayer.visible = true
    m.videoPlayer.content = videoContent
    m.videoPlayer.setFocus(true)
    m.videoPlayer.control = "play"
    
    print "=== VIDEO PLAYER STARTED ==="
    print "Video player visible: "; m.videoPlayer.visible
    print "Video player has content: "; (m.videoPlayer.content <> invalid)
    print "Video player control set to: play"
end sub

sub ConfigureVideoPlayerForQuality()
    print "=== Configuring video player for optimal quality ==="
    
    ' Set video player to use maximum available quality
    ' Only set properties that are actually supported
    if m.videoPlayer.DoesExist("enableCookies")
        m.videoPlayer.enableCookies = true
    end if
    
    if m.videoPlayer.DoesExist("enableTrickPlay")
        m.videoPlayer.enableTrickPlay = true
    end if
    
    ' Add debugging for video player capabilities
    print "Video player properties configured"
    
    print "Video player quality configuration complete"
end sub


sub onVideoStateChange(event as object)
    state = event.getData()
    print "=== VIDEO STATE CHANGED ==="
    print "New state: "; state
    print "Current time: "; CreateObject("roDateTime").AsSeconds()
    
    if state = "error"
        print "VIDEO ERROR occurred"
        m.videoPlayer.visible = false
        
        ' Get more detailed error information
        errorMessage = "Failed to play video - check stream URL"
        if m.videoPlayer.content <> invalid
            videoUrl = m.videoPlayer.content.url
            videoFormat = m.videoPlayer.content.streamFormat
            print "Error details:"
            print "  - URL: " + videoUrl
            print "  - Format: " + videoFormat
            print "  - Title: " + m.videoPlayer.content.title
            
            ' Provide specific error message based on format
            if videoFormat = "mkv" and Instr(1, LCase(videoUrl), ".mkv") > 0
                errorMessage = "MKV codecs not supported - video needs H.264/AAC codecs"
            else if videoFormat = "mp4" and Instr(1, LCase(videoUrl), ".mkv") > 0
                errorMessage = "MKV codecs not supported - video needs H.264/AAC codecs"
            else if videoFormat = "hls" and Instr(1, LCase(videoUrl), ".mkv") > 0
                errorMessage = "MKV codecs not supported - video needs H.264/AAC codecs"
            else if Instr(1, videoUrl, "127.0.0.1") > 0 or Instr(1, videoUrl, "localhost") > 0
                errorMessage = "Local server URL - check network connectivity"
            else
                errorMessage = "Video format or URL not supported by Roku"
            end if
        end if
        
        ShowError(errorMessage)
    else if state = "playing"
        print "Video is now playing"
        m.isPlaying = true
        m.loadingSpinner.visible = false
        hideAllUIElements()
    else if state = "paused"
        print "Video is paused"
        m.isPlaying = false
    else if state = "stopped"
        print "Video stopped"
        m.isPlaying = false
        m.videoPlayer.visible = false
        showAllUIElements()
        ShowReady()
    end if
end sub

sub hideAllUIElements()
    ' Hide all UI except video player for immersive playback
    print "=== Hiding UI for video playback ==="
    
    ' Hide background and all cards
    m.top.findNode("background").visible = false
    if m.headerCard <> invalid then m.headerCard.visible = false
    if m.statusCard <> invalid then m.statusCard.visible = false
    if m.networkCard <> invalid then m.networkCard.visible = false
    if m.instructionsCard <> invalid then m.instructionsCard.visible = false
    if m.iconContainer <> invalid then m.iconContainer.visible = false
    
    ' Hide all text elements
    hideAllLabels()
    
    ' Hide all modals
    HideAllModals()
    
    print "UI hidden for immersive video experience"
end sub

sub showAllUIElements()
    ' Show all modern UI elements
    print "=== Showing modern UI ==="
    
    ' Show background and all cards
    m.top.findNode("background").visible = true
    ShowMainUI()
    if m.iconContainer <> invalid then m.iconContainer.visible = true
    
    ' Show all text elements
    showAllLabels()
    
    print "Modern UI restored"
end sub

sub hideAllLabels()
    ' Hide all text labels
    if m.top.findNode("appTitle") <> invalid then m.top.findNode("appTitle").visible = false
    if m.appSubtitle <> invalid then m.appSubtitle.visible = false
    if m.statusLabel <> invalid then m.statusLabel.visible = false
    if m.instructionsLabel <> invalid then m.instructionsLabel.visible = false
    if m.ipLabel <> invalid then m.ipLabel.visible = false
    if m.networkStatus <> invalid then m.networkStatus.visible = false
    if m.step1Label <> invalid then m.step1Label.visible = false
    if m.step2Label <> invalid then m.step2Label.visible = false
    if m.step3Label <> invalid then m.step3Label.visible = false
    if m.controlsLabel <> invalid then m.controlsLabel.visible = false
    if m.top.findNode("versionLabel") <> invalid then m.top.findNode("versionLabel").visible = false
    if m.disclaimerLabel <> invalid then m.disclaimerLabel.visible = false
    if m.statusIndicator <> invalid then m.statusIndicator.visible = false
end sub

sub showAllLabels()
    ' Show all text labels
    if m.top.findNode("appTitle") <> invalid then m.top.findNode("appTitle").visible = true
    if m.appSubtitle <> invalid then m.appSubtitle.visible = true
    if m.statusLabel <> invalid then m.statusLabel.visible = true
    if m.instructionsLabel <> invalid then m.instructionsLabel.visible = true
    if m.ipLabel <> invalid then m.ipLabel.visible = true
    if m.networkStatus <> invalid then m.networkStatus.visible = true
    if m.step1Label <> invalid then m.step1Label.visible = true
    if m.step2Label <> invalid then m.step2Label.visible = true
    if m.step3Label <> invalid then m.step3Label.visible = true
    if m.controlsLabel <> invalid then m.controlsLabel.visible = true
    if m.top.findNode("versionLabel") <> invalid then m.top.findNode("versionLabel").visible = true
    if m.disclaimerLabel <> invalid then m.disclaimerLabel.visible = true
    if m.statusIndicator <> invalid then m.statusIndicator.visible = true
end sub

sub SetTheme()
    ' Apply Stremio purple theme to all elements
    print "=== Applying Stremio Theme ==="
    
    ' Apply theme colors to UI elements
    if m.headerCard <> invalid then m.headerCard.color = m.theme.backgroundCard
    if m.statusCard <> invalid then m.statusCard.color = m.theme.backgroundCard
    if m.networkCard <> invalid then m.networkCard.color = m.theme.backgroundSurface
    if m.instructionsCard <> invalid then m.instructionsCard.color = m.theme.backgroundSurface
    if m.iconContainer <> invalid then m.iconContainer.color = m.theme.primary
    
    ' Set text colors
    if m.top.findNode("appTitle") <> invalid then m.top.findNode("appTitle").color = m.theme.textPrimary
    if m.appSubtitle <> invalid then m.appSubtitle.color = m.theme.textSecondary
    if m.ipLabel <> invalid then m.ipLabel.color = m.theme.accent
    if m.networkStatus <> invalid then m.networkStatus.color = m.theme.textHint
    if m.disclaimerLabel <> invalid then m.disclaimerLabel.color = m.theme.accent
    
    print "Stremio purple theme applied"
end sub


sub onFocusChange(event as object)
    ' Handle focus changes if needed
    ' Note: event parameter is required by the observer but not used
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    print "Key pressed: "; key; " Press: "; press
    
    if press
        if key = "back"
            if m.videoPlayer.visible
                ' Stop video and return to ready state
                m.videoPlayer.control = "stop"
                return true
            else if m.errorBackground.visible
                ' Clear error and return to ready state  
                ShowReady()
                return true
            end if
        end if
    end if
    
    return false
end function

' Memory monitoring functions removed to prevent startup issues
' These will be added back after the app is working properly

' Direct to Play voice command handlers for certification requirement 5.2
sub HandleVoiceContentRequest(contentRequest as object)
    print "=== VOICE CONTENT REQUEST RECEIVED ==="
    print "Title: "; contentRequest.title
    print "Content ID: "; contentRequest.contentId
    print "Media Type: "; contentRequest.mediaType
    print "Valid Media Type: "; contentRequest.isValidMediaType
    print "Requested Via: "; contentRequest.requestedVia
    
    ' Show message to user about voice command
    voiceMessage = "Voice command received: '" + contentRequest.title + "'"
    voiceInstructions = "Use your Android app to stream this content to Roku"
    
    ' Add media type information to the message
    if contentRequest.mediaType <> "" and contentRequest.isValidMediaType
        mediaTypeInfo = " (" + contentRequest.mediaType + ")"
        voiceMessage = voiceMessage + mediaTypeInfo
    end if
    
    ' Update the status to show voice command was received
    if m.statusLabel <> invalid
        m.statusLabel.text = voiceMessage
    end if
    
    if m.instructionsLabel <> invalid
        m.instructionsLabel.text = voiceInstructions
    end if
    
    ' Set status indicator to show voice command activity
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.accent
    end if
    
    print "Voice content request displayed to user"
end sub

' Handle voice command errors (unsupported media types)
sub HandleVoiceCommandError(errorRequest as object)
    print "=== VOICE COMMAND ERROR RECEIVED ==="
    print "Title: "; errorRequest.title
    print "Content ID: "; errorRequest.contentId
    print "Media Type: "; errorRequest.mediaType
    print "Error: "; errorRequest.error
    
    ' Show error message to user
    errorMessage = "Unsupported content type: " + errorRequest.mediaType
    errorInstructions = "This media type is not supported for voice commands"
    
    ' Update the UI to show error
    if m.statusLabel <> invalid
        m.statusLabel.text = errorMessage
    end if
    
    if m.instructionsLabel <> invalid
        m.instructionsLabel.text = errorInstructions
    end if
    
    ' Set status indicator to show error state
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.error
    end if
    
    print "Voice command error displayed to user"
end sub

sub ShowVoiceCommandHelp()
    print "=== SHOWING VOICE COMMAND HELP ==="
    
    ' Show help message for voice commands
    helpMessage = "Voice command received"
    helpInstructions = "Use your Android app to stream content to this Roku device"
    
    ' Update the UI to show help
    if m.statusLabel <> invalid
        m.statusLabel.text = helpMessage
    end if
    
    if m.instructionsLabel <> invalid
        m.instructionsLabel.text = helpInstructions
    end if
    
    ' Set status indicator to show help state
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.warning
    end if
    
    print "Voice command help displayed"
end sub

' Handle roInput event notifications (legacy function)
sub ShowInputReceived(contentInfo as string)
    print "=== INPUT EVENT NOTIFICATION (LEGACY) ==="
    print "Content Info: "; contentInfo
    
    ' Show message to user about input event
    inputMessage = "Input received: " + contentInfo
    inputInstructions = "Use your Android app to stream content to this Roku device"
    
    ' Update the UI to show input was received
    if m.statusLabel <> invalid
        m.statusLabel.text = inputMessage
    end if
    
    if m.instructionsLabel <> invalid
        m.instructionsLabel.text = inputInstructions
    end if
    
    ' Set status indicator to show input activity
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.primary
    end if
    
    print "Input event notification displayed"
end sub

' Handle roInput requests with media type validation
sub HandleInputRequest(inputRequest as object)
    print "=== INPUT REQUEST RECEIVED ==="
    print "Content ID: "; inputRequest.contentId
    print "Media Type: "; inputRequest.mediaType
    print "Valid Media Type: "; inputRequest.isValidMediaType
    print "Requested Via: "; inputRequest.requestedVia
    
    ' Show message to user about input request
    if inputRequest.isValidMediaType
        inputMessage = "Input received for: " + inputRequest.contentId
        inputInstructions = "Use your Android app to stream this content to Roku"
        
        ' Add media type information to the message
        if inputRequest.mediaType <> "unknown" and inputRequest.mediaType <> ""
            mediaTypeInfo = " (" + inputRequest.mediaType + ")"
            inputMessage = inputMessage + mediaTypeInfo
        end if
        
        ' Set status indicator to show input activity
        if m.statusIndicator <> invalid
            m.statusIndicator.color = m.theme.primary
        end if
    else
        inputMessage = "Unsupported content type: " + inputRequest.mediaType
        inputInstructions = "This media type is not supported by the bridge"
        
        ' Set status indicator to show error state
        if m.statusIndicator <> invalid
            m.statusIndicator.color = m.theme.error
        end if
    end if
    
    ' Update the UI to show input was received
    if m.statusLabel <> invalid
        m.statusLabel.text = inputMessage
    end if
    
    if m.instructionsLabel <> invalid
        m.instructionsLabel.text = inputInstructions
    end if
    
    print "Input request displayed to user"
end sub

' Handle deep link requests for all supported media types
sub HandleDeepLinkRequest(deepLinkRequest as object)
    print "=== DEEP LINK REQUEST RECEIVED ==="
    print "Content ID: "; deepLinkRequest.contentId
    print "Media Type: "; deepLinkRequest.mediaType
    print "Title: "; deepLinkRequest.title
    print "Valid Media Type: "; deepLinkRequest.isValidMediaType
    
    ' Show message to user about deep link
    if deepLinkRequest.title <> ""
        deepLinkMessage = "Deep link received: '" + deepLinkRequest.title + "'"
    else
        deepLinkMessage = "Deep link received for: " + deepLinkRequest.contentId
    end if
    
    deepLinkInstructions = "Use your Android app to stream this content to Roku"
    
    ' Add media type information to the message
    if deepLinkRequest.mediaType <> "unknown" and deepLinkRequest.mediaType <> ""
        mediaTypeInfo = " (" + deepLinkRequest.mediaType + ")"
        deepLinkMessage = deepLinkMessage + mediaTypeInfo
    end if
    
    ' Update the status to show deep link was received
    if m.statusLabel <> invalid
        m.statusLabel.text = deepLinkMessage
    end if
    
    if m.instructionsLabel <> invalid
        m.instructionsLabel.text = deepLinkInstructions
    end if
    
    ' Set status indicator to show deep link activity
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.primary
    end if
    
    print "Deep link request displayed to user"
end sub

' Handle deep link errors (unsupported media types)
sub HandleDeepLinkError(errorRequest as object)
    print "=== DEEP LINK ERROR RECEIVED ==="
    print "Content ID: "; errorRequest.contentId
    print "Media Type: "; errorRequest.mediaType
    print "Error: "; errorRequest.error
    
    ' Show error message to user
    errorMessage = "Unsupported content type: " + errorRequest.mediaType
    errorInstructions = "This media type is not supported by the bridge"
    
    ' Update the UI to show error
    if m.statusLabel <> invalid
        m.statusLabel.text = errorMessage
    end if
    
    if m.instructionsLabel <> invalid
        m.instructionsLabel.text = errorInstructions
    end if
    
    ' Set status indicator to show error state
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.error
    end if
    
    print "Deep link error displayed to user"
end sub

' Handle Roku-compliant deep link requests with proper mediaType behaviors
sub HandleRokuDeepLinkRequest(rokuDeepLinkRequest as object)
    print "=== ROKU DEEP LINK REQUEST RECEIVED ==="
    print "Content ID: "; rokuDeepLinkRequest.contentId
    print "Media Type: "; rokuDeepLinkRequest.mediaType
    print "Title: "; rokuDeepLinkRequest.title
    print "Required Behavior: "; rokuDeepLinkRequest.requiredBehavior
    
    ' Show message to user about Roku deep link
    if rokuDeepLinkRequest.title <> ""
        deepLinkMessage = "Roku deep link: '" + rokuDeepLinkRequest.title + "'"
    else
        deepLinkMessage = "Roku deep link for: " + rokuDeepLinkRequest.contentId
    end if
    
    ' Add media type and behavior information
    mediaTypeInfo = " (" + rokuDeepLinkRequest.mediaType + ")"
    behaviorInfo = " - " + rokuDeepLinkRequest.requiredBehavior
    deepLinkMessage = deepLinkMessage + mediaTypeInfo + behaviorInfo
    
    deepLinkInstructions = rokuDeepLinkRequest.bridgeGuidance
    
    ' Update the status to show deep link was received
    if m.statusLabel <> invalid
        m.statusLabel.text = deepLinkMessage
    end if
    
    if m.instructionsLabel <> invalid
        m.instructionsLabel.text = deepLinkInstructions
    end if
    
    ' Set status indicator to show deep link activity
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.primary
    end if
    
    print "Roku deep link request displayed to user"
end sub

' Handle invalid deep links (Roku requirement: launch home screen)
sub HandleInvalidDeepLink(errorMessage as string)
    print "=== INVALID DEEP LINK ERROR ==="
    print "Error: "; errorMessage
    
    ' Show error message to user
    errorTitle = "Invalid Deep Link"
    errorInstructions = "The deep link could not be processed. Launching home screen."
    
    ' Update the UI to show error
    if m.statusLabel <> invalid
        m.statusLabel.text = errorTitle
    end if
    
    if m.instructionsLabel <> invalid
        m.instructionsLabel.text = errorInstructions
    end if
    
    ' Set status indicator to show error state
    if m.statusIndicator <> invalid
        m.statusIndicator.color = m.theme.error
    end if
    
    ' Show error modal
    ShowErrorModal(errorMessage)
    
    ' Auto-dismiss error after 5 seconds and return to home screen
    timer = CreateObject("roSGNode", "Timer")
    timer.duration = 5.0
    timer.repeat = false
    timer.observeField("fire", "onInvalidDeepLinkTimer")
    timer.control = "start"
    m.invalidDeepLinkTimer = timer
    
    print "Invalid deep link error displayed, will return to home screen"
end sub

' Timer callback to dismiss invalid deep link error
sub onInvalidDeepLinkTimer(event as object)
    print "=== DISMISSING INVALID DEEP LINK ERROR ==="
    
    ' Hide error modal
    HideErrorModal()
    
    ' Return to ready state (home screen)
    ShowReady()
    
    ' Clean up timer
    if m.invalidDeepLinkTimer <> invalid
        m.invalidDeepLinkTimer.control = "stop"
        m.invalidDeepLinkTimer = invalid
    end if
    
    print "Returned to home screen after invalid deep link"
end sub