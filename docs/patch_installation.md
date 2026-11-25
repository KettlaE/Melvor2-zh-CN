# Melvor Idle 2 EA 覆盖层安装说明

- AppID: 3218350
- Build: 26886380（v0.11.7-alpha，Windows）
- 当前方法: 把 `override.cfg`、`mod/zh_CN.po`、`mod/zh_CN_patch.gd` 直接解压到 `Melvor2.exe` 所在的游戏目录
- 卸载: 删除游戏目录里的 `override.cfg` 和 `mod` 文件夹
- 不改写 `Melvor2.exe` 的内嵌资源；若当前还是旧的 exe 改写版，请先用 Steam「验证游戏文件完整性」或官方备份还原官方 exe，再解压覆盖层
- 不改 DLL 内容、不改存档

旧的「改写 Melvor2.exe 内嵌 PCK」安装方式已经淘汰。历史说明与文件见 [`legacy-exe-patch/`](../legacy-exe-patch/)，技术对照见 [`overlay-report.md`](overlay-report.md)。

## 安装步骤

1. 完全退出游戏。
2. 若 `Melvor2.exe` 仍是旧的改写版汉化，先还原官方 exe（Steam「验证游戏文件完整性」，或拷回官方备份）。不要把覆盖层解压到改写版 exe 上。
3. 把发布包 `Melvor2_zh-CN_overlay_build26886380.zip` 里的 `override.cfg` 和 `mod` 文件夹解压到游戏目录，与 `Melvor2.exe` 同一层（不要多解压出一层子文件夹）。
4. 从 Steam 启动游戏，在设置 → 语言选择「简体中文」。若之前一直用旧汉化，语言选项可能仍停在 English，需要手动切一次。

## 覆盖层如何生效

1. Godot 会读取游戏目录里的 `override.cfg`，在官方 `Locale/en_GB.po` 之外额外载入 `res://mod/zh_CN.po`（语系 `zh_CN`），并 Autoload `mod/zh_CN_patch.gd`。
2. 玩家在游戏的语言设置里选择「简体中文」。选 English 时就是官方原文。
3. `zh_CN_patch.gd` 只在当前语言为简体中文时，把部分未走翻译系统的界面原文替换为中文（例如部分商店说明、闪避列表、时间单位）。

因此安装不必按 exe 哈希锁定版本。Steam 更新后覆盖层通常仍可用；新增或改动过的英文会暂时保持原文，等翻译包更新即可。

已知的官方 `Melvor2.exe`（build 26886380）SHA256：`4fbd4504809b2d2cf3c12ad962a632f4b1dd0934eebd2452f3766ebc313146d1`（602,186,032 字节）。旧改写版（SHA256 `bd660f06968b54bad4ae95d55fc3402df9ef55f1d23bd6c3a9759586a4a6fa44`）需要先还原成上述官方 exe，再解压覆盖层。

## 发布包

使用 `tools/pack-release.ps1` 打包 `Melvor2_zh-CN_overlay_build26886380.zip`（仅英文文件名）。压缩包根目录直接包含 `override.cfg`、`mod/`、README 和 `SHA256SUMS.txt`。该脚本只供维护者打包，不是给玩家用来安装的。

## 译文来源

`mod/zh_CN.po` 由现有 0.11.7 简体中文包（历史上作为 `Locale/en_GB.po` 分发）转换而来，msgstr 与用词约定保持不变。维护时可运行 `tools/convert_en_GB_to_zh_CN_po.py`，从 `prototype/Locale/en_GB.po` 重新生成。
