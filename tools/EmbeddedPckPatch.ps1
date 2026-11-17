# PE/PCK Locale/en_GB.po patch helpers. No Python required.

Set-StrictMode -Version Latest

$ErrorActionPreference = 'Stop'

$script:PckMagic = [uint32]0x43504447



function Get-Sha256Hex {

    param([Parameter(Mandatory)][string]$Path)

    $sha = [System.Security.Cryptography.SHA256]::Create()

    try {

        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)

        try {

            $hash = $sha.ComputeHash($fs)

            return ([System.BitConverter]::ToString($hash) -replace '-','').ToLowerInvariant()

        } finally { $fs.Dispose() }

    } finally { $sha.Dispose() }

}



function Get-Md5Bytes {

    param([Parameter(Mandatory)][byte[]]$Data)

    $md5 = [System.Security.Cryptography.MD5]::Create()

    try { return ,$md5.ComputeHash($Data) } finally { $md5.Dispose() }

}



function Read-UInt16LE([byte[]]$Buf, [int]$Offset) {

    return [uint16]([int]$Buf[$Offset] + ([int]$Buf[$Offset+1] * 256))

}

function Read-UInt32LE([byte[]]$Buf, [int]$Offset) {

    return [uint32]([uint64]$Buf[$Offset] + ([uint64]$Buf[$Offset+1] * 256) + ([uint64]$Buf[$Offset+2] * 65536) + ([uint64]$Buf[$Offset+3] * 16777216))

}

function Read-UInt64LE([byte[]]$Buf, [int]$Offset) {

    $lo = [uint64](Read-UInt32LE $Buf $Offset)

    $hi = [uint64](Read-UInt32LE $Buf ($Offset+4))

    return [uint64]($lo -bor ($hi -shl 32))

}



function Read-StreamExact {

    param($Stream, [int]$Count, [int64]$LimitPos)

    if ($Count -lt 0 -or ($Stream.Position + $Count) -gt $LimitPos) { throw 'Truncated pack directory' }

    $b = New-Object byte[] $Count

    $got = 0

    while ($got -lt $Count) {

        $r = $Stream.Read($b, $got, $Count - $got)

        if ($r -le 0) { throw 'Short read' }

        $got += $r

    }

    return ,$b

}



