# Melvor Idle 2 简体中文覆盖层对照报告

日期：2026-11-25（Asia/Hong_Kong）

本文件记录覆盖层安装方式的设计对照与技术说明。当前仓库中的用户文件位于仓库根目录（`override.cfg`、`mod/zh_CN.po`、`mod/zh_CN_patch.gd` 及安装脚本）。本包把安装方式从「改写 `Melvor2.exe` 内嵌 PCK」改为「在 exe 旁放置少量覆盖文件」，译文仍是我们 0.11.7 / build 26886380 的简体中文包。覆盖层做法参考 bmlee9527 / YukoCat 的繁体中文社区包，但没有使用他们的译文。

## 1. 从源码确认的繁体包机制

参考来源（先读后改编）：

- Steam 指南：https://steamcommunity.com/sharedfiles/filedetails/?id=3841417206（作者 YukoCat）
- GitHub：https://github.com/bmlee9527/melvor-idle-2-zh-tw（仓库所有者 bmlee9527；克隆时最新提交 `1687763`，说明为 “Translate popup menu items in the runtime patch”）
- 仓库中**没有 LICENSE 文件**。README 声明为非官方、与 Games By Malcs 无关，游戏文字版权属于原开发者，请勿用于商业用途。本包遵循同样的声明，并在 `override.cfg`、`zh_CN_patch.gd`、`README.md` 中注明出处。

Windows 布局（放在 `Melvor2.exe` 旁边）：

```
Melvor2.exe
override.cfg
mod\
    zh_TW.po
    zh_TW_patch.gd
```

已确认的 `override.cfg` 键（CRLF）：

```
[autoload]
ZhTWPatch="*res://mod/zh_TW_patch.gd"

[internationalization]
locale/translations=PackedStringArray("res://Locale/en_GB.po", "res://mod/zh_TW.po")
```

含义：

- Godot 会读取可执行文件目录里的 `override.cfg`，覆盖工程设置。
- `locale/translations` 同时加载官方 PCK 内的 `res://Locale/en_GB.po`（英文）和松散文件 `res://mod/zh_TW.po`（语系 `zh_TW`，语言菜单出现「繁體中文」）。`*` 前缀表示 Autoload 单例。
- 松散文件按 `res://` 相对游戏目录解析；脚本读取 PO 样板时还会按顺序尝试：
  1. `OS.get_executable_path().get_base_dir() / mod / zh_TW.po`（可执行文件相对路径）
  2. `res://mod/zh_TW.po`
  3. `user://zh_TW.po`（Mac 试玩版/正式版脚本把文件放到用户目录）

Mac 脚本仅作参考，本包未提供 Mac 安装器。Mac 的 `override.cfg` 改从 `user://` 加载，并写入 `.app` 的 `Contents/MacOS` 与 `Contents/Resources`。

`zh_TW_patch.gd` 行为摘要（已通读）：

- Autoload `Node`，`PROCESS_MODE_ALWAYS`，`process_priority = 1 << 30`（排在其他节点 `_process` 之后，同一帧内换掉被游戏重设的英文；注释写明 `frame_pre_draw` 太晚会一直闪英文）。
- **仅当** `TranslationServer.get_locale().begins_with("zh")` 时工作；切回英文时把改过的控件还原为保存的原文。
- 追踪 `Label` / `RichTextLabel` / `Button`；另外追踪 `PopupMenu` 选项（例如追踪时段「1 hour」）。
- 调度：新节点下一帧立刻处理；被游戏反复改回英文的节点每帧检查（hot）；其余每帧检查 1/8（cold）。
- 替换路径：整句 `TranslationServer.translate`；去空白后再查；逗号列表「Stab, Slash, Crush」每项都有译文才换成顿号连接；`{0}` / `{Value:...}` 样板用正则把运行时数字填回中文模板；短词组逐词翻译后无空格拼接；中英夹杂句替换英文片段和 `less than `；「10 minutes」类时间单位。
- 商店说明等用 `add_text()` 拼出的富文本：`text` 为空，改读 `get_parsed_text()`，用去掉 BBCode 的原文去对 `_rich` 表，写入时保留译文里的标签。
- 拼出来、又含图标/颜色的长句：只处理长度 &lt; 100 且不含汉字的短句，避免整段重写丢图标。更长的仍可能保持英文。
- `LOG_UNTRANSLATED`（默认 `false`）：为 `true` 时把仍是英文的句子写到 `user://zh_TW_untranslated.txt`，即 `%APPDATA%\Games By Malcs\Melvor Idle 2\zh_TW_untranslated.txt`。`DEBUG` 可写 `zh_TW_debug.txt`。
- 不修改 `Melvor2.exe`、存档或 DLL。

