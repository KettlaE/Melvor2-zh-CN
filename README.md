# Melvor Idle 2 简体中文翻译（覆盖层，非官方）

这是 Steam 抢先体验版 **Melvor Idle 2: A RuneScape Adventure**（AppID **3218350**）的玩家自制简体中文翻译。**不修改 Melvor2.exe**，只把几个小文件解压到游戏目录、放在 `Melvor2.exe` 旁边。装好后，可在游戏的语言设置里在「简体中文」和 English 之间切换，英文原版完整保留。

> ⚠️ 本翻译为**非官方**玩家作品，与 Games By Malcs 无关。游戏文字版权属于原开发者，请勿用于商业用途。

- 适用版本：Melvor Idle 2 `v0.11.7-alpha`（Steam build `26886380`，Windows）
- 翻译条目：14199 条（沿用我们现有的简体译文与用词约定）
- Steam 更新后一般不必重装 exe：覆盖层会继续生效，新增或改动过的英文会暂时保持原文，等翻译包更新即可

请从 [GitHub Release `overlay-26886380-2`](https://github.com/KettlaE/Melvor2-zh-CN/releases/tag/overlay-26886380-2) 下载 `Melvor2_zh-CN_overlay_build26886380.zip`，或直接使用本仓库根目录的 `override.cfg` 和 `mod` 文件夹。

覆盖层的安装方式参考了 [bmlee9527 / YukoCat 的繁体中文社区包](https://github.com/bmlee9527/melvor-idle-2-zh-tw)（[Steam 指南](https://steamcommunity.com/sharedfiles/filedetails/?id=3841417206)）。感谢他们公开了 `override.cfg` + 松散 `.po` + 运行时 GDScript 这条路径。本包的译文是我们自己的简体中文，不是把繁体包转换过来的。

## 安装（Windows）

1. **完全退出游戏**（任务栏里也不要留着）。
2. 若当前的 `Melvor2.exe` 还是旧的「改写 exe」汉化，请先还原官方 exe，再解压本包。可用 Steam 的「验证游戏文件完整性」，或把以前留下的官方备份拷回 `Melvor2.exe`。不要把覆盖层解压到改写版 exe 上。
3. 把压缩包里的 `override.cfg` 和 `mod` 文件夹**直接解压到 `Melvor2.exe` 所在的游戏目录**（不要多解压出一层子文件夹）。放好后长这样：

   ```
   Melvor2.exe
   override.cfg
   mod\
       zh_CN.po
       zh_CN_patch.gd
   data_GamesByMalcs.Melvor2_windows_x86_64\
   ```

4. 从 Steam 启动游戏，在**设置 → 语言**选择「简体中文」。

本包**不会修改 `Melvor2.exe`**（若你仍在用旧汉化，需要按上面第 2 步自行先还原官方 exe）。若你之前一直用旧汉化（中文写在英文语言包里），语言选项可能仍停在 English，需要手动切换一次。系统语言是简体中文、且这是第一次选语言时，通常会自动选上简体中文。

也可以从本仓库根目录复制同样的 `override.cfg` 和 `mod` 文件夹到游戏目录，效果相同。

## 切换语言

在游戏的语言设置里选「简体中文」或「English」即可，选择会被游戏记住。选英文时就是原版，翻译不会有任何作用。

## 卸载

删除游戏目录里的 `override.cfg` 和 `mod` 文件夹即可，**不会删除或改动官方 Melvor2.exe**。然后自行重开游戏即可。

## 运作原理

游戏使用 Godot 引擎的翻译系统，语言菜单会列出所有已载入的语言。

- `override.cfg`：Godot 会读取游戏目录里的这个文件。它让游戏额外载入 `mod/zh_CN.po`（语系 `zh_CN`，所以语言菜单会出现「简体中文」），并在启动时执行 `mod/zh_CN_patch.gd`。
- `zh_CN.po`：我们的简体中文翻译文件。不写入官方的 `Locale/en_GB.po`。
- `zh_CN_patch.gd`：有些文字是游戏程序直接显示原文、没经过翻译系统（例如商店说明、闪避列表的 Stab / Slash、「10 minutes」，以及 `LocalizedString.Message` 这类原始文本）。这个小脚本只在语言为简体中文时动作，用翻译文件的内容把画面上的这些英文换成中文；切回英文时会还原。

因为只是额外放文件，不会动到 `Melvor2.exe`、DLL 或存档。Steam 更新之后，覆盖层通常仍然有效，无需按 exe 哈希锁定版本。

## 已知问题

- 少数由游戏程序拼出来、混着图标和颜色的文字可能仍是英文。
- 游戏用程序拼出来的纯英文句子换成中文后，可能失去原本的颜色。
- 在游戏中切换语言时，游戏日志可能会出现一笔「显示设置」下拉菜单的错误。这是游戏本身的问题，切换任何语言都会发生，不影响使用。
- 想找出还没翻译的文字：把 `mod/zh_CN_patch.gd` 开头的 `LOG_UNTRANSLATED` 改成 `true`，玩一阵子后，`%APPDATA%\Games By Malcs\Melvor Idle 2\zh_CN_untranslated.txt` 会列出画面上仍是英文的文字。
- 游戏仍在抢先体验阶段，更新后新增的文字不会有翻译，需要等本包更新。
- 运行时脚本只处理 `Label`、`RichTextLabel`、`Button` 和 `PopupMenu` 上的文字。若有界面把原文写到其他类型的控件上，可能仍显示英文（旧的 exe 改写版会把中文直接写进 `MelvorBase.json`，覆盖面会更宽，但安装很慢）。详见 [`docs/overlay-report.md`](docs/overlay-report.md)。

## 文件说明

| 文件 | 说明 |
| --- | --- |
| `override.cfg` | 让游戏载入翻译与脚本的配置（Windows） |
| `mod/zh_CN.po` | 简体中文翻译文件 |
| `mod/zh_CN_patch.gd` | 运行时文字替换脚本 |
| `SHA256SUMS.txt` | 上述文件的 SHA256 |
| `docs/overlay-report.md` | 与繁体包、旧 exe 改写版的对照和技术说明 |

仓库里的 `tools/pack-release.ps1` 和 `tools/convert_en_GB_to_zh_CN_po.py` 只供维护打包使用，安装时不需要运行。

## 校验

覆盖层源文件哈希见 [`SHA256SUMS.txt`](SHA256SUMS.txt)。

发布包文件名：`Melvor2_zh-CN_overlay_build26886380.zip`（仅使用英文文件名，方便在 GitHub Release 中下载）。SHA256 见仓库里的 `Melvor2_zh-CN_overlay_build26886380.zip.sha256.txt`，以及 Release 说明。

## 旧的 exe 改写安装方式（已淘汰）

此前的安装方式会改写大约 600MB 的 `Melvor2.exe`，安装较慢，并且无法在游戏的语言设定里在中文和英文之间切换。**该方法已经淘汰，请不要再使用 `一键汉化.cmd`。**

若你电脑上还是旧汉化，请先用 Steam「验证游戏文件完整性」（或官方备份）还原官方 `Melvor2.exe`，再按上面的步骤把本包解压到游戏目录。历史文件保留在 [`legacy-exe-patch/`](legacy-exe-patch/)，旧版 Release 仍可在 [tag `build-26886380`](https://github.com/KettlaE/Melvor2-zh-CN/releases/tag/build-26886380) 下载，仅供存档。