function Get-PckLayout {

    param(

        [Parameter(Mandatory)][string]$Path,

        [switch]$VerifyResources

    )

    $fileInfo = Get-Item -LiteralPath $Path

    $size = [int64]$fileInfo.Length

    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)

    try {

        $head = New-Object byte[] 4096

        $n = $fs.Read($head, 0, 4096)

        if ($n -lt 64) { throw 'Not a PE executable' }

        if ($head[0] -ne 0x4D -or $head[1] -ne 0x5A) { throw 'Not a PE executable' }

        $pe = [int](Read-UInt32LE $head 60)

        if (($pe + 24) -gt $head.Length) { throw 'Invalid PE signature' }

        if ($head[$pe] -ne 0x50 -or $head[$pe+1] -ne 0x45 -or $head[$pe+2] -ne 0 -or $head[$pe+3] -ne 0) { throw 'Invalid PE signature' }

        if ((Read-UInt16LE $head ($pe+4)) -ne 0x8664) { throw 'Expected x64' }

        $opt = $pe + 24

        if ((Read-UInt16LE $head $opt) -ne 0x20b) { throw 'Expected PE32+' }

        $sectionCount = [int](Read-UInt16LE $head ($pe+6))

        $optSize = [int](Read-UInt16LE $head ($pe+20))

        $secStart = $opt + $optSize

        $sections = New-Object System.Collections.Generic.List[object]

        for ($i = 0; $i -lt $sectionCount; $i++) {

            $pos = $secStart + 40 * $i

            if (($pos + 40) -gt $head.Length) { throw 'Section table outside supported header' }

            $nameEnd = 8

            for ($k = 0; $k -lt 8; $k++) { if ($head[$pos + $k] -eq 0) { $nameEnd = $k; break } }

            $name = [System.Text.Encoding]::ASCII.GetString($head, $pos, $nameEnd)

            $sections.Add([pscustomobject]@{

                Name = $name

                Virtual = [uint32](Read-UInt32LE $head ($pos+8))

                Rva = [uint32](Read-UInt32LE $head ($pos+12))

                Size = [uint32](Read-UInt32LE $head ($pos+16))

                Start = [uint32](Read-UInt32LE $head ($pos+20))

                Pos = $pos

            })

        }

        $pcks = @($sections | Where-Object { $_.Name -eq 'pck' })

        if ($pcks.Count -ne 1) { throw 'Expected one embedded PCK section' }

        $s = $pcks[0]

        $base = [int64]$s.Start

        $end = $base + [int64]$s.Size

        $security = $opt + 112 + 4*8

        $certStart = [int64](Read-UInt32LE $head $security)

        $certSize = [int64](Read-UInt32LE $head ($security+4))

        if ($end -gt $size -or $certStart -ne $end -or (($certStart + $certSize) -ne $size) -or (($certStart % 8) -ne 0)) {

            throw 'Unsupported certificate/trailing-data layout'

        }

        foreach ($x in $sections) {

            if ($x.Pos -ne $s.Pos -and $x.Size -ne 0 -and $x.Start -ge $base) {

                throw 'PCK must be final raw section'

            }

        }

        $null = $fs.Seek($base, [System.IO.SeekOrigin]::Begin)

        $header = New-Object byte[] 112

        if ($fs.Read($header, 0, 112) -ne 112) { throw 'Truncated PCK' }

        $magic = Read-UInt32LE $header 0

        $v1 = Read-UInt32LE $header 4

        $v2 = Read-UInt32LE $header 8

        $v3 = Read-UInt32LE $header 12

        $v4 = Read-UInt32LE $header 16

        $v5 = Read-UInt32LE $header 20

        $dataRel = Read-UInt64LE $header 24

        $dirRel = Read-UInt64LE $header 32

        if ($magic -ne $script:PckMagic -or $v1 -ne 4 -or $v2 -ne 4 -or $v3 -ne 7 -or $v4 -ne 2 -or $v5 -ne 2 -or $dataRel -ne 112) {

            throw 'Unsupported PCK version/flags'

        }

        $data = $base + [int64]$dataRel

        $directory = $base + [int64]$dirRel

        if (-not ($data -le $directory -and $directory -lt ($end - 12))) { throw 'Invalid directory offset' }

        $null = $fs.Seek($directory, [System.IO.SeekOrigin]::Begin)

        $limitPos = $end - 12

        $countBuf = Read-StreamExact -Stream $fs -Count 4 -LimitPos $limitPos

        $count = [int](Read-UInt32LE $countBuf 0)

        if ($count -gt 100000) { throw 'Oversized pack directory' }

        $entries = New-Object System.Collections.Generic.List[object]

        $seen = New-Object 'System.Collections.Generic.HashSet[string]'

        for ($i = 0; $i -lt $count; $i++) {

            $lenBuf = Read-StreamExact -Stream $fs -Count 4 -LimitPos $limitPos

            $length = [int](Read-UInt32LE $lenBuf 0)

            if ($length -le 0 -or $length -ge 16384) { throw 'Invalid resource path length' }

            $name = Read-StreamExact -Stream $fs -Count $length -LimitPos $limitPos

            $nameText = [System.Text.Encoding]::UTF8.GetString($name).TrimEnd([char]0)

            $meta = Read-StreamExact -Stream $fs -Count 16 -LimitPos $limitPos

            $offset = [int64](Read-UInt64LE $meta 0)

            $lengthData = [int64](Read-UInt64LE $meta 8)

            $digest = Read-StreamExact -Stream $fs -Count 16 -LimitPos $limitPos

            $flagsBuf = Read-StreamExact -Stream $fs -Count 4 -LimitPos $limitPos

            $flags = Read-UInt32LE $flagsBuf 0

            if ($seen.Contains($nameText) -or $flags -ne 0 -or (($data + $offset + $lengthData) -gt $directory)) {

                throw 'Invalid resource metadata'

            }

            [void]$seen.Add($nameText)

            $entries.Add([pscustomobject]@{

                Path = $nameText

                Name = $name

                Offset = $offset

                Size = $lengthData

                Md5 = $digest

                Flags = $flags

            })

        }

        $directoryEnd = $fs.Position

        $padLen = [int]($limitPos - $directoryEnd)

        if ($padLen -gt 0) {

            $padding = Read-StreamExact -Stream $fs -Count $padLen -LimitPos $limitPos

            $nonzero = $false

            foreach ($pb in $padding) { if ($pb -ne 0) { $nonzero = $true; break } }

            if ($padding.Length -ge 16 -or $nonzero) { throw 'Unexpected directory padding' }

        }

        $footerBuf = Read-StreamExact -Stream $fs -Count 12 -LimitPos $end

        $footer = Read-UInt64LE $footerBuf 0

        $footerMagic = Read-UInt32LE $footerBuf 8

        if ($footerMagic -ne $script:PckMagic -or $footer -ne ([uint64]($s.Size - 12))) { throw 'Invalid embedded footer' }

        if ($VerifyResources) {

            $md5 = [System.Security.Cryptography.MD5]::Create()

            try {

                foreach ($e in $entries) {

                    $null = $fs.Seek($data + $e.Offset, [System.IO.SeekOrigin]::Begin)

                    $md5.Initialize()

                    $remaining = [int64]$e.Size

                    $buf = New-Object byte[] (8MB)

                    while ($remaining -gt 0) {

                        $toRead = [int]([Math]::Min($remaining, $buf.Length))

                        $r = $fs.Read($buf, 0, $toRead)

                        if ($r -le 0) { throw 'Truncated resource' }

                        $null = $md5.TransformBlock($buf, 0, $r, $buf, 0)

                        $remaining -= $r

                    }

                    $null = $md5.TransformFinalBlock([byte[]]@(), 0, 0)

                    $digest2 = $md5.Hash

                    for ($k = 0; $k -lt 16; $k++) {

                        if ($digest2[$k] -ne $e.Md5[$k]) { throw ('Resource checksum mismatch: ' + $e.Path) }

                    }

                }

            } finally { $md5.Dispose() }

        }

        return [pscustomobject]@{

            Base = $base

            Data = $data

            Directory = $directory

            DirectoryEnd = $directoryEnd

            End = $end

            Entries = $entries

            Section = $s

            Security = $security

            CertSize = $certSize

            Checksum = ($opt + 64)

            Header = $head

            FileSize = $size

        }

    } finally { $fs.Dispose() }

}