繁体包文档中的已知限制（同样适用于本包，已写入 README）：

- 少数程序拼出来、混着图标和颜色的文字可能仍是英文。
- 程序拼出来的纯英文句子换成中文后，可能失去原本的颜色。
- 游戏内切换语言时，日志可能出现「显示设置」下拉菜单错误。这是游戏本身的问题，切任何语言都会发生，不影响使用。
- 抢先体验更新后的新文本会保持英文，直到翻译包更新。

他们的 PO 使用 `Language: zh_TW` 和 `Plural-Forms: nplurals=1; plural=0;`，复数条目只有 `msgstr[0]`。脚本解析 PO 时也只把 `msgstr[0]` 当作模板译文，并用它去匹配 `msgid_plural`。这对我们 17 条「Current / Max」目标文本不够，见第 4 节。

## 2. 本包产出文件

下列哈希与当前仓库根目录中的同名文件一致：

| 文件 | 字节 | SHA256 | 编码 |
| --- | ---: | --- | --- |
| `override.cfg` | 676 | `820c6faa6e0a2616f874759a0a331dac837f06dd46c2a43da0b883b2624bce2d` | UTF-8 无 BOM，CRLF |
| `mod/zh_CN.po` | 3,339,951 | `6ece38b933c72be4d644f0a161cd624d364e78ca205453531d520aa2e27f34aa` | UTF-8 无 BOM，LF，末尾换行 |
| `mod/zh_CN_patch.gd` | 15,478 | `dcddb5f3ec3d4f80b6352c2df749df1a6b13ac427d30bafa43103713f51d8610` | UTF-8 无 BOM，LF |
| `install-overlay.cmd` | 272 | `38eb872b93f25e00af70ff058017aac2abcee2cec76f09795b5de399db5ceb9a` | 纯 ASCII，CRLF |
| `uninstall-overlay.cmd` | 276 | `721850c2d82c198120d004a3a57cde218799ad17a94ade35472f0779b336555d` | 纯 ASCII，CRLF |
| `Install-Overlay.ps1` | 6,019 | `5bc3d5ec1cf18de8167783e5c70c78b65263edd55365dc66da85f81436846218` | UTF-8 BOM，CRLF |
| `Uninstall-Overlay.ps1` | 2,161 | `aea9355f63a4e5014227b2013a98e3be245406bb16e14967b2ea0ef33a06912f` | UTF-8 BOM，CRLF |
| `README.md` | 5,215 | `cef28cf687382c8ee1041acbf977d94ac849976b65ddf2524e7888ab26866f74` | UTF-8 无 BOM，LF |
| `tools/convert_en_GB_to_zh_CN_po.py` | 3,696 | `b459be11449199a51d9d27ee3d9a1b3ad4f69986bb5ff7df8d9a72645f0d09cd` | UTF-8 无 BOM，LF（可复现转换；用户机不需要 Python） |

`REPORT.md` 本身未列入上表。安装所需的核心文件是 `override.cfg` + `mod/zh_CN.po` + `mod/zh_CN_patch.gd`（合计约 3.2 MB，相对改写约 600 MB 的 exe 是一次小复制）。

本包 `override.cfg` 对应键：

```
[autoload]
ZhCNPatch="*res://mod/zh_CN_patch.gd"

[internationalization]
locale/translations=PackedStringArray("res://Locale/en_GB.po", "res://mod/zh_CN.po")
```

注意：不要写成 `res://Locale/zh_CN.po`。官方 PCK 里虽然有未加载的 `Locale/zh_CN.po`，那是官方简体（条目更少、用词与我们的锁定约定不完全相同）。本包加载的是游戏目录旁的 `mod/zh_CN.po`。

## 3. 译文如何从现有包转换

来源（0.11.7 / build 26886380，哈希与任务一致，已再校验）：

| 文件 | SHA256 | 说明 |
| --- | --- | --- |
| `/workspace/patch-fix/en_GB.po` | `f67e283357fd099614f5c853d185f601363a50fe354cce860585d1a121580fed` | 14,199 条，1,970 个复数；UTF-8 无 BOM，LF，末尾换行 |
| `/workspace/patch-fix/MelvorBase.json` | `533ff984edea677aab9914f9422b438276561af06c79a08b7ec94ce32f286a0e` | 仅作对照；新方法不再写入 exe 内的 JSON |
| `/workspace/patch-fix/manifest.json` | `fff2463deafa8bbbcf24039b402ea389d9fa5f16d940b22fa67e3bd2a001591f` | 同上 |

