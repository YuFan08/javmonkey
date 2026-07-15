param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ProtocolUri
)

$ErrorActionPreference = 'Stop'
$mpv = 'C:\Users\mugon\Documents\PythonStudio\MyMPV\mpv.com'

$uri = [Uri]$ProtocolUri
if ($uri.Scheme -ne 'mpv115' -or $uri.Host -ne 'play') {
    throw 'Expected mpv115://play URI'
}

$query = @{}
foreach ($pair in $uri.Query.TrimStart('?').Split('&', [StringSplitOptions]::RemoveEmptyEntries)) {
    $parts = $pair.Split('=', 2)
    if ($parts.Count -eq 2) {
        $query[[Uri]::UnescapeDataString($parts[0])] = [Uri]::UnescapeDataString($parts[1].Replace('+', ' '))
    }
}

$mediaUrl = [Uri]$query.url
if ($mediaUrl.Scheme -ne 'https') {
    throw 'Only https media URLs are allowed'
}
if (-not (Test-Path -LiteralPath $mpv -PathType Leaf)) {
    throw "MPV not found: $mpv"
}

$title = [string]$query.title -replace '[\x00-\x1f"]', "'"
$title = $title.Substring(0, [Math]::Min(160, $title.Length))
$userAgent = [string]$query.ua -replace '[\x00-\x1f"]', ''
$userAgent = $userAgent.Substring(0, [Math]::Min(300, $userAgent.Length))

Start-Process -FilePath $mpv -ArgumentList @(
    '--referrer=https://115.com/',
    ('--user-agent="{0}"' -f $userAgent),
    ('--title="{0}"' -f $title),
    '--force-window=yes',
    ('"{0}"' -f $mediaUrl.AbsoluteUri)
)