function Copy-BytesStream {

    param($Source, $Target, [int64]$Count)

    $buf = New-Object byte[] (8MB)

    $left = $Count

    while ($left -gt 0) {

        $n = [int]([Math]::Min($left, $buf.Length))

        $r = $Source.Read($buf, 0, $n)

        if ($r -le 0) { throw 'Unexpected source EOF' }

        $Target.Write($buf, 0, $r)

        $left -= $r

    }

}



function Get-MaskedPrefixHash {
    param([string]$Path, [int64]$Length, $Excluded)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try {
        $pos = [int64]0
        $items = New-Object System.Collections.Generic.List[object]
        foreach ($ex in @($Excluded)) {
            if ($null -eq $ex) { continue }
            [void]$items.Add([pscustomobject]@{ Start = [int64]$ex.Start; Size = [int64]$ex.Size })
        }
        [void]$items.Add([pscustomobject]@{ Start = [int64]$Length; Size = [int64]0 })
        $ordered = $items | Sort-Object { [int64]$_.Start }
        $buf = New-Object byte[] (8MB)
        foreach ($pair in $ordered) {
            $start = [int64]$pair.Start
            $sz = [int64]$pair.Size
            if ($start -lt $pos -or (($start + $sz) -gt $Length)) { throw 'Invalid comparison exclusions' }
            $remaining = $start - $pos
            while ($remaining -gt 0) {
                $n = [int]([Math]::Min($remaining, $buf.Length))
                $r = $fs.Read($buf, 0, $n)
                if ($r -le 0) { throw 'Truncated prefix' }
                $null = $sha.TransformBlock($buf, 0, $r, $buf, 0)
                $remaining -= $r
            }
            if ($sz -gt 0) { $null = $fs.Seek($sz, [System.IO.SeekOrigin]::Current) }
            $pos = $start + $sz
        }
        $null = $sha.TransformFinalBlock([byte[]]@(), 0, 0)
        return ([System.BitConverter]::ToString($sha.Hash) -replace '-','').ToLowerInvariant()
    } finally { $fs.Dispose(); $sha.Dispose() }
}

