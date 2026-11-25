# Pack the shareable Melvor2 zh-CN overlay zip.
# ASCII filename only. Zip root contains override.cfg, mod/, README.md, and SHA256SUMS.txt.
# Maintainer tooling only; players unzip the pack into the game folder.
#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$stageRoot = Join-Path $repo 'work\overlay-release-stage'
$buildId = '26886380'
$zipName = 'Melvor2_zh-CN_overlay_build{0}.zip' -f $buildId

$required = @(
    'README.md',
    'SHA256SUMS.txt',
    'override.cfg',
    'mod\zh_CN.po',
    'mod\zh_CN_patch.gd'
)

foreach ($rel in $required) {
    $p = Join-Path $repo $rel
    if (-not (Test-Path -LiteralPath $p)) {
        throw "missing required file: $rel"
    }
}

if (Test-Path -LiteralPath $stageRoot) {
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}
New-Item -ItemType Directory -Path (Join-Path $stageRoot 'mod') | Out-Null

foreach ($rel in $required) {
    $src = Join-Path $repo $rel
    $dst = Join-Path $stageRoot $rel
    $dstDir = Split-Path -Parent $dst
    if (-not (Test-Path -LiteralPath $dstDir)) {
        New-Item -ItemType Directory -Path $dstDir | Out-Null
    }
    Copy-Item -LiteralPath $src -Destination $dst -Force
}

Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = Join-Path $repo $zipName
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}
# includeBaseDirectory=$false so override.cfg and mod/ sit at the zip root
[System.IO.Compression.ZipFile]::CreateFromDirectory($stageRoot, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

$hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLowerInvariant()
$shaPath = $zipPath + '.sha256.txt'
$line = $hash + '  ' + $zipName + [Environment]::NewLine
[System.IO.File]::WriteAllText($shaPath, $line, [System.Text.UTF8Encoding]::new($false))

$bytes = (Get-Item -LiteralPath $zipPath).Length
Write-Output ($zipName + ' ' + $hash + ' bytes=' + $bytes)
Write-Output 'DONE'
