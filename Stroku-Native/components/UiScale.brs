' Shared UI scaling helpers.
'
' Every screen in Stroku is authored once in a fixed 1920x1080 "design space".
' Roku hands the channel a design resolution that depends on the player: 1280x720
' on HD-only devices and 1920x1080 on FHD devices (manifest ui_resolutions=hd,fhd).
' Drawing 1920x1080 coordinates into a 1280x720 design resolution is what makes the
' UI look zoomed in and cropped, so every design-space value has to be mapped onto
' the resolution we actually got.
'
' The mapping is a plain arithmetic pass over the node tree rather than a Group
' scale transform, so text stays natively rendered instead of being resampled.
'
' MainScene publishes the factors on m.global; everything else reads them from
' there, which keeps list/grid item components working even though they are
' created long after the scene.

function UiDesignWidth() as float
    return 1920.0
end function

function UiDesignHeight() as float
    return 1080.0
end function

function UiScaleMinPercent() as integer
    return 70
end function

function UiScaleMaxPercent() as integer
    return 110
end function

function UiScaleStepPercent() as integer
    return 5
end function

function UiScaleDefaultPercent() as integer
    return 100
end function

' Works out how the design space maps onto a device design resolution.
'
' deviceWidth/deviceHeight are what Roku reports for the current design
' resolution, resolutionName is "HD"/"FHD"/"" and userPercent is the manual scale
' from Settings. Pure arithmetic, so it can be exercised on its own.
function ComputeUiScale(deviceWidth as float, deviceHeight as float, resolutionName as string, userPercent as integer) as object
    designWidth = UiDesignWidth()
    designHeight = UiDesignHeight()

    ' Uniform fit so the aspect ratio is never distorted, whatever the device
    ' reports. Any letterboxed remainder is split evenly by the offsets below.
    autoScale = deviceWidth / designWidth
    heightScale = deviceHeight / designHeight
    if heightScale < autoScale then autoScale = heightScale
    if autoScale <= 0.0 then autoScale = 1.0

    userScale = userPercent / 100.0
    if userScale <= 0.0 then userScale = 1.0
    geometry = autoScale * userScale

    ' System font URIs already resolve to the size matching the device design
    ' resolution, so the font factor only has to carry the manual adjustment.
    fontResolutionRatio = autoScale
    if UCase(resolutionName) = "FHD"
        fontResolutionRatio = 1.0
    else if UCase(resolutionName) = "HD"
        fontResolutionRatio = 24.0 / 36.0
    end if
    if fontResolutionRatio <= 0.0 then fontResolutionRatio = 1.0

    return {
        auto: autoScale
        geometry: geometry
        font: geometry / fontResolutionRatio
        offsetX: (deviceWidth - designWidth * geometry) / 2.0
        offsetY: (deviceHeight - designHeight * geometry) / 2.0
    }
end function

' Geometry factor: automatic device fit multiplied by the user's manual scale.
function UiScaleFactor() as float
    return UiScaleGlobalFloat("uiScaleGeometry")
end function

' Font factor: system fonts already come back sized for the device design
' resolution, so this normally only carries the user's manual scale.
function UiScaleFontFactor() as float
    return UiScaleGlobalFloat("uiScaleFont")
end function

' Design space is centred inside the device viewport, which is what keeps a
' reduced manual scale inset evenly instead of anchored to the top left corner.
function UiScaleOffsetX() as float
    return UiScaleGlobalFloat("uiScaleOffsetX", 0.0)
end function

function UiScaleOffsetY() as float
    return UiScaleGlobalFloat("uiScaleOffsetY", 0.0)
end function

function UiScaleGlobalFloat(fieldName as string, fallback = 1.0 as float) as float
    if m.global = invalid then return fallback
    if not m.global.hasField(fieldName) then return fallback
    value = m.global.getField(fieldName)
    if value = invalid then return fallback
    return value
end function

' Converts a design-space length into device space.
function ScaleUi(value as dynamic) as float
    return value * UiScaleFactor()
end function

' Converts a design-space point into a device-space translation.
function ScaleUiXY(x as dynamic, y as dynamic) as object
    factor = UiScaleFactor()
    return [x * factor, y * factor]
end function

' Converts a device-space length back into design space, for the few places that
' read a node's current size and keep measuring in design units.
function UnscaleUi(value as dynamic) as float
    factor = UiScaleFactor()
    if factor <= 0.0 then return value
    return value / factor
end function