function Test-PckPatch {

    param([string]$Original, [string]$Patched, [byte[]]$Payload, [hashtable]$ExtraResources)

    $a = Get-PckLayout -Path $Original

    $b = Get-PckLayout -Path $Patched -VerifyResources

    if ($a.Entries.Count -ne $b.Entries.Count) { throw 'Resource paths changed' }

    for ($i = 0; $i -lt $a.Entries.Count; $i++) {

        if ($a.Entries[$i].Path -ne $b.Entries[$i].Path) { throw 'Resource paths changed' }

    }

    $changed = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $a.Entries.Count; $i++) {

        $x = $a.Entries[$i]; $y = $b.Entries[$i]

        $same = ($x.Offset -eq $y.Offset -and $x.Size -eq $y.Size -and $x.Flags -eq $y.Flags)

        if ($same) {

            for ($k = 0; $k -lt 16; $k++) { if ($x.Md5[$k] -ne $y.Md5[$k]) { $same = $false; break } }

        }

        if (-not $same) { [void]$changed.Add($x.Path) }

    }

    $expected = New-Object System.Collections.Generic.List[string]
    [void]$expected.Add('Locale/en_GB.po')
    if ($ExtraResources) {
        foreach ($k in @($ExtraResources.Keys)) {
            if ($expected -notcontains $k) { [void]$expected.Add([string]$k) }
        }
    }
    $expectedSorted = @($expected | Sort-Object)
    $changedSorted = @($changed | Sort-Object)
    if ($expectedSorted.Count -ne $changedSorted.Count) {
        throw ('Unexpected resource modifications: ' + ($changed -join ','))
    }
    for ($i = 0; $i -lt $expectedSorted.Count; $i++) {
        if ($expectedSorted[$i] -ne $changedSorted[$i]) {
            throw ('Unexpected resource modifications: ' + ($changed -join ','))
        }
    }

    $payloads = @{}
    $payloads['Locale/en_GB.po'] = $Payload
    if ($ExtraResources) {
        foreach ($k in @($ExtraResources.Keys)) { $payloads[[string]$k] = $ExtraResources[$k] }
    }

    $fs = [System.IO.File]::Open($Patched, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)
    try {
        foreach ($path in @($payloads.Keys)) {
            $target = $null
            foreach ($e in $b.Entries) { if ($e.Path -eq $path) { $target = $e; break } }
            if ($null -eq $target) { throw ('Missing patched resource: ' + $path) }
            $want = $payloads[$path]
            $null = $fs.Seek($b.Data + $target.Offset, [System.IO.SeekOrigin]::Begin)
            $got = New-Object byte[] ([int]$target.Size)
            $read = 0
            while ($read -lt $got.Length) {
                $r = $fs.Read($got, $read, $got.Length - $read)
                if ($r -le 0) { throw ('Payload differs: ' + $path) }
                $read += $r
            }
            if ($got.Length -ne $want.Length) { throw ('Payload differs: ' + $path) }
            for ($i = 0; $i -lt $got.Length; $i++) { if ($got[$i] -ne $want[$i]) { throw ('Payload differs: ' + $path) } }
        }
    } finally { $fs.Dispose() }

    $excluded = @(
        [pscustomobject]@{ Start = [int64]($a.Section.Pos + 16); Size = [int64]4 },
        [pscustomobject]@{ Start = [int64]$a.Security; Size = [int64]4 },
        [pscustomobject]@{ Start = [int64]$a.Checksum; Size = [int64]4 },
        [pscustomobject]@{ Start = [int64]($a.Base + 32); Size = [int64]8 }
    )

    if ((Get-MaskedPrefixHash -Path $Original -Length $a.Directory -Excluded $excluded) -ne

        (Get-MaskedPrefixHash -Path $Patched -Length $a.Directory -Excluded $excluded)) {

        throw 'Non-target prefix changed'

    }

    $fs1 = [System.IO.File]::Open($Original, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)

    $fs2 = [System.IO.File]::Open($Patched, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)

    try {

        $null = $fs1.Seek($a.End, [System.IO.SeekOrigin]::Begin)

        $null = $fs2.Seek($b.End, [System.IO.SeekOrigin]::Begin)

        $left = [int64]$a.CertSize

        $buf1 = New-Object byte[] (1MB)

        $buf2 = New-Object byte[] (1MB)

        while ($left -gt 0) {

            $n = [int]([Math]::Min($left, $buf1.Length))

            $r1 = $fs1.Read($buf1, 0, $n)

            $r2 = $fs2.Read($buf2, 0, $n)

            if ($r1 -ne $r2 -or $r1 -le 0) { throw 'Certificate bytes changed' }

            for ($i = 0; $i -lt $r1; $i++) { if ($buf1[$i] -ne $buf2[$i]) { throw 'Certificate bytes changed' } }

            $left -= $r1

        }

    } finally { $fs1.Dispose(); $fs2.Dispose() }

    return [pscustomobject]@{

        changed_resources = @($expectedSorted)

        verified_resources = $b.Entries.Count

        non_target_data_identical = $true

        certificate_bytes_preserved = $true

        authenticode_signature_valid_after_modification = $false

        runtime_ui_verified = $false

    }

}



