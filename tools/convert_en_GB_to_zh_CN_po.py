#!/usr/bin/env python3
"""Rebuild mod/zh_CN.po from the current Simplified Chinese pack (prototype/Locale/en_GB.po).

The pack historically shipped Chinese msgstr values inside Locale/en_GB.po.
This script only rewrites the gettext header to Language: zh_CN and leaves
every msgid / msgstr body byte-identical.

Plural-Forms stays nplurals=2; plural=(n != 1) so 17 goal strings that have
distinct singular/plural Chinese forms keep both msgstr[0] and msgstr[1].
"""
from __future__ import annotations

import argparse
import hashlib
import re
from datetime import datetime, timezone, timedelta
from pathlib import Path

HKT = timezone(timedelta(hours=8))
DEFAULT_SRC = Path(__file__).resolve().parents[1] / 'prototype' / 'Locale' / 'en_GB.po'
DEFAULT_DST = Path(__file__).resolve().parents[1] / 'mod' / 'zh_CN.po'


def convert(src: Path, dst: Path) -> None:
    raw = src.read_bytes()
    if raw.startswith(b'\xef\xbb\xbf'):
        raise SystemExit(f'{src} has a UTF-8 BOM; expected none')
    if b'\r\n' in raw:
        raise SystemExit(f'{src} uses CRLF; expected LF')
    if not raw.endswith(b'\n'):
        raise SystemExit(f'{src} missing trailing newline')
    text = raw.decode('utf-8')
    m = re.search(r'^msgid ""\nmsgstr ""\n(?:".*\\n"\n)+', text, re.M)
    if not m:
        raise SystemExit('PO header entry not found')
    body = text[m.end():]
    src_sha = hashlib.sha256(raw).hexdigest()
    now = datetime.now(HKT).strftime('%Y-%m-%d %H:%M%z')
    # datetime %z is +0800; insert colon for consistency with existing packs
    now = now[:-2] + ':' + now[-2:] if len(now) >= 5 else now
    header = (
        'msgid ""\n'
        'msgstr ""\n'
        '"Project-Id-Version: Melvor2 zh_CN\\n"\n'
        '"MIME-Version: 1.0\\n"\n'
        '"Content-Type: text/plain; charset=UTF-8\\n"\n'
        '"Content-Transfer-Encoding: 8bit\\n"\n'
        '"Language: zh_CN\\n"\n'
        '"Plural-Forms: nplurals=2; plural=(n != 1);\\n"\n'
        '"X-Generator: Melvor2-zh-CN-overlay\\n"\n'
        f'"PO-Revision-Date: {now}\\n"\n'
        '"X-Source-Pack: Locale/en_GB.po of the Simplified Chinese pack\\n"\n'
        f'"X-Source-SHA256: {src_sha}\\n"\n'
    )
    pre = (
        '# Melvor Idle 2 Simplified Chinese (zh_CN) overlay translation.\n'
        '# Unofficial player-made pack. Not affiliated with Games By Malcs.\n'
        '# Game text copyright belongs to the original developers; not for commercial use.\n'
        '#\n'
        '# Generated from our existing Simplified Chinese pack (previously shipped\n'
        '# as Locale/en_GB.po). msgstr content is unchanged. Language is zh_CN so the\n'
        '# in-game menu can switch between 简体中文 and English.\n'
        '#\n'
        '# Plural-Forms is kept as nplurals=2; plural=(n != 1) on purpose: 17 goal / count\n'
        '# entries have distinct singular and plural Chinese strings (Current / Max).\n'
        '# nplurals=1 would drop the count forms. This is a deliberate difference from\n'
        '# official zh_CN and from the Traditional Chinese community pack.\n'
        '#\n'
    )
    out = pre + header + body
    if not out.endswith('\n'):
        out += '\n'
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(out.encode('utf-8'))
    print(f'wrote {dst} bytes={dst.stat().st_size} sha256={hashlib.sha256(dst.read_bytes()).hexdigest()}')
    print(f'source {src} sha256={src_sha}')
    print(f'msgid entries including header: {out.count("msgid ")}')


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument('--src', type=Path, default=DEFAULT_SRC)
    ap.add_argument('--dst', type=Path, default=DEFAULT_DST)
    args = ap.parse_args()
    convert(args.src, args.dst)


if __name__ == '__main__':
    main()
