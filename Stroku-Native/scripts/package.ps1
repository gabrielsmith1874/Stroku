$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$outputDirectory = Join-Path $projectRoot "dist"
$outputFile = Join-Path $outputDirectory "stroku-native.zip"

New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
if (Test-Path $outputFile) {
    Remove-Item -LiteralPath $outputFile
}

Push-Location $projectRoot
try {
    & npx.cmd --yes brighterscript `
        --no-project `
        --root-dir . `
        --files "manifest" "source/**/*" "components/**/*" "images/**/*" `
        --out-file $outputFile `
        --diagnostic-level error
    if ($LASTEXITCODE -ne 0) {
        throw "BrighterScript could not package the application."
    }
} finally {
    Pop-Location
}

Write-Output $outputFile

