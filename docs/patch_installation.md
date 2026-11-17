# Melvor Idle 2 EA 补丁安装说明

- AppID: 3218350
- Build: 26724394（由 Demo 汉化迁移，官方目录已完整）
- 方法: 仅替换 Melvor2.exe 内嵌 PCK 的 `Locale/en_GB.po`（en_GB 通道）
- 工具: `tools/Patch-Game.ps1` / `Manage-Patch.ps1`（纯 PowerShell，无 Python）
- 入口: `一键汉化.cmd` / `取消汉化.cmd`（纯 ASCII，避免 cmd 代码页截断）
- 版本锁: `prototype/manifest.json` 校验 Melvor2.exe 与 GamesByMalcs.Melvor2.dll 的 size/sha256
- 不改 DLL 内容、不改存档、不自动启动游戏

## 合并策略（26724394）

1. 从当前官方 EXE 提取 PCK。官方 `Locale/en.po` 已不存在；工程设置只加载 `Locale/en_GB.po`（完整英文目录，11540 键 / 1934 复数）。`Locale/zh_CN.po` 为官方完整简体中文（10407 键），但未写入 `internationalization/locale/translations`，游戏不会自动使用。
2. 以官方 `en_GB.po` 的 msgid / msgid_plural / msgctxt（`PluralName`）为目录骨架，按 msgid 填入官方中文；Demo 旧译文用于补缺或覆盖「中英相同且 Demo 已有中文」的条目。
3. 补译官方中文缺的 3 条（`Select Language`、`Language`、`Waiting for Player Input...`），并为 8 条复数补全 `{Current}` / `{Max}` 占位符。所有复数均写入 `msgstr[0]` 与 `msgstr[1]`，以匹配 en_GB 的 `nplurals=2`。

## 安装后

`manifest.json` 的 `patched_sha256` / `known_patched_sha256` 会记录本 build 补丁后 EXE 哈希，便于在 backups/state 被删除后仍识别「已汉化」。

语言请保持 **en_GB**。本补丁尚未做游戏内字体、换行与界面溢出验收。

## 物品名称修复（2026-11-17）

物品 DisplayName 是带上下文 PluralName 的 PluralString。银行物品面板把 ItemName.Text 设为 DisplayName.Singular（未翻译原文），再靠 Godot AutoTranslate **无上下文** 查找。因此只有同时也存在无 msgctxt 条目的物品名会显示中文。本版为所有 PluralName 条目补了无上下文回退，并按 JSON 原文补全了 18 个因官方 PO typo/单复数不一致而缺失的物品名。
