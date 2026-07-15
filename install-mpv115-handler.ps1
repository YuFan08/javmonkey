$ErrorActionPreference = 'Stop'
$handler = Join-Path $PSScriptRoot 'mpv115-handler.ps1'
if (-not (Test-Path -LiteralPath $handler -PathType Leaf)) {
    throw "Handler not found: $handler"
}

$root = 'HKCU:\Software\Classes\mpv115'
New-Item -Path "$root\shell\open\command" -Force | Out-Null
Set-Item -Path $root -Value 'URL:MPV 115 Protocol'
New-ItemProperty -Path $root -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
Set-Item -Path "$root\shell\open\command" -Value ('powershell.exe -NoProfile -ExecutionPolicy Bypass -File "{0}" "%1"' -f $handler)

Write-Host 'mpv115:// protocol installed for the current user.'
