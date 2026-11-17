# Version-locked install/update/restore/check. Never starts the game. Pure PowerShell.
param(
    [Parameter(Mandatory)][ValidateSet('install','update','restore','check')][string]$Action,
    [string]$GameDir,
    [string]$Manifest,
    [bool]$CheckProcess = $true
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'EmbeddedPckPatch.ps1')

$W = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

function Test-ContainedPath([string]$Path, [string]$Parent) {
    $full = [System.IO.Path]::GetFullPath($Path)
    $parentFull = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\')
    return $full.Equals($parentFull, [StringComparison]::OrdinalIgnoreCase) -or
           $full.StartsWith($parentFull + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Write-AtomicJson([string]$Path, $Obj) {
    $tmp = $Path + '.tmp'
    $json = $Obj | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($tmp, $json, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Test-GameRunning {
    $found = @(Get-Process | Where-Object { $_.ProcessName -eq 'Melvor2' })
    return $found.Count -gt 0
}

function Enter-WorkspaceLock {
    $folder = Join-Path $W 'backups'
    if (-not (Test-Path -LiteralPath $folder)) { New-Item -ItemType Directory -Path $folder | Out-Null }
    $lockPath = Join-Path $folder 'patch.lock'
    $fs = [System.IO.File]::Open($lockPath, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
    if ($fs.Length -eq 0) { $fs.WriteByte(0); $fs.Flush() }
    return $fs
}

function Invoke-PatchAction {
    param([string]$ActionName, [string]$GameDirArg, [string]$ManifestArg, [bool]$CheckProc)

    $game = if ($GameDirArg) { [System.IO.Path]::GetFullPath($GameDirArg) } else { [System.IO.Path]::GetFullPath((Join-Path $W '..')) }
    $manifestPath = if ($ManifestArg) { [System.IO.Path]::GetFullPath($ManifestArg) } else { [System.IO.Path]::GetFullPath((Join-Path $W 'prototype\manifest.json')) }
    $workAllowed = Join-Path $W 'work'
    if ($game -ne [System.IO.Path]::GetFullPath((Join-Path $W '..')) -and -not (Test-ContainedPath $game $workAllowed)) {
        throw 'Only this installation or workspace test fixtures are allowed'
    }
    if (-not (Test-ContainedPath $manifestPath $W)) { throw 'Manifest must stay inside the workspace' }

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($game.ToLowerInvariant())
        $key = ([System.BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-','').ToLowerInvariant().Substring(0,16)
    } finally { $sha.Dispose() }

    $statePath = Join-Path $W ("backups\state-$key.json")
    $exe = Join-Path $game 'Melvor2.exe'

    if ($CheckProc -and (Test-GameRunning)) { throw 'Please exit Melvor2.exe before installing/restoring' }

    $lock = Enter-WorkspaceLock
    try {
        $state = $null
        if (Test-Path -LiteralPath $statePath) {
            $state = Get-Content -LiteralPath $statePath -Raw -Encoding UTF8 | ConvertFrom-Json
        }
        $current = Get-Sha256Hex -Path $exe

        if ($ActionName -eq 'restore') {
            if (-not $state) { return @{ result = 'NOT_INSTALLED'; modified_game_files = @() } }
            if ($state.game_dir -ne $game) { throw 'State target mismatch' }
            if ($current -eq $state.original_sha256) { return @{ result = 'ALREADY_RESTORED'; modified_game_files = @() } }
            $recognized = @($state.recognized_patched_hashes)
            if ($recognized -notcontains $current) { throw 'Game changed since installation; refusing to overwrite it' }
            $backup = [string]$state.backup
            if (-not (Test-ContainedPath $backup (Join-Path $W 'backups'))) { throw 'Original backup missing. Use Steam Verify Integrity of Game Files to restore official Melvor2.exe, then run the patch again if you need Chinese.' }
            if ((Get-Sha256Hex -Path $backup) -ne $state.original_sha256) { throw 'Original backup missing. Use Steam Verify Integrity of Game Files to restore official Melvor2.exe, then run the patch again if you need Chinese.' }
            $work = Join-Path $W 'work'
            if (-not (Test-Path -LiteralPath $work)) { New-Item -ItemType Directory -Path $work | Out-Null }
            $tmp = Join-Path $work ('restore-' + [guid]::NewGuid().ToString('N') + '.exe')
            try {
                Copy-Item -LiteralPath $backup -Destination $tmp -Force
                if ((Get-Sha256Hex -Path $tmp) -ne $state.original_sha256) { throw 'Restore preflight changed' }
                if ((Get-Sha256Hex -Path $exe) -ne $current) { throw 'Restore preflight changed' }
                Move-Item -LiteralPath $tmp -Destination $exe -Force
            } finally {
                if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
            }
            if ((Get-Sha256Hex -Path $exe) -ne $state.original_sha256) { throw 'Restored file verification failed' }
            $state.stage = 'restored'
            Write-AtomicJson $statePath $state
            return @{ result = 'RESTORED_ORIGINAL'; modified_game_files = @('Melvor2.exe'); sha256 = $state.original_sha256 }
        }

        $manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
        if ($manifest.buildid -notmatch '^\d+$' -or $manifest.appid -ne '3218350') { throw 'Invalid build/app identity' }
        $changed = @($manifest.changed_resource_paths)
        $allowedFixed = @('Locale/en_GB.po', 'Data/Packages/MelvorBase.json')
        if ($changed -notcontains 'Locale/en_GB.po') { throw 'Unexpected patch targets' }
        foreach ($c in $changed) {
            if ($allowedFixed -contains $c) { continue }
            if ($c -notmatch '^\.godot/exported/\d+/export-[0-9a-f]{32}-.+\.scn$') { throw 'Unexpected patch targets' }
        }

        $required = @{}
        foreach ($r in $manifest.required_game_files) { $required[$r.path] = $r }
        if (-not $required.ContainsKey('Melvor2.exe')) { throw 'Unexpected version-lock file set' }
        $dllKey = 'data_GamesByMalcs.Melvor2_windows_x86_64/GamesByMalcs.Melvor2.dll'
        if (-not $required.ContainsKey($dllKey)) { throw 'Unexpected version-lock file set' }
        if ($required.Keys.Count -ne 2) { throw 'Unexpected version-lock file set' }
        $original = [string]$required['Melvor2.exe'].sha256
        if ($original -notmatch '^[0-9a-f]{64}$') { throw 'Unexpected version-lock file set' }

        $knownPatched = @()
        if ($manifest.PSObject.Properties.Name -contains 'known_patched_sha256' -and $null -ne $manifest.known_patched_sha256) {
            $knownPatched = @($manifest.known_patched_sha256 | ForEach-Object { [string]$_ })
        }
        if ($manifest.PSObject.Properties.Name -contains 'patched_sha256' -and $manifest.patched_sha256) {
            $kp = [string]$manifest.patched_sha256
            if ($knownPatched -notcontains $kp) { $knownPatched += $kp }
        }

        $already = $false
        if ($state -and (@($state.recognized_patched_hashes) -contains $current)) {
            if ($state.original_sha256 -ne $original) { throw 'Patch is for a different original game build' }
            $already = ($state.stage -eq 'installed' -and $state.payload_sha256 -eq $manifest.resource_sha256.'Locale/en_GB.po' -and $current -eq $state.patched_sha256)
        } elseif ($knownPatched -contains $current) {
            # EXE already matches this pack's known patched hash (e.g. backups/state deleted)
            $already = $false
        } elseif ($current -ne $original) {
            throw 'Unsupported executable version or unknown modification'
        }

        foreach ($rel in $required.Keys) {
            if ($rel -eq 'Melvor2.exe') { continue }
            $target = Join-Path $game ($rel -replace '/','\')
            if (-not (Test-ContainedPath $target $game)) { throw ("Dependency/build mismatch: " + $rel) }
            if ((Get-Sha256Hex -Path $target) -ne $required[$rel].sha256) { throw ("Dependency/build mismatch: " + $rel) }
        }

        $payloadPath = Join-Path (Split-Path -Parent $manifestPath) 'Locale\en_GB.po'
        $payload = [System.IO.File]::ReadAllBytes($payloadPath)
        $shaTmp = [System.Security.Cryptography.SHA256]::Create()
        try { $payloadHash = ([System.BitConverter]::ToString($shaTmp.ComputeHash($payload)) -replace '-','').ToLowerInvariant() } finally { $shaTmp.Dispose() }
        if ($payloadHash -ne $manifest.resource_sha256.'Locale/en_GB.po') { throw 'Translation payload checksum mismatch' }

        $extraResources = @{}
        $jsonHash = $null
        $extrasHash = $null
        $protoRoot = Split-Path -Parent $manifestPath
        $extraHashParts = New-Object System.Collections.Generic.List[string]
        foreach ($c in $changed) {
            if ($c -eq 'Locale/en_GB.po') { continue }
            $filePath = Join-Path $protoRoot ($c -replace '/','\')
            if (-not (Test-ContainedPath $filePath $protoRoot)) { throw 'Translation payload path escaped workspace' }
            $fileBytes = [System.IO.File]::ReadAllBytes($filePath)
            $shaTmp = [System.Security.Cryptography.SHA256]::Create()
            try { $fileHash = ([System.BitConverter]::ToString($shaTmp.ComputeHash($fileBytes)) -replace '-','').ToLowerInvariant() } finally { $shaTmp.Dispose() }
            $expectedHash = $null
            $hashProp = $manifest.resource_sha256.PSObject.Properties[$c]
            if ($hashProp) { $expectedHash = [string]$hashProp.Value }
            if ($fileHash -ne $expectedHash) { throw 'Translation payload checksum mismatch' }
            $extraResources[$c] = $fileBytes
            if ($c -eq 'Data/Packages/MelvorBase.json') { $jsonHash = $fileHash }
            [void]$extraHashParts.Add($c + ':' + $fileHash)
        }
        if ($extraHashParts.Count -gt 0) {
            $joined = ((@($extraHashParts) | Sort-Object) -join '|')
            $shaTmp = [System.Security.Cryptography.SHA256]::Create()
            try { $extrasHash = ([System.BitConverter]::ToString($shaTmp.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($joined))) -replace '-','').ToLowerInvariant() } finally { $shaTmp.Dispose() }
        }
        if ($already -and $jsonHash) {
            $stateJson = $null
            if ($state -and $state.PSObject.Properties.Name -contains 'payload_json_sha256') { $stateJson = [string]$state.payload_json_sha256 }
            if ($stateJson -ne $jsonHash) { $already = $false }
        }
        if ($already -and $extrasHash) {
            $stateExtras = $null
            if ($state -and $state.PSObject.Properties.Name -contains 'payload_extras_sha256') { $stateExtras = [string]$state.payload_extras_sha256 }
            if ($stateExtras -ne $extrasHash) { $already = $false }
        }

        if (($knownPatched -contains $current) -and ($current -ne $original)) {
            $expectedPatched = if ($manifest.PSObject.Properties.Name -contains 'patched_sha256' -and $manifest.patched_sha256) { [string]$manifest.patched_sha256 } else { $current }
            $backupDir = Join-Path $W ('backups\' + $manifest.buildid + '-' + $original.Substring(0,16))
            $backup = Join-Path $backupDir 'Melvor2.exe.original'
            $recognized = New-Object System.Collections.Generic.List[string]
            if ($state) { foreach ($h in @($state.recognized_patched_hashes)) { if ($h) { [void]$recognized.Add([string]$h) } } }
            foreach ($h in $knownPatched) { if ($recognized -notcontains $h) { [void]$recognized.Add($h) } }
            if ($recognized -notcontains $current) { [void]$recognized.Add($current) }
            $alreadyThisPayload = ($state -and ([string]$state.payload_sha256 -eq $payloadHash) -and ([string]$state.patched_sha256 -eq $current))
            if ($alreadyThisPayload -and $jsonHash) {
                $stateJson = $null
                if ($state.PSObject.Properties.Name -contains 'payload_json_sha256') { $stateJson = [string]$state.payload_json_sha256 }
                if ($stateJson -ne $jsonHash) { $alreadyThisPayload = $false }
            }
            if ($alreadyThisPayload -and $extrasHash) {
                $stateExtras = $null
                if ($state.PSObject.Properties.Name -contains 'payload_extras_sha256') { $stateExtras = [string]$state.payload_extras_sha256 }
                if ($stateExtras -ne $extrasHash) { $alreadyThisPayload = $false }
            }
            $newState = [ordered]@{
                game_dir = $game
                buildid = [string]$manifest.buildid
                backup = $backup
                original_sha256 = $original
                patched_sha256 = $current
                recognized_patched_hashes = @($recognized | Sort-Object)
                payload_sha256 = $payloadHash
                payload_json_sha256 = $jsonHash
                payload_extras_sha256 = $extrasHash
                stage = 'installed'
                proof = $null
                note = 'State recreated from known_patched_sha256; original backup may be absent'
            }
            if (-not (Test-Path -LiteralPath $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
            Write-AtomicJson $statePath $newState
            $state = $newState
            $already = $alreadyThisPayload
        }

        if ($ActionName -eq 'check') {
            return @{
                result = 'PREFLIGHT_OK'
                installed = ($current -ne $original)
                modified_game_files = @()
                runtime_ui_verified = $false
            }
        }

        if ($already) { return @{ result = 'ALREADY_INSTALLED'; modified_game_files = @() } }

        $backupDir = Join-Path $W ('backups\' + $manifest.buildid + '-' + $original.Substring(0,16))
        $backup = Join-Path $backupDir 'Melvor2.exe.original'
        if (-not (Test-Path -LiteralPath $backupDir)) { New-Item -ItemType Directory -Path $backupDir | Out-Null }
        if (Test-Path -LiteralPath $backup) {
            if ((Get-Sha256Hex -Path $backup) -ne $original) { throw 'Existing original backup is corrupted; will not overwrite it' }
        } else {
            if ($current -ne $original) { throw 'Original backup unavailable and Melvor2.exe is not the official build. If Chinese is already applied, use install/check only. To restore English: Steam Verify Integrity of Game Files.' }
            Copy-Item -LiteralPath $exe -Destination $backup
            if ((Get-Sha256Hex -Path $backup) -ne $original) { throw 'Backup verification failed' }
        }

        $work = Join-Path $W 'work'
        if (-not (Test-Path -LiteralPath $work)) { New-Item -ItemType Directory -Path $work | Out-Null }
        $tmp = Join-Path $work ('patch-' + [guid]::NewGuid().ToString('N') + '.exe')
        try {
            Write-Host '  [1/3] 正在生成补丁（最耗时，约 2 分钟）...' -ForegroundColor Yellow
            $proof = Build-PckPatch -Original $backup -Output $tmp -Payload $payload -ExtraResources $extraResources
            Write-Host '  [2/3] 补丁已生成，正在校验并替换 Melvor2.exe...' -ForegroundColor Yellow
            $patched = Get-Sha256Hex -Path $tmp
            $recognized = New-Object System.Collections.Generic.List[string]
            if ($state -and $state.original_sha256 -eq $original) {
                foreach ($h in @($state.recognized_patched_hashes)) { if ($h) { [void]$recognized.Add([string]$h) } }
            }
            if ($recognized -notcontains $patched) { [void]$recognized.Add($patched) }
            $newState = [ordered]@{
                game_dir = $game
                buildid = [string]$manifest.buildid
                backup = $backup
                original_sha256 = $original
                patched_sha256 = $patched
                recognized_patched_hashes = @($recognized | Sort-Object)
                payload_sha256 = $payloadHash
                payload_json_sha256 = $jsonHash
                payload_extras_sha256 = $extrasHash
                stage = 'prepared'
                proof = $proof
            }
            Write-AtomicJson $statePath $newState
            if ((Get-Sha256Hex -Path $exe) -ne $current) { throw 'Game changed while preparing the patch' }
            Move-Item -LiteralPath $tmp -Destination $exe -Force
            if ((Get-Sha256Hex -Path $exe) -ne $patched) { throw 'Installed file verification failed; original backup retained' }
            $newState.stage = 'installed'
            Write-AtomicJson $statePath $newState
            Write-Host '  [3/3] 文件操作完成。' -ForegroundColor Yellow
        } finally {
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
        }
        return @{
            result = 'INSTALLED_STATICALLY_VERIFIED'
            modified_game_files = @('Melvor2.exe')
            backup = $backup
            proof = $proof
            runtime_ui_verified = $false
        }
    } finally {
        $lock.Dispose()
    }
}

$effective = if ($Action -eq 'update') { 'install' } else { $Action }
$result = Invoke-PatchAction -ActionName $effective -GameDirArg $GameDir -ManifestArg $Manifest -CheckProc $CheckProcess
($result | ConvertTo-Json -Depth 10 -Compress)
Write-Host 'Done. The game was not started. Review docs/patch_installation.md for verification limits.'

