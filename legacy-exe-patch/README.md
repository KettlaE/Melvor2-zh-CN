# 旧的 exe 改写安装方式（已淘汰）

本目录保存此前「改写 `Melvor2.exe` 内嵌语言包」的一键汉化包，仅供存档。

**请改用仓库根目录的覆盖层安装方式**（`install-overlay.cmd`）。新方法不修改 `Melvor2.exe`，安装更快，也可以在游戏的语言设定里在「简体中文」和 English 之间切换。

若电脑上还装着本目录这种旧汉化，直接运行仓库根目录的 `install-overlay.cmd` 即可：脚本会先还原官方 exe 备份，再放入覆盖文件。请不要再双击本目录里的 `一键汉化.cmd`。

旧版 GitHub Release 仍保留在：

- https://github.com/KettlaE/Melvor2-zh-CN/releases/tag/build-26886380 （v0.11.7-alpha）
- https://github.com/KettlaE/Melvor2-zh-CN/releases/tag/build-26724394

本目录中的 `Melvor2_zh-CN_build26886380.zip` 与 `Melvor2_简体中文_build26886380.zip` 是同一份旧补丁包（仅文件名不同）。仓库根目录的 `tools/Patch-Game.ps1`、`prototype/` 等也属于这一套已淘汰的构建流程，不再用于日常安装。
