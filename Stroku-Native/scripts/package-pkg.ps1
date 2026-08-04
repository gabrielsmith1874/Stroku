<#
.SYNOPSIS
    Builds, sideloads, and signs a Roku .pkg ready for the Developer Dashboard.

.DESCRIPTION
    Run it with no arguments. The first run asks for the two secrets once and
    caches them; every run after that is fully unattended.

        ROKU_DEV_PASSWORD      the dev webserver password (user "rokudev")
        ROKU_SIGNING_PASSWORD  the developer key from `genkey` / `showkey`

    Lookup order for each secret: environment variable, then the cache, then an
    interactive prompt (whose answer is written to the cache).

    The cache lives outside the repo, under %LOCALAPPDATA%, and is encrypted with
    DPAPI -- readable only by this Windows user on this machine. Nothing is ever
    written to the working tree, so there is nothing to leak through git.

.PARAMETER ResetSecrets
    Discards the cache and prompts again. Use after changing the webserver
    password or running genkey.

.EXAMPLE
    npm run package:pkg

.EXAMPLE
    powershell -File scripts/package-pkg.ps1 -ResetSecrets
#>
param(
    [string]$RokuIp = $(if ($env:ROKU_IP) { $env:ROKU_IP } else { "" }),
    [switch]$ResetSecrets
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$RokuIp = $RokuIp.Trim()
if ([string]::IsNullOrWhiteSpace($RokuIp)) {
    throw "Set ROKU_IP or pass -RokuIp with the Roku device address before sideloading."
}
$outputDirectory = Join-Path $projectRoot "dist"
$zipFile = Join-Path $outputDirectory "stroku-native.zip"

$secretStore = Join-Path $env:LOCALAPPDATA "Stroku\roku-secrets.xml"

if ($ResetSecrets -and (Test-Path $secretStore)) {
    Remove-Item -LiteralPath $secretStore -Force
    Write-Host "Cleared cached credentials."
}

function Read-SecretCache {
    if (-not (Test-Path $secretStore)) { return @{} }
    try {
        $loaded = Import-Clixml -LiteralPath $secretStore
        if ($loaded -is [hashtable]) { return $loaded }
    } catch {
        # A cache written by another user or machine cannot be decrypted. Treat
        # it as absent and prompt again rather than failing the build.
        Write-Host "Cached credentials could not be read; prompting again."
    }
    return @{}
}

function Save-SecretCache([hashtable]$cache) {
    $parent = Split-Path -Parent $secretStore
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    # SecureString members are DPAPI-encrypted by Export-Clixml.
    $cache | Export-Clixml -LiteralPath $secretStore -Force
}

function ConvertFrom-SecureStringPlain([Security.SecureString]$secure) {
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
    }
}

$secretCache = Read-SecretCache
$cacheDirty = $false

function Get-Secret([string]$envName, [string]$promptText) {
    $fromEnv = [Environment]::GetEnvironmentVariable($envName)
    if (-not [string]::IsNullOrWhiteSpace($fromEnv)) { return $fromEnv }

    if ($secretCache.ContainsKey($envName)) {
        return ConvertFrom-SecureStringPlain $secretCache[$envName]
    }

    $secure = Read-Host -Prompt $promptText -AsSecureString
    $value = ConvertFrom-SecureStringPlain $secure
    if ([string]::IsNullOrWhiteSpace($value)) {
        throw "$envName is required."
    }

    $script:secretCache[$envName] = $secure
    $script:cacheDirty = $true
    return $value
}

$devPassword = Get-Secret "ROKU_DEV_PASSWORD" "Roku dev webserver password (user rokudev)"
$signingPassword = Get-Secret "ROKU_SIGNING_PASSWORD" "Roku developer key (signing password)"

if ($cacheDirty) {
    Save-SecretCache $secretCache
    Write-Host "Saved credentials to $secretStore (encrypted, this user only)."
}

# Version the package the same way the manifest does, so the dashboard does not
# reject it as a duplicate.
$manifest = Get-Content (Join-Path $projectRoot "manifest") | Where-Object { $_ -match "=" }
$manifestValues = @{}
foreach ($line in $manifest) {
    $parts = $line -split "=", 2
    $manifestValues[$parts[0].Trim()] = $parts[1].Trim()
}
$appVersion = "{0}.{1}.{2}" -f $manifestValues["major_version"], $manifestValues["minor_version"], $manifestValues["build_version"]
$appName = "{0}/{1}" -f $manifestValues["title"], $appVersion

# curl reads the credential from a config file rather than argv so the password
# is not visible to other processes.
$workDir = Join-Path ([IO.Path]::GetTempPath()) ("roku-pkg-" + [Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $workDir | Out-Null
$curlConfig = Join-Path $workDir "curl.cfg"
$signingFile = Join-Path $workDir "signing.txt"

try {
    Set-Content -Path $curlConfig -Value @("digest", "user = `"rokudev:$devPassword`"") -Encoding ascii
    Set-Content -Path $signingFile -Value $signingPassword -Encoding ascii -NoNewline

    Write-Host "==> Building $zipFile"
    & (Join-Path $PSScriptRoot "package.ps1") | Out-Null
    if (-not (Test-Path $zipFile)) {
        throw "Build did not produce $zipFile."
    }

    Write-Host "==> Sideloading to $RokuIp"
    $installResponse = & curl.exe --silent --show-error --config $curlConfig `
        -F "mysubmit=Install" -F "archive=@$zipFile" -F "passwd=" `
        "http://$RokuIp/plugin_install"
    if ($LASTEXITCODE -ne 0) { throw "Sideload request failed." }

    # The response carries its outcome as typed messages in an embedded JSON
    # blob. Grepping the page as a whole gives false positives -- its own
    # JavaScript contains the word "error" in a comment -- so key off the type.
    # "Identical to previous version" is an info message, not a failure: the
    # channel is installed either way, which is all the packager needs.
    if ($installResponse -match '"type":"error"') {
        $detail = [regex]::Match($installResponse, '"text":"(?<text>[^"]+)"')
        if ($detail.Success) {
            throw "Roku rejected the sideload: $($detail.Groups['text'].Value)"
        }
        throw "Roku rejected the sideload. Check the webserver password (rerun with -ResetSecrets) and that the device is in developer mode."
    }

    Write-Host "==> Signing as $appName"
    $pkgTime = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $packageResponse = & curl.exe --silent --show-error --config $curlConfig `
        -F "mysubmit=Package" -F "app_name=$appName" -F "passwd=<$signingFile" -F "pkg_time=$pkgTime" `
        "http://$RokuIp/plugin_package"
    if ($LASTEXITCODE -ne 0) { throw "Package request failed." }

    $match = [regex]::Match($packageResponse, "pkgs/[^""'>< ]+\.pkg")
    if (-not $match.Success) {
        throw "Roku did not return a package link. The signing key is probably wrong for this device (rerun with -ResetSecrets)."
    }

    $pkgFile = Join-Path $outputDirectory "stroku-native.pkg"
    Write-Host "==> Downloading $($match.Value)"
    & curl.exe --silent --show-error --config $curlConfig -o $pkgFile "http://$RokuIp/$($match.Value)"
    if ($LASTEXITCODE -ne 0) { throw "Package download failed." }

    Write-Output $pkgFile
} finally {
    Remove-Item -Recurse -Force -LiteralPath $workDir -ErrorAction SilentlyContinue
}
