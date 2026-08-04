$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot "dist"
$outputFile = Join-Path $outputDirectory "stroku-receiver.zip"

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
if (Test-Path $outputFile) {
    Remove-Item -LiteralPath $outputFile
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::Open($outputFile, [System.IO.Compression.ZipArchiveMode]::Create)

$items = @("manifest", "source", "components", "images")

foreach ($item in $items) {
    $itemPath = Join-Path $projectRoot $item
    if (Test-Path $itemPath -PathType Leaf) {
        $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $itemPath, $item)
    } elseif (Test-Path $itemPath -PathType Container) {
        # Explicitly write the directory entry
        $null = $zip.CreateEntry(($item + "/"))
        $files = Get-ChildItem -Path $itemPath -Recurse -File
        foreach ($file in $files) {
            # Compute relative path and normalize slashes
            $relativeName = $file.FullName.Substring($projectRoot.Length).TrimStart("\").Replace("\", "/")
            $null = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, $relativeName)
        }
    }
}

$zip.Dispose()
Write-Output $outputFile


