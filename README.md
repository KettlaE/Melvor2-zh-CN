# Melvor Idle 2 简体中文翻译（非官方）

这是 Steam 抢先体验版 **Melvor Idle 2: A RuneScape Adventure** 的玩家自制简体中文翻译，适用游戏版本 **v0.11.7-alpha**（Windows）。

> ⚠️ 本翻译为**非官方**玩家作品，与 Games By Malcs 无关。游戏文字版权属于原开发者，请勿用于商业用途。本包不会修改 `Melvor2.exe` 或游戏存档。

请从 [最新 Release](https://github.com/KettlaE/Melvor2-zh-CN/releases/latest) 下载对应压缩包。仓库中的 `overlay/` 和 `modloader/` 目录与 Release 压缩包内容相同。

## 该选哪个版本

两种安装方式的**译文相同**，但加载方式不同，**不能同时使用**（游戏目录里只能有一份 `override.cfg`）。请只选一种：

| 版本 | 适合谁 | 压缩包 |
| --- | --- | --- |
| 解压覆盖层（不需要 Mod Loader） | 只想装中文、不使用其它模组 | `Melvor2_zh-CN_overlay_v0.11.7-alpha.zip` |
| Melvor Mod Loader 版 | 已经安装、或准备使用 Melvor Mod Loader 和其它模组 | `Melvor2_zh-CN_modloader_v0.11.7-alpha.zip` |

切换安装方式前，请先**完全退出游戏**（任务栏里也不要留着），并按下面对应章节卸掉旧的那一套，再安装新的。

## 解压覆盖层（不需要 Mod Loader）

把 `override.cfg` 和 `mod` 文件夹直接放到 `Melvor2.exe` 旁边即可，不需要安装 Melvor Mod Loader。

### 安装

1. **完全退出游戏**（任务栏里也不要留着）。
2. 若当前的 `Melvor2.exe` 还是旧的「改写 exe」中文版，请先还原官方 exe，再解压本包。可用 Steam 的「验证游戏文件完整性」，或把以前留下的官方备份拷回 `Melvor2.exe`。不要把覆盖层解压到改写版 exe 上。
3. 若你正在使用 Melvor Mod Loader 版汉化，请先删除游戏目录里的 `mods\zh-CN` 文件夹；如果不再使用 Loader，再按 Loader 的说明把它一并卸掉（包括它的 `override.cfg`）。不要让两份 `override.cfg` 叠在一起。
4. 把压缩包里的 `override.cfg` 和 `mod` 文件夹**直接解压到 `Melvor2.exe` 所在的游戏目录**（不要多解压出一层子文件夹）。放好后长这样：

   ```
   Melvor2.exe
   override.cfg
   mod\
       zh_CN.po
       zh_CN_patch.gd
   data_GamesByMalcs.Melvor2_windows_x86_64\
   ```

5. 从 Steam 启动游戏，在**设置 → 语言**选择「简体中文」。

本包不会修改 `Melvor2.exe`。若你之前一直用旧的 exe 改写版汉化（中文写在英文语言包里），语言选项可能仍停在 English，需要手动切换一次。

### 卸载

删除游戏目录里的 `override.cfg` 和 `mod` 文件夹即可，不会删除或改动官方 `Melvor2.exe`。然后自行重开游戏即可。

## Melvor Mod Loader 版

本包把简体中文放进 Loader 的 `mods` 文件夹里加载，**不带、也不应覆盖 Loader 自己的 `override.cfg`**。需要先安装 [Melvor Mod Loader](https://www.nexusmods.com/melvoridle2/mods/2) **0.2.0 或更新**（建议 0.3.0）。

本包只汉化游戏正文，不翻译 Melvor Mod Loader 的模组菜单或其他模组界面。

### 安装

1. **完全退出游戏**（任务栏里也不要留着）。
2. **若你现在用的是解压覆盖层汉化**（游戏目录里已有覆盖层的 `override.cfg` 和 `mod` 文件夹）：先删除这两个东西。这只是覆盖层本身，不会改动 `Melvor2.exe` 或存档。
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
5. 从 Steam 启动游戏，在**设置 → 语言**选择「简体中文」。成功时，游戏目录里的 `MelvorModLoader.log` 会有一行：`Mod loaded: ZhCNLocalization`。

如果设置里没有「简体中文」，或语言按钮不见了：请确认 Loader 已正常启动、本包在 `mods\zh-CN\` 下，然后完全退出后再开一次。不要同时留下覆盖层的 `override.cfg`。

### 卸载

删除游戏目录里的 `mods\zh-CN` 文件夹，再在游戏里把语言改回 English。**不要删除 Loader 的 `override.cfg`**，除非你也要卸掉 Melvor Mod Loader。卸 Loader 时，按官方说明删除它的 `override.cfg` 和 `data_MelvorModLoader_windows_x86_64`。

若要改回解压覆盖层汉化：先卸掉本包，再按上一节安装覆盖层。不要让两份 `override.cfg` 叠在一起。

## 说明与致谢

装好后，可在游戏的语言设置里在「简体中文」和 English 之间切换。切回英文时就是原版。

覆盖层的安装方式参考了 [bmlee9527 / YukoCat 的繁体中文社区包](https://github.com/bmlee9527/melvor-idle-2-zh-tw)。感谢他们公开了 `override.cfg` + 松散 `.po` + 运行时 GDScript 这条路径。本包的译文是我们自己的简体中文，不是把繁体包转换过来的。

Mod Loader 版的接入方式参考了 [falorfrozen 的 Melvor Mod Loader](https://github.com/falorfrozen-cmd/MelvorModLoader) 与 [CyPh3R 的 Localization Pack（Mod Loader 版）](https://github.com/Mr-CyPh3R/Melvor-Idle-2-Localization-Pack) 的加载桥接。本包没有使用他们的译文，也只汉化游戏正文，不翻译 Loader 菜单或其他模组界面。

更早的 exe 改写版汉化已经淘汰，仅作为历史版本保留在过去的 [Releases](https://github.com/KettlaE/Melvor2-zh-CN/releases) 中。仓库里不再提供这些文件。若你电脑上还是旧汉化，请先用 Steam「验证游戏文件完整性」（或官方备份）还原官方 `Melvor2.exe`，再按上面的步骤安装当前版本。

游戏仍在抢先体验阶段，更新后新增的文字可能暂时保持英文，需要等本包更新。