function Write-UInt32LEAt([System.IO.Stream]$Stream, [int64]$Pos, [uint32]$Value) {

    $null = $Stream.Seek($Pos, [System.IO.SeekOrigin]::Begin)

    $b = [BitConverter]::GetBytes([uint32]$Value)

    if (-not [BitConverter]::IsLittleEndian) { [Array]::Reverse($b) }

    $Stream.Write($b, 0, 4)

}

function Write-UInt64LEAt([System.IO.Stream]$Stream, [int64]$Pos, [uint64]$Value) {

    $null = $Stream.Seek($Pos, [System.IO.SeekOrigin]::Begin)

    $b = [BitConverter]::GetBytes([uint64]$Value)

    if (-not [BitConverter]::IsLittleEndian) { [Array]::Reverse($b) }

    $Stream.Write($b, 0, 8)

}



function Update-PeChecksum {

    param([string]$Path)

    if (-not ('NativeMethodsPE' -as [type])) {

        Add-Type -TypeDefinition @"

using System;

using System.Runtime.InteropServices;

public static class NativeMethodsPE {

  [DllImport("imagehlp.dll", CharSet=CharSet.Unicode, SetLastError=true)]

  public static extern uint MapFileAndCheckSumW(string Filename, out uint HeaderSum, out uint CheckSum);

}

"@

    }

    $old = [uint32]0; $new = [uint32]0

    $rc = [NativeMethodsPE]::MapFileAndCheckSumW($Path, [ref]$old, [ref]$new)

    if ($rc -ne 0) { throw 'Windows PE checksum API failed' }

    return $new

}