' Scales a subtree that was authored in design space.
'
' Safe to call repeatedly: the root records the factor it was last scaled with, so
' only the difference is applied. That lets item components re-check themselves
' every time they are bound to new content, which is how recycled list cards pick
' up a scale the user changed after they were created.
sub EnsureUiScale(root as object)
    if root = invalid then return

    target = UiScaleFactor()
    applied = 1.0
    if root.hasField("uiScaleApplied")
        stored = root.uiScaleApplied
        if stored <> invalid and stored > 0.0 then applied = stored
    else
        root.addField("uiScaleApplied", "float", false)
    end if

    root.uiScaleApplied = target
    if Abs(target - applied) < 0.0005 then return

    ScaleUiTree(root, target / applied, UiScaleFontFactor())
end sub

' Applies a relative geometry factor and an absolute font factor to every
' descendant of root. The root itself is left alone because its own translation is
' owned by whoever placed it (the centring offset, or a parent list).
sub ScaleUiTree(root as object, geometryFactor as float, fontFactor as float)
    childCount = root.getChildCount()
    for index = 0 to childCount - 1
        child = root.getChild(index)
        if child <> invalid and not UiScalesItself(child)
            ScaleUiNode(child, geometryFactor, fontFactor)
            ScaleUiTree(child, geometryFactor, fontFactor)
        end if
    end for
end sub

' True for nodes that run their own scaling pass, which must not also be scaled
' from above: anything already marked, plus list and grid item components. Item
' components are recognised by their itemContent field; whether a firmware version
' exposes them as children of the grid is an implementation detail we should not
' depend on.
function UiScalesItself(node as object) as boolean
    if node.hasField("uiScaleApplied") then return true
    return node.hasField("itemContent")
end function

sub ScaleUiNode(node as object, geometryFactor as float, fontFactor as float)
    for each fieldName in ["width", "height", "maxWidth", "maxHeight", "minWidth", "minHeight", "lineSpacing"]
        if node.hasField(fieldName)
            value = node.getField(fieldName)
            ' Zero means "size to content" on most nodes, so leave it alone.
            if value <> invalid and value > 0 then node.setField(fieldName, value * geometryFactor)
        end if
    end for

    for each fieldName in ["translation", "itemSize", "itemSpacing", "scaleRotateCenter"]
        if node.hasField(fieldName)
            scaled = ScaleUiPair(node.getField(fieldName), geometryFactor)
            if scaled <> invalid then node.setField(fieldName, scaled)
        end if
    end for

    for each fieldName in ["rowSpacings", "rowHeights"]
        if node.hasField(fieldName)
            values = node.getField(fieldName)
            if IsUiArray(values)
                scaled = []
                for each value in values
                    scaled.Push(value * geometryFactor)
                end for
                node.setField(fieldName, scaled)
            end if
        end if
    end for

    for each fieldName in ["rowItemSize", "rowItemSpacing", "rowLabelOffset"]
        if node.hasField(fieldName)
            values = node.getField(fieldName)
            if IsUiArray(values)
                scaled = []
                for each value in values
                    pair = ScaleUiPair(value, geometryFactor)
                    if pair = invalid then pair = value
                    scaled.Push(pair)
                end for
                node.setField(fieldName, scaled)
            end if
        end if
    end for

    for each fieldName in ["font", "focusedFont", "rowLabelFont", "sectionDividerFont", "textFont", "focusedTextFont"]
        if node.hasField(fieldName)
            ScaleUiFont(node.getField(fieldName), fontFactor)
        end if
    end for
end sub

function ScaleUiPair(value as dynamic, factor as float) as dynamic
    if not IsUiArray(value) then return invalid
    if value.Count() <> 2 then return invalid
    return [value[0] * factor, value[1] * factor]
end function

function IsUiArray(value as dynamic) as boolean
    return value <> invalid and Type(value) = "roArray"
end function

' Resizes a font node.
'
' The original size is stashed on the font node itself, so this is idempotent and
' free of rounding drift no matter how often the user nudges the slider. Recording
' it on the node also keeps things correct if the firmware hands the same system
' font instance to several labels.
sub ScaleUiFont(font as object, fontFactor as float)
    if font = invalid then return
    if Type(font) <> "roSGNode" then return
    if not font.hasField("size") then return

    if not font.hasField("uiScaleBaseSize")
        font.addField("uiScaleBaseSize", "float", false)
        font.uiScaleBaseSize = font.size
    end if

    baseSize = font.uiScaleBaseSize
    if baseSize = invalid or baseSize <= 0.0 then return

    newSize = Int((baseSize * fontFactor) + 0.5)
    if newSize < 8 then newSize = 8
    font.size = newSize
end sub