转换方法：只改 gettext 文件头（`Language: zh_CN`，`Project-Id-Version: Melvor2 zh_CN` 等），**文件头之后的全部条目正文与来源 `en_GB.po` 字节级相同**（已核对）。不把中文再写进 `en_GB`。占位符 `{0}`、`{Value:...}`、`[color]`、`[b]`、`[Player Name]` 以及复数形式均原样保留。

`msgid "Water"` 仍为 `msgstr "水域"`（农田地块按钮；魔法元素「流水」走的是「Water Rune」「Water vs Fire」等更具体条目，没有改这条共享 msgid）。

**复数策略（有意与繁体包 / 官方 `zh_CN` 不同）：**

- 官方与繁体包使用 `nplurals=1; plural=0;`，只有 `msgstr[0]`。
- 我们的包里有 **17** 条目标/计数文本，`msgstr[0]` 与 `msgstr[1]` 不同，例如「拥有 {ItemName}」对「拥有 {Current} / {Max} {ItemName}」。若改成 `nplurals=1`，进度数字会丢。
- 因此本包头写成 `Plural-Forms: nplurals=2; plural=(n != 1);`，并保留全部 `msgstr[0]` / `msgstr[1]`。语系仍是 `zh_CN`，语言菜单会显示简体中文。Godot 按该 PO 的复数公式选择条目。

锁定用词未重开，正文未改。可用 `tools/convert_en_GB_to_zh_CN_po.py` 从更新后的 `en_GB.po` 再生成。

## 4. 运行时脚本覆盖范围，对照旧的 JSON / 场景补丁

旧方法做了三件事：

1. 把中文写进嵌入的 `Locale/en_GB.po`（语言菜单通常看不到中文选项，因为实际只加载了 `en_GB`）。
2. 把已译中文写回 `MelvorBase.json` 的 `LocalizedString.Message` / `PluralString.Singular|Plural`（官方 0.11.7 JSON 中这三类字段共 3,904 处全部写穿为中文），因为部分界面直接读 `.Message`，不查翻译系统。
3. 替换 38 个关闭了自动翻译的 `FormatString` 场景模板（例如 `{0:N0} Available`、`+{0:N0} HP`、`Lasts for {0:F2}s`、`Lasts [b]{0:numbertime(ms)}[/b] after growing.`、牧场 Comfort/Hunger 等）。

新方法用官方英文 exe + `zh_CN.po` + 运行时脚本代替 2 和 3：

| 旧做法 | 覆盖层如何覆盖 | 评估 |
| --- | --- | --- |
| `en_GB.po` 运载中文 | 真正的 `zh_CN.po` 经 `override.cfg` 加载；官方 `en_GB.po` 保持英文 | 更好：可在设置里切换简体中文 / English |
| JSON `.Message` 写穿（商店说明、物品名被直接塞到控件上等） | 脚本监视 Label / RichTextLabel / Button / PopupMenu；整句查找翻译；富文本用去标签后的原文对 `_rich` 表，写回带标签的译文 | **在这四类控件上应能覆盖**。物品名若只把 `DisplayName.Singular` 赋给 Label，再靠 AutoTranslate 或脚本的 `_tr()`，PO 里无上下文回退条目仍然有效 |
| 38 个 FormatString 场景 | PO 里保留了这些英文模板；脚本用 `{…}` 样板匹配运行时已填数字的字符串，再套中文模板 | **应能覆盖**这些模板。额外改进：样板匹配成功后仍会把捕获值里的 `10 minutes` 换成 `10 分钟`（繁体脚本在这里会提前返回，时间单位可能残留英文） |
| 逗号武器列表 Stab / Slash / Crush、「10 minutes」弹单 | 脚本原有逻辑，时间单位改为简体「小时 / 分钟」 | 覆盖，且用词已简体化 |
| 目标复数（Current / Max） | 脚本改为：`msgid` → `msgstr[0]`，`msgid_plural` → `msgstr[1]`；PO 保留 `nplurals=2` | 覆盖，且优于繁体脚本只把 `msgstr[0]` 套到复数模板 |

对本包脚本相对繁体脚本的改编（不是改译文）：

- 语系判断改为只认 `zh_CN`（以及 `zh_CN_*`），不再用 `begins_with("zh")`。
- `UNITS` 使用「小时」「分钟」。
- 解析并使用 `msgstr[1]`。
- 样板命中后仍做时间单位替换。
- `LOG_UNTRANSLATED` 写到 `user://zh_CN_untranslated.txt`。
- 注释改为简体，并保留对 bmlee9527 / YukoCat 的出处说明。

## 5. 仍存在的限制（相对旧 exe 改写版，不会悄悄丢掉而不说明）

这些是覆盖层方法固有的或尚未用脚本补上的差距，安装前需要知道：

