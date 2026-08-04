param(
    [string]$ManifestUrl = "http://127.0.0.1:7319/manifest.json"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$stagingRoot = Join-Path $env:TEMP "stroku-native-mock"
$outputFile = Join-Path $projectRoot "dist\stroku-native-mock.zip"

if (Test-Path $stagingRoot) {
    $resolvedStaging = (Resolve-Path $stagingRoot).Path
    $resolvedTemp = (Resolve-Path $env:TEMP).Path
    if (-not $resolvedStaging.StartsWith($resolvedTemp, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Refusing to remove staging directory outside TEMP: $resolvedStaging"
    }
    Remove-Item -LiteralPath $resolvedStaging -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $stagingRoot | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot "manifest") -Destination $stagingRoot
Copy-Item -LiteralPath (Join-Path $projectRoot "source") -Destination $stagingRoot -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot "components") -Destination $stagingRoot -Recurse
Copy-Item -LiteralPath (Join-Path $projectRoot "images") -Destination $stagingRoot -Recurse

$scenePath = Join-Path $stagingRoot "components\MainScene.brs"
$scene = Get-Content -LiteralPath $scenePath -Raw
$escapedUrl = $ManifestUrl.Replace('"', '""')
$replacement = @"
sub LoadAddonConfiguration()
    m.addonManifestUrls = ["$escapedUrl"]
    StartRequest("$escapedUrl", "addonLoad|0")
end sub
"@
$pattern = '(?s)sub LoadAddonConfiguration\(\).*?end sub'
$patched = [regex]::Replace($scene, $pattern, $replacement, 1)
if ($patched -eq $scene) {
    throw "Could not inject the mock addon URL."
}

$mockOrigin = ([uri]$ManifestUrl).GetLeftPart([System.UriPartial]::Authority)
$patched = $patched.Replace("https://link.stremio.com", $mockOrigin)
$patched = $patched.Replace("https://api.strem.io", $mockOrigin)
$patched = $patched.Replace("https://v3-cinemeta.strem.io", $mockOrigin)

$patched = $patched.Replace(
    '    if m.streams.Count() = 0',
    @'
    print "[mock-test] directStreams="; m.streams.Count(); " rawTorrents="; m.torrentOnlyCount

    if m.streams.Count() = 0
'@
)
$patched = $patched.Replace(
    '    if not response.ok',
    @'
    if not response.ok
        print "[mock-test] requestError="; response.error
'@
)
$patched = $patched.Replace(
    '    m.video.SetHeaders(playbackHeaders)',
    @'
    headersApplied = m.video.SetHeaders(playbackHeaders)
    print "[mock-test] headersApplied="; headersApplied
'@
)
$patched = $patched.Replace(
    '    m.video.subtitleOptions = subtitleOptions',
    @'
    print "[mock-test] assigningSubtitleOptions="; subtitleOptions.Count()
    m.video.subtitleOptions = subtitleOptions
    print "[mock-test] assignedSubtitleOptions=true"
'@
)
$patched = $patched.Replace(
    '    m.video.hasNextEpisode = HasNextEpisode()',
    @'
    print "[mock-test] assigningNextEpisode"
    m.video.hasNextEpisode = HasNextEpisode()
    print "[mock-test] assignedNextEpisode="; m.video.hasNextEpisode
'@
)
$patched = $patched.Replace(
    '    m.video.content = content',
    @'
    print "[mock-test] playbackUrl="; content.url
    print "[mock-test] playbackFormat="; content.streamFormat
    print "[mock-test] playbackHeaders="; playbackHeaders.Count()
    print "[mock-test] playbackSubtitles="; subtitleOptions.Count()
    m.video.content = content
'@
)
[System.IO.File]::WriteAllText(
    $scenePath,
    $patched,
    [System.Text.UTF8Encoding]::new($false)
)

if (Test-Path $outputFile) {
    Remove-Item -LiteralPath $outputFile
}

& npx.cmd --yes brighterscript `
    --no-project `
    --root-dir $stagingRoot `
    --files "manifest" "source/**/*" "components/**/*" "images/**/*" `
    --out-file $outputFile `
    --diagnostic-level error
if ($LASTEXITCODE -ne 0) {
    throw "BrighterScript could not package the mock application."
}

Write-Output $outputFile
