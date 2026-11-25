# Melvor Idle 2 简体中文覆盖层卸载脚本
# 只删除游戏目录里的 override.cfg 和 mod 文件夹，不删除、不改动 Melvor2.exe。
# 不启动游戏。游戏正在运行时会中止。
#Requires -Version 5.1
[CmdletBinding()]
param(
    [string]$GameDir = 'E:\Games\SteamLibrary\steamapps\common\Melvor Idle 2'
)

$ErrorActionPreference = 'Stop'
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Test-GameRunning {
    $procs = @(Get-Process -Name 'Melvor2' -ErrorAction SilentlyContinue)
    return $procs.Count -gt 0
}

Write-Host ''
Write-Host '=== Melvor Idle 2 简体中文覆盖层 卸载 ===' -ForegroundColor Cyan
Write-Host '只会删除 override.cfg 和 mod 文件夹，不会改动 Melvor2.exe。' -ForegroundColor DarkGray
Write-Host ''

if (-not (Test-Path -LiteralPath $GameDir)) {
    throw "找不到游戏目录：$GameDir`n可用 -GameDir 指定 Melvor2.exe 所在文件夹。"
}
$exe = Join-Path $GameDir 'Melvor2.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    throw "该目录里没有 Melvor2.exe：$GameDir"
}

if (Test-GameRunning) {
    throw '检测到 Melvor2.exe 正在运行。请先完全退出游戏后再卸载。'
}

$dstCfg = Join-Path $GameDir 'override.cfg'
$dstMod = Join-Path $GameDir 'mod'
$removed = @()

if (Test-Path -LiteralPath $dstCfg) {
    Remove-Item -LiteralPath $dstCfg -Force
    $removed += $dstCfg
}
if (Test-Path -LiteralPath $dstMod) {
    Remove-Item -LiteralPath $dstMod -Recurse -Force
    $removed += $dstMod
}

if ($removed.Count -eq 0) {
    Write-Host '游戏目录里没有覆盖层文件，无需删除。' -ForegroundColor Yellow
} else {
    Write-Host '已删除：' -ForegroundColor Green
    foreach ($r in $removed) { Write-Host "  $r" }
}

Write-Host ''
Write-Host 'Melvor2.exe 未被改动。请自行重新启动游戏；界面会回到官方英文（以及游戏自带、但默认未加载的语言资源状态）。' -ForegroundColor Cyan
Write-Host '本脚本没有启动游戏。' -ForegroundColor DarkGray
exit 0
