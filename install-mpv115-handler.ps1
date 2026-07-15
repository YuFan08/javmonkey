$ErrorActionPreference = 'Stop'
$sourceHandler = Join-Path $PSScriptRoot 'mpv115-handler.cs'
$sourceClipboard = Join-Path $PSScriptRoot 'mpv115-clipboard.lua'
if (-not (Test-Path -LiteralPath $sourceHandler -PathType Leaf)) {
    throw "Handler not found: $sourceHandler"
}
if (-not (Test-Path -LiteralPath $sourceClipboard -PathType Leaf)) {
    throw "Clipboard helper not found: $sourceClipboard"
}

$installDir = Join-Path $env:LOCALAPPDATA 'mpv115'
$handler = Join-Path $installDir 'mpv115-handler.exe'
$tempHandler = Join-Path $env:TEMP ("mpv115-handler-{0}.exe" -f [guid]::NewGuid())
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $csc -PathType Leaf)) {
    $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
New-Item -Path $installDir -ItemType Directory -Force | Out-Null
try {
    & $csc /nologo /target:winexe /out:$tempHandler $sourceHandler
    if ($LASTEXITCODE -ne 0) { throw 'Failed to compile mpv115 handler' }
    Copy-Item -LiteralPath $tempHandler -Destination $handler -Force
} finally {
    Remove-Item -LiteralPath $tempHandler -Force -ErrorAction SilentlyContinue
}

$mpvScripts = 'C:\Users\mugon\Documents\PythonStudio\MyMPV\portable_config\scripts'
Copy-Item -LiteralPath $sourceClipboard -Destination (Join-Path $mpvScripts 'mpv115-clipboard.lua') -Force
Remove-Item -LiteralPath (Join-Path $installDir 'mpv115-handler.ps1') -Force -ErrorAction SilentlyContinue

$root = 'HKCU:\Software\Classes\mpv115'
New-Item -Path "$root\shell\open\command" -Force | Out-Null
Set-Item -Path $root -Value 'URL:MPV 115 Protocol'
New-ItemProperty -Path $root -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
Set-Item -Path "$root\shell\open\command" -Value ('"{0}" "%1"' -f $handler)

Write-Host 'mpv115:// protocol installed for the current user.'
