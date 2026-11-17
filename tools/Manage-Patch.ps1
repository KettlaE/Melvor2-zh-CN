param([ValidateSet('install','update','restore','check')][string]$Action='check')
$ErrorActionPreference = 'Stop'
try {
    $titles = @{
        install = 'Melvor2 一键汉化'
        update  = 'Melvor2 更新汉化'
        restore = 'Melvor2 取消汉化'
        check   = 'Melvor2 汉化检查'
    }
    $host.UI.RawUI.WindowTitle = $titles[$Action]
    Write-Host ""
    Write-Host ("=== " + $titles[$Action] + " ===") -ForegroundColor Cyan
    if ($Action -eq 'install' -or $Action -eq 'update') {
        Write-Host "正在处理，大约需要 2-3 分钟，请不要关闭本窗口..." -ForegroundColor Yellow
    } elseif ($Action -eq 'restore') {
        Write-Host "正在还原官方英文版..." -ForegroundColor Yellow
    } else {
        Write-Host "正在检查版本与汉化状态..." -ForegroundColor Yellow
    }
    & (Join-Path $PSScriptRoot 'Patch-Game.ps1') -Action $Action
    Write-Host ""
    switch ($Action) {
        'install' { Write-Host "完成：汉化已写入 Melvor2.exe。请自行启动游戏查看。" -ForegroundColor Green }
        'update'  { Write-Host "完成：汉化已更新。" -ForegroundColor Green }
        'restore' { Write-Host "完成：已还原官方 Melvor2.exe。" -ForegroundColor Green }
        'check'   { Write-Host "完成：检查结束（上方 JSON 为详细结果）。" -ForegroundColor Green }
    }
    Write-Host "未自动启动游戏。" -ForegroundColor DarkGray
    exit 0
} catch {
    Write-Host ""
    Write-Host ("失败：" + $_.Exception.Message) -ForegroundColor Red
    if ($_.ScriptStackTrace) { Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed }
    exit 1
}
