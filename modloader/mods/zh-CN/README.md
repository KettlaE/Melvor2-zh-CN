# Melvor Idle 2 简体中文翻译（Melvor Mod Loader 版，非官方）

这是 Steam 抢先体验版 **Melvor Idle 2: A RuneScape Adventure**（AppID **3218350**）的玩家自制简体中文翻译，供已经安装、或准备安装 **Melvor Mod Loader** 的玩家使用。

本包把简体中文放进 Loader 的 `mods` 文件夹里加载，**不带、也不应覆盖 Loader 的 `override.cfg`**。装好后，可在游戏的语言设置里在「简体中文」和 English 之间切换。译文与运行时补丁和现有的解压覆盖层汉化相同。

> ⚠️ 本翻译为**非官方**玩家作品，与 Games By Malcs 无关。游戏文字版权属于原开发者，请勿用于商业用途。

- 适用游戏版本：Melvor Idle 2 `v0.11.7-alpha`（Windows）
- 需要：Melvor Mod Loader **0.2.0 或更新**（按 0.3.0 的公开说明与 API 制作）
- 翻译条目：14199 条（沿用我们现有的简体译文与用词约定）
- 本包**不会修改** `Melvor2.exe` 或存档

解压覆盖层汉化（`override.cfg` + `mod\`）仍是独立的安装方式，并未被本包取代。两者都要用 Godot 的 `override.cfg`，**不能同时使用**。要用本包和其它 Mod Loader 模组一起玩，请先改用 Loader 的 `override.cfg`，再安装本包。

Mod Loader 的接入方式参考了 [CyPh3R 的 Localization Pack（Mod Loader 版）](https://github.com/Mr-CyPh3R/Melvor-Idle-2-Localization-Pack) 与 [falorfrozen 的 Melvor Mod Loader](https://github.com/falorfrozen-cmd/MelvorModLoader)。覆盖层本身仍参考了 [bmlee9527 / YukoCat 的繁体中文社区包](https://github.com/bmlee9527/melvor-idle-2-zh-tw) 公开的松散 `.po` + 运行时脚本路径。本包的译文是我们自己的简体中文，不是把上述任一包转换过来的。

## 安装

1. **完全退出游戏**（任务栏里也不要留着）。
2. **若你现在用的是解压覆盖层汉化**（游戏目录里已有我们的 `override.cfg` 和 `mod` 文件夹）：先删除这两个东西。这只是覆盖层本身，不会改动 `Melvor2.exe` 或存档。
3. **先安装 Melvor Mod Loader 0.2.0 或更新版本**（建议 0.3.0）：把 Loader 的压缩包解压到 `Melvor2.exe` 旁边，使 Loader 自己的 `override.cfg` 和 `data_MelvorModLoader_windows_x86_64` 就位。
   - 下载：https://www.nexusmods.com/melvoridle2/mods/2
   - 说明：https://falorfrozen-cmd.github.io/MelvorModLoader/
   - 源码：https://github.com/falorfrozen-cmd/MelvorModLoader
4. 把本包解压到 `Melvor2.exe` 所在的游戏目录，使 `mods\zh-CN\` 出现在游戏目录下（不要多解压出一层子文件夹）。**不要改动、不要替换 Loader 的 `override.cfg`。** 放好后长这样：

   ```
   Melvor2.exe
   override.cfg                          （来自 Melvor Mod Loader，不要换成覆盖层那份）
   data_MelvorModLoader_windows_x86_64\  （来自 Melvor Mod Loader）
   mods\
       zh-CN\
           ZhCNLocalization.dll
           zh_CN.po
           zh_CN_patch.gd
           mod.json
   data_GamesByMalcs.Melvor2_windows_x86_64\
   ```

   Windows 上 `mods` 和 `Mods` 是同一个文件夹。若你已有其它 Mod Loader 模组，把 `zh-CN` 文件夹放进现有的 `mods`（或 `Mods`）即可。
5. 从 Steam 启动游戏，在**设置 → 语言**选择「简体中文」。成功时，游戏目录里的 `MelvorModLoader.log` 会有一行：`Mod loaded: ZhCNLocalization`。开头左上角的绿色 Loader 行也会把模组计数加 1。

如果设置里没有「简体中文」，或语言按钮不见了：请确认 Loader 已正常启动、本包在 `mods\zh-CN\` 下，然后完全退出后再开一次。不要同时留下覆盖层的 `override.cfg`。

## 卸载

删除游戏目录里的 `mods\zh-CN` 文件夹，再在游戏里把语言改回 English。不要删除 Loader 的 `override.cfg`，除非你也要卸掉 Melvor Mod Loader。卸 Loader 时，按官方说明删除它的 `override.cfg` 和 `data_MelvorModLoader_windows_x86_64`。

若要改回解压覆盖层汉化：先卸掉（或至少不要使用）本包，再按覆盖层说明安装它自己的 `override.cfg` 和 `mod` 文件夹。不要让两份 `override.cfg` 叠在一起。

## 与覆盖层的差异和限制

- 覆盖层在游戏启动时就通过 `override.cfg` 载入译文；本包要等 Melvor Mod Loader 在第一帧加载模组后才会注册 `zh_CN`。因此需要先装 Loader，并且不能保留覆盖层的 `override.cfg`。
- 本包会尝试把已保存在设置里的「简体中文」恢复回来（游戏会在模组加载前读设置；当时若还没有中文目录，会暂时退回英文）。若第一次启动没有自动选上，请在设置里手动选一次。
- 运行时补丁的行为与覆盖层相同：只在语言为简体中文时替换画面上漏出的英文（`Label` / `RichTextLabel` / `Button` / `PopupMenu`），切回英文时还原。
- 本包只汉化游戏正文，不翻译 Melvor Mod Loader 或其他模组的界面。
- 可以与其它 **Mod Loader 模组**（例如 Cheat Menu、Localization Pack 的 Mod Loader 版）一起使用。不要同时安装 Localization Pack 的「自带 override.cfg」独立版。
- 本包未在游戏内实际启动测试（制作时没有运行游戏）。请以 `MelvorModLoader.log` 和语言菜单是否出现「简体中文」为准。
- 已知的界面限制与覆盖层相同：少数由程序拼出来、混着图标和颜色的文字可能仍是英文；切换语言时游戏日志可能出现一笔「显示设置」下拉菜单的错误（游戏本身的问题）。

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `mods/zh-CN/ZhCNLocalization.dll` | Melvor Mod Loader 入口（IMod），负责注册译文、恢复已保存的语言、启动运行时脚本 |
| `mods/zh-CN/zh_CN.po` | 简体中文翻译文件（语系 `zh_CN`） |
| `mods/zh-CN/zh_CN_patch.gd` | 运行时文字替换脚本 |
| `mods/zh-CN/mod.json` | 模组说明（Loader 不强制要求此文件） |

源码在旁路目录 `src/`（本压缩包不含），用于以后在有游戏 `GodotSharp.dll` 和 .NET 10 SDK 的环境中重新编译 DLL。
