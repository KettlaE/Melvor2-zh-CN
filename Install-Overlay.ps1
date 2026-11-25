# Melvor Idle 2 简体中文覆盖层安装脚本
# 只复制 override.cfg 和 mod 文件夹；如当前是旧的 exe 改写版，会先还原官方 Melvor2.exe。
# 不启动游戏，不修改 DLL / 存档 / 统计。游戏正在运行时会中止。
#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$GameDir = 'E:\Games\SteamLibrary\steamapps\common\Melvor Idle 2'
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$PackRoot = $PSScriptRoot
$Official26886380 = '4fbd4504809b2d2cf3c12ad962a632f4b1dd0934eebd2452f3766ebc313146d1'
$Official26724394 = '770b22a1c5bf37ab4e3bee0ba8b396a8008ecaa8d970270c3e9ed6d07ceffd3b'
$KnownOfficial = @{
    $Official26886380 = '26886380'
    $Official26724394 = '26724394'
}
# 旧的 exe 改写版哈希 -> 对应官方哈希。覆盖层不能写在这些 exe 上，必须先还原。
$KnownPatched = @{
    'bd660f06968b54bad4ae95d55fc3402df9ef55f1d23bd6c3a9759586a4a6fa44' = $Official26886380
    '166da981c686724c1361bfcb0e3a9210a30a00fe84a2f35aeee7aee1621cc849' = $Official26724394
    'f152025a186ceaa5beb13d76ef746ee05ac2548750e239b8ed62a65fa1105ffc' = $Official26724394
    'a982a738d7b206d6fcda32cf4939f20976e8a09a61accc04e157842be721e302' = $Official26724394
}

function Get-Sha256Lower {
    param([Parameter(Mandatory=$true)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

function Test-GameRunning {
    $procs = @(Get-Process -Name 'Melvor2' -ErrorAction SilentlyContinue)
    return $procs.Count -gt 0
}

Write-Host ''
Write-Host '=== Melvor Idle 2 简体中文覆盖层 安装 ===' -ForegroundColor Cyan
Write-Host '不会改写 Melvor2.exe 的内嵌资源；只复制少量覆盖文件。' -ForegroundColor DarkGray
Write-Host '不会启动游戏。' -ForegroundColor DarkGray
Write-Host ''

$srcCfg = Join-Path $PackRoot 'override.cfg'
$srcPo  = Join-Path $PackRoot 'mod\zh_CN.po'
$srcGd  = Join-Path $PackRoot 'mod\zh_CN_patch.gd'
foreach ($f in @($srcCfg, $srcPo, $srcGd)) {
    if (-not (Test-Path -LiteralPath $f)) {
        throw "安装包不完整，找不到：$f"
    }
}

if (-not (Test-Path -LiteralPath $GameDir)) {
    throw "找不到游戏目录：$GameDir`n可用 -GameDir 指定 Melvor2.exe 所在文件夹。"
}
$exe = Join-Path $GameDir 'Melvor2.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "该目录里没有 Melvor2.exe：$GameDir"
}

if (Test-GameRunning) {
    throw '检测到 Melvor2.exe 正在运行。请先完全退出游戏后再安装。'
}

$current = Get-Sha256Lower -Path $exe
Write-Host ("当前 Melvor2.exe SHA256: $current")
Write-Host ("大小: $((Get-Item -LiteralPath $exe).Length) 字节")

if ($KnownPatched.ContainsKey($current)) {
    $wantOfficial = $KnownPatched[$current]
    Write-Host '当前是旧的 exe 改写版汉化，安装覆盖层前必须先还原官方 Melvor2.exe。' -ForegroundColor Yellow

    $packName = 'Melvor2_' + [string]([char]0x7B80) + [string]([char]0x4F53) + [string]([char]0x4E2D) + [string]([char]0x6587)
    $packDir = Join-Path $GameDir $packName
    $backupHits = @()
    if (Test-Path -LiteralPath $packDir) {
        $backupHits = @(Get-ChildItem -LiteralPath $packDir -Recurse -Filter 'Melvor2.exe.original' -ErrorAction SilentlyContinue)
    }
    $chosen = $null
    foreach ($b in $backupHits) {
        $bh = Get-Sha256Lower -Path $b.FullName
        if ($bh -eq $wantOfficial) {
            $chosen = $b
            break
        }
    }
    if (-not $chosen) {
        throw ("找不到对应的官方备份（期望 SHA256 $wantOfficial）。`n请先用 Steam「验证游戏文件完整性」还原官方 Melvor2.exe，再重新运行本安装脚本。不要在改写版 exe 上直接叠放覆盖层。")
    }
    $bh = Get-Sha256Lower -Path $chosen.FullName
    if ($bh -ne $wantOfficial) {
        throw "官方备份哈希不匹配：$($chosen.FullName)"
    }
    Write-Host ("正在从备份还原官方 exe：$($chosen.FullName)") -ForegroundColor Yellow
    Copy-Item -LiteralPath $chosen.FullName -Destination $exe -Force
    $after = Get-Sha256Lower -Path $exe
    if ($after -ne $wantOfficial) {
        throw "还原后哈希仍不是官方版本（得到 $after）。已中止，未复制覆盖层。"
    }
    Write-Host ("已还原官方 Melvor2.exe：$after") -ForegroundColor Green
    $current = $after
}
elseif ($KnownOfficial.ContainsKey($current)) {
    Write-Host ("已确认是官方 exe（build $($KnownOfficial[$current])），无需还原。") -ForegroundColor Green
}
else {
    Write-Host '当前 exe 不在已知官方/改写哈希列表中。按新的 Steam 官方版本处理，只复制覆盖层，不会覆盖 exe。' -ForegroundColor Yellow
    Write-Host '若这其实是未知的改写版 exe，请先用 Steam 验证文件完整性，再重新安装。' -ForegroundColor Yellow
}

$dstCfg = Join-Path $GameDir 'override.cfg'
$dstMod = Join-Path $GameDir 'mod'
if (-not (Test-Path -LiteralPath $dstMod)) {
    New-Item -ItemType Directory -Path $dstMod | Out-Null
}
Copy-Item -LiteralPath $srcCfg -Destination $dstCfg -Force
Copy-Item -LiteralPath $srcPo  -Destination (Join-Path $dstMod 'zh_CN.po') -Force
Copy-Item -LiteralPath $srcGd  -Destination (Join-Path $dstMod 'zh_CN_patch.gd') -Force

Write-Host ''
Write-Host '覆盖层已复制到游戏目录：' -ForegroundColor Green
Write-Host "  $dstCfg"
Write-Host "  $(Join-Path $dstMod 'zh_CN.po')"
Write-Host "  $(Join-Path $dstMod 'zh_CN_patch.gd')"
Write-Host ''
Write-Host '请自行从 Steam 启动游戏，在 设置 → 语言 选择「简体中文」。' -ForegroundColor Cyan
Write-Host '本脚本没有启动游戏。若之前一直用旧的 en_GB 改写版，语言可能仍停在 English，需要手动切换一次。' -ForegroundColor DarkGray
exit 0