function Build-PckPatch {

    param(

        [Parameter(Mandatory)][string]$Original,

        [Parameter(Mandatory)][string]$Output,

        [Parameter(Mandatory)][byte[]]$Payload,

        [hashtable]$ExtraResources

    )

    $origPath = [System.IO.Path]::GetFullPath($Original)

    $outPath = [System.IO.Path]::GetFullPath($Output)

    if ($origPath -eq $outPath) { throw 'Must build a separate file' }

    $a = Get-PckLayout -Path $Original

    $hasPo = $false

    foreach ($e in $a.Entries) { if ($e.Path -eq 'Locale/en_GB.po') { $hasPo = $true; break } }

    if (-not $hasPo) { throw 'Missing English PO' }

    $outDir = [System.IO.Path]::GetDirectoryName($outPath)

    if ($outDir -and -not (Test-Path -LiteralPath $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

    if (Test-Path -LiteralPath $outPath) { throw 'Output already exists' }



    Write-Host '    - copying embedded resources...' -ForegroundColor DarkYellow
    $src = [System.IO.File]::Open($Original, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::Read)

    $dst = [System.IO.File]::Open($Output, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)

    try {

        Copy-BytesStream -Source $src -Target $dst -Count $a.Directory

        $replacements = @{}
        $replacements['Locale/en_GB.po'] = $Payload
        if ($ExtraResources) {
            foreach ($k in @($ExtraResources.Keys)) { $replacements[[string]$k] = $ExtraResources[$k] }
        }
        foreach ($path in @($replacements.Keys)) {
            $found = $false
            foreach ($e0 in $a.Entries) { if ($e0.Path -eq $path) { $found = $true; break } }
            if (-not $found) { throw ('Missing original resource: ' + $path) }
        }

        $newMeta = @{}
        foreach ($path in @($replacements.Keys)) {
            $bytes = $replacements[$path]
            $offset = $dst.Position - $a.Data
            $dst.Write($bytes, 0, $bytes.Length)
            $pad = [int]((16 - (($dst.Position - $a.Base) % 16)) % 16)
            if ($pad -gt 0) { $dst.Write((New-Object byte[] $pad), 0, $pad) }
            $newMeta[$path] = @{
                Offset = [uint64]$offset
                Size = [uint64]$bytes.Length
                Md5 = Get-Md5Bytes -Data $bytes
            }
        }

        $directory = $dst.Position

        $countBytes = [BitConverter]::GetBytes([uint32]$a.Entries.Count)

        if (-not [BitConverter]::IsLittleEndian) { [Array]::Reverse($countBytes) }

        $dst.Write($countBytes, 0, 4)

        foreach ($e in $a.Entries) {

            $name = $e.Name

            $lenBytes = [BitConverter]::GetBytes([uint32]$name.Length)

            if (-not [BitConverter]::IsLittleEndian) { [Array]::Reverse($lenBytes) }

            $dst.Write($lenBytes, 0, 4)

            $dst.Write($name, 0, $name.Length)

            if ($newMeta.ContainsKey($e.Path)) {

                $meta = $newMeta[$e.Path]

                $offB = [BitConverter]::GetBytes([uint64]$meta.Offset)

                $szB = [BitConverter]::GetBytes([uint64]$meta.Size)

                if (-not [BitConverter]::IsLittleEndian) { [Array]::Reverse($offB); [Array]::Reverse($szB) }

                $dst.Write($offB, 0, 8); $dst.Write($szB, 0, 8)

                $dst.Write($meta.Md5, 0, 16)

                $zero = [BitConverter]::GetBytes([uint32]0)

                $dst.Write($zero, 0, 4)

            } else {

                $offB = [BitConverter]::GetBytes([uint64]$e.Offset)

                $szB = [BitConverter]::GetBytes([uint64]$e.Size)

                if (-not [BitConverter]::IsLittleEndian) { [Array]::Reverse($offB); [Array]::Reverse($szB) }

                $dst.Write($offB, 0, 8); $dst.Write($szB, 0, 8)

                $dst.Write($e.Md5, 0, 16)

                $fl = [BitConverter]::GetBytes([uint32]$e.Flags)

                if (-not [BitConverter]::IsLittleEndian) { [Array]::Reverse($fl) }

                $dst.Write($fl, 0, 4)

            }

        }

        $pad2 = [int]((16 - ((($dst.Position - $a.Base) + 12) % 16)) % 16)

        if ($pad2 -gt 0) { $dst.Write((New-Object byte[] $pad2), 0, $pad2) }

        $end = $dst.Position + 12

        $packSize = $end - $a.Base

        if ($packSize -ge [uint64]4294967296 -or $end -ge [uint64]4294967296) { throw 'PE raw-file offsets exceed uint32' }

        $footOff = [BitConverter]::GetBytes([uint64]($packSize - 12))

        $footMag = [BitConverter]::GetBytes([uint32]$script:PckMagic)

        if (-not [BitConverter]::IsLittleEndian) { [Array]::Reverse($footOff); [Array]::Reverse($footMag) }

        $dst.Write($footOff, 0, 8); $dst.Write($footMag, 0, 4)

        $null = $src.Seek($a.End, [System.IO.SeekOrigin]::Begin)

        Copy-BytesStream -Source $src -Target $dst -Count $a.CertSize

        Write-UInt64LEAt $dst ($a.Base + 32) ([uint64]($directory - $a.Base))

        Write-UInt32LEAt $dst ($a.Section.Pos + 16) ([uint32]$packSize)

        Write-UInt32LEAt $dst $a.Security ([uint32]$end)

        $dst.Flush()

    } finally { $dst.Dispose(); $src.Dispose() }



    $oldChecksum = Read-UInt32LE $a.Header $a.Checksum

    if ($oldChecksum -ne 0) {

        $full = (Resolve-Path -LiteralPath $Output).Path

        Write-Host '    - updating PE checksum...' -ForegroundColor DarkYellow
    $newSum = Update-PeChecksum -Path $full

        $fs = [System.IO.File]::Open($Output, [System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)

        try { Write-UInt32LEAt $fs $a.Checksum ([uint32]$newSum) } finally { $fs.Dispose() }

    }

    Write-Host '    - verifying patch...' -ForegroundColor DarkYellow
    return Test-PckPatch -Original $Original -Patched $Output -Payload $Payload -ExtraResources $ExtraResources

}

