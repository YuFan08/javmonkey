$ErrorActionPreference = 'Stop'
$sourceHandler = Join-Path $PSScriptRoot 'mpv115-handler.ps1'
if (-not (Test-Path -LiteralPath $sourceHandler -PathType Leaf)) {
    throw "Handler not found: $sourceHandler"
}

$installDir = Join-Path $env:LOCALAPPDATA 'mpv115'
$handler = Join-Path $installDir 'mpv115-handler.ps1'
New-Item -Path $installDir -ItemType Directory -Force | Out-Null
Copy-Item -LiteralPath $sourceHandler -Destination $handler -Force

$root = 'HKCU:\Software\Classes\mpv115'
New-Item -Path "$root\shell\open\command" -Force | Out-Null
Set-Item -Path $root -Value 'URL:MPV 115 Protocol'
New-ItemProperty -Path $root -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
Set-Item -Path "$root\shell\open\command" -Value ('powershell.exe -NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" "%1"' -f $handler)

Write-Host 'mpv115:// protocol installed for the current user.'