1. **控件类型范围。** 脚本只改 `Label`、`RichTextLabel`、`Button`、`PopupMenu`。旧 JSON 写穿会让任何直接读取 `.Message` 的界面都显示中文，包括上述类型之外的控件（例如某些自定义控件、ItemList、Tree、LineEdit、非 Label 的提示层）。若实机发现这类漏英，应记录后考虑扩展脚本，而不是再改 exe。
2. **拼出来的图标/颜色长句。** 与繁体包相同：可能仍是英文；强行整段替换可能丢颜色或图标。旧的场景/JSON 写穿有时能保住这些排版，因为译文被写进原始数据。
3. **颜色丢失。** 纯英文拼句被整段换成中文时，可能失去原本颜色（繁体包已记录）。
4. **切换语言时的显示设置日志错误。** 游戏本身的问题。
5. **更新后的新字符串。** 保持英文，直到我们更新 PO。这是预期行为，不再用 exe 哈希锁定。
6. **脚本未覆盖的控件里的 FormatString。** 目前 38 个已补场景里的模板都出现在普通标签/富文本上，预期可由样板匹配处理；若有写到其他控件上的，会漏。
7. **尚未在游戏内跑过。** 本任务明确要求不要启动游戏、不要装进 Steam 目录，因此「语言菜单是否出现简体中文、JSON 写穿与 FormatString 是否全部被脚本接住」还需要一次实机确认。

没有把旧的 `MelvorBase.json` 或 38 个 `.scn` 打进覆盖层，以保持「只复制小文件、不改 exe」的目标。

## 6. 从当前已安装的改写版 exe 迁移

当前用户机（Kellta_Laptop，`22dde8ae-94f3-4962-9a6d-e354fecab7af`）状态，摘自 2026-11-25 安装记录：

| 项目 | SHA256 | 大小 |
| --- | --- | --- |
| 已安装的改写版 `Melvor2.exe` | `bd660f06968b54bad4ae95d55fc3402df9ef55f1d23bd6c3a9759586a4a6fa44` | 621,136,032 |
| 官方 backup（build 26886380） | `4fbd4504809b2d2cf3c12ad962a632f4b1dd0934eebd2452f3766ebc313146d1` | 602,186,032 |

官方备份路径：

`E:\Games\SteamLibrary\steamapps\common\Melvor Idle 2\Melvor2_简体中文\backups\26886380-4fbd4504809b2d2c\Melvor2.exe.original`

安装脚本（`Install-Overlay.ps1`，由 ASCII 的 `install-overlay.cmd` 启动）计划步骤：

1. 若 `Melvor2.exe` 进程在运行，**中止**并请用户先退出。不强杀。
2. 计算当前 `Melvor2.exe` 的 SHA256。
3. 若是已知改写版哈希（含当前的 `bd660f06…`，以及更早的 `166da981…`、`f152025a…`、`a982a738…`），先从 `Melvor2_简体中文\backups\**\Melvor2.exe.original` 找到对应官方哈希的备份，还原并校验；**禁止**在改写版 exe 上直接叠放覆盖层。找不到备份则中止，提示用 Steam「验证游戏文件完整性」。
4. 若已是已知官方哈希（`4fbd4504…` 或旧版 `770b22a1…`），只复制覆盖文件。
5. 若是未知哈希（多半是新的 Steam 官方更新），只复制覆盖文件并警告；**不会**用旧官方备份覆盖新版 exe。
6. 将 `override.cfg` 和 `mod\zh_CN.po`、`mod\zh_CN_patch.gd` 复制到游戏目录。
7. **不启动游戏。** 提示用户自行启动，并在设置里选「简体中文」。若以前一直用 en_GB 改写通道，语言可能仍停在 English，需要手动切一次。

卸载：只删除 `override.cfg` 和整个 `mod` 文件夹，不动 `Melvor2.exe`。游戏在运行则中止。

默认游戏路径：`E:\Games\SteamLibrary\steamapps\common\Melvor Idle 2`（可用 `-GameDir` 覆盖）。用户机没有 Python，安装只依赖 PowerShell / cmd。

## 7. 建议的下一步（需父代理 / 用户确认后再做）

覆盖层方法**可行**，并且能解决「每次改 exe 大约 600 MB、安装慢」以及「设置里切不了中英文」这两个核心问题。建议在用户确认后，再由父代理在用户机关闭游戏的前提下执行安装脚本，然后请用户启动一次，检查：

- 设置里是否出现「简体中文」，切到英文是否完全恢复官方文本；
- 商店说明、物品名、闪避列表、时间单位、目标进度（Current / Max）、以及原先 38 个 FormatString 界面是否仍是中文；
- 有无脚本范围之外的新漏英。

在此之前不要把文件复制到 `E:\Games\...`，不要启动游戏，不要推 GitHub。
