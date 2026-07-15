param([string]$MpvExe)

$ErrorActionPreference = 'Stop'
$sourceHandler = Join-Path $PSScriptRoot 'mpv115-handler.cs'
$sourceClipboard = Join-Path $PSScriptRoot 'mpv115-clipboard.lua'
if (-not (Test-Path -LiteralPath $sourceHandler -PathType Leaf)) {
    throw "Handler not found: $sourceHandler"
}
if (-not (Test-Path -LiteralPath $sourceClipboard -PathType Leaf)) {
    throw "Clipboard helper not found: $sourceClipboard"
}

function Find-MpvExe {
    if ($MpvExe -and (Test-Path -LiteralPath $MpvExe -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $MpvExe).Path
    }
    if ($env:MPV_EXE -and (Test-Path -LiteralPath $env:MPV_EXE -PathType Leaf)) {
        return (Resolve-Path -LiteralPath $env:MPV_EXE).Path
    }
    $command = Get-Command mpv.exe -ErrorAction SilentlyContinue
    if ($command) { return $command.Source }
    foreach ($dir in @($PSScriptRoot, (Split-Path -Parent $PSScriptRoot))) {
        $found = Get-ChildItem -LiteralPath $dir -Filter mpv.exe -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if (-not $found) {
            $found = Get-ChildItem -LiteralPath $dir -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Filter mpv.exe -File -ErrorAction SilentlyContinue } |
                Select-Object -First 1
        }
        if ($found) { return $found.FullName }
    }
    throw 'mpv.exe not found. Install MPV, add it to PATH, set MPV_EXE, or run: .\install-mpv115-handler.ps1 -MpvExe C:\path\to\mpv.exe'
}

$mpv = Find-MpvExe
$installDir = Join-Path $env:LOCALAPPDATA 'mpv115'
$handler = Join-Path $installDir 'mpv115-handler.exe'
$tempHandler = Join-Path $env:TEMP ("mpv115-handler-{0}.exe" -f [guid]::NewGuid())
$tempSource = Join-Path $env:TEMP ("mpv115-handler-{0}.cs" -f [guid]::NewGuid())
$csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if (-not (Test-Path -LiteralPath $csc -PathType Leaf)) {
    $csc = Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'
}
New-Item -Path $installDir -ItemType Directory -Force | Out-Null
try {
    (Get-Content -LiteralPath $sourceHandler -Raw).Replace('__MPV_EXE__', $mpv.Replace('\', '\\')) | Set-Content -LiteralPath $tempSource -Encoding UTF8
    & $csc /nologo /target:winexe /out:$tempHandler $tempSource
    if ($LASTEXITCODE -ne 0) { throw 'Failed to compile mpv115 handler' }
    Remove-Item -LiteralPath $handler -Force -ErrorAction SilentlyContinue
    Copy-Item -LiteralPath $tempHandler -Destination $handler -Force
} finally {
    Remove-Item -LiteralPath $tempHandler -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $tempSource -Force -ErrorAction SilentlyContinue
}

$portableScripts = Join-Path (Split-Path -Parent $mpv) 'portable_config\scripts'
if (Test-Path -LiteralPath $portableScripts -PathType Container) {
    Copy-Item -LiteralPath $sourceClipboard -Destination (Join-Path $portableScripts 'mpv115-clipboard.lua') -Force
}
Remove-Item -LiteralPath (Join-Path $installDir 'mpv115-handler.ps1') -Force -ErrorAction SilentlyContinue

$root = 'HKCU:\Software\Classes\mpv115'
New-Item -Path "$root\shell\open\command" -Force | Out-Null
Set-Item -Path $root -Value 'URL:MPV 115 Protocol'
New-ItemProperty -Path $root -Name 'URL Protocol' -Value '' -PropertyType String -Force | Out-Null
Set-Item -Path "$root\shell\open\command" -Value ('"{0}" "%1"' -f $handler)

Write-Host 'mpv115:// protocol installed for the current user.'
Write-Host "MPV: $mpv"
