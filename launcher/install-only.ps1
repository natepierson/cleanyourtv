# Install the launcher APK and stop. Nothing else.
#
# Pushes the release APK and runs: pm install -r
# Then grants ACCESS_FINE_LOCATION so the Wi-Fi pill can read the network name
# when Location is already on. It does not turn Location on.
#
# It does not change which app the Home button opens.
# It does not turn any package off.
# It does not enable a key helper.
# It does not restart the TV.
# A verification or signature refusal stops here. There is no second attempt.
#
# Usage, from the repository root, after tools\venv exists:
#   powershell -ExecutionPolicy Bypass -File launcher\install-only.ps1 -TvHost 192.168.1.50
#   powershell -ExecutionPolicy Bypass -File launcher\install-only.ps1 -TvHost 192.168.1.50 -Apk C:\tvhome.apk
#
# The APK defaults to launcher\app\build\outputs\apk\release\app-release.apk.
# Build that first (launcher\INSTALL-ONLY.md). This script does not build.
param(
    [string]$TvHost = $env:TV_HOST,
    [string]$Apk = ''
)
$ErrorActionPreference = 'Stop'
$OutputEncoding = New-Object System.Text.UTF8Encoding $false
if (-not $TvHost) { throw 'pass -TvHost <tv ip> or set $env:TV_HOST. Nothing was sent.' }
$env:TV_HOST = $TvHost
Set-Location $PSScriptRoot

if (-not $Apk) { $Apk = 'app\build\outputs\apk\release\app-release.apk' }
if (-not (Test-Path -LiteralPath $Apk)) {
    throw "no APK at $Apk. Build it first (launcher\INSTALL-ONLY.md). Nothing was sent."
}
$Apk = (Resolve-Path -LiteralPath $Apk).Path

$py = '..\tools\venv\Scripts\python.exe'
if (-not (Test-Path $py)) {
    throw 'run: python -m venv tools\venv; tools\venv\Scripts\python.exe -m pip install -r tools\requirements.txt. Nothing was sent.'
}

& $py -I ..\tools\b64push.py $Apk /data/local/tmp/tvhome.apk
if ($LASTEXITCODE -ne 0) { throw 'APK upload failed. The launcher on the TV was not replaced.' }

# One shot. The temporary file is removed either way. tv.py does not return the TV shell's status,
# so the word Success has to be its own line: the command echoed above does not contain it.
$out = (& $py -I ..\tools\tv.py 'pm install -r /data/local/tmp/tvhome.apk; rm -f /data/local/tmp/tvhome.apk') -join "`n"
Write-Host $out
$lines = @($out -split '\r?\n' | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' })
$success = $lines -contains 'Success'
$refusal = $lines | Where-Object {
    $_ -match 'INSTALL_FAILED_UPDATE_INCOMPATIBLE|INSTALL_FAILED_VERIFICATION_FAILURE|INSTALL_PARSE_FAILED_NO_CERTIFICATES|INSTALL_FAILED_INVALID_APK|INSTALL_FAILED_OLDER_SDK|INSTALL_FAILED_DEPRECATED_SDK_VERSION|INSTALL_FAILED_SHARED_USER_INCOMPATIBLE|signatures do not match'
} | Select-Object -First 1
if ($refusal) {
    throw "Install refused ($refusal). Stopping. Nothing was removed, and the Home button was left as it was."
}
if ($LASTEXITCODE -ne 0 -or -not $success -or ($out -match 'INSTALL_FAILED')) {
    throw 'pm install did not report Success. Stopping. The Home button was left as it was.'
}

# The pill needs this to read the network name. A refusal here leaves the app installed.
$grant = (& $py -I ..\tools\tv.py 'pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION') -join "`n"
Write-Host $grant
if ($LASTEXITCODE -ne 0 -or $grant -match '(?i)exception|security') {
    Write-Warning 'The app is installed. The location grant did not complete, so the Wi-Fi pill may say Wi-Fi until Location is on and the grant succeeds.'
}

Write-Host 'Installed com.gathin.tvhome.'
Write-Host 'The Home button still opens whatever it opened before.'
Write-Host 'No package was turned off.'
Write-Host 'No key helper was enabled.'
Write-Host 'The TV was not restarted.'
Write-Host 'Open Home from the stock apps row when you want to look at it.'
