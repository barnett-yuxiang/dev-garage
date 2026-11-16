# AGENTS.md

给在本仓库工作的 coding agent 的说明。各脚本的功能见 `README.md`。

## 定位与结构

个人常用脚本库，放日常提效的小工具。

- 每个脚本只做一件事，保持简短，放在根目录，彼此独立。没有共享库、构建步骤或测试。
- 只给自己用：个人配置（如 `dg_set_codeup_identity.sh` 里的身份）直接写在脚本里即可，不必为通用性做参数化。

## 脚本规范

- 文件名：`dg_` 前缀，小写加下划线，体现动作和对象（如 `dg_find_port.sh`、`dg_domain_lookup.sh`）；会修改状态的脚本用 `set` 等动词标明。需可执行（`chmod +x`）。
- 首行 `#!/bin/bash`，随后用简短注释写明用途和 `Usage:`。
- 有必填参数的脚本，开头先校验：缺参数时输出 `Usage: $0 <arg>` 并 `exit 1`。
- 需同时支持 macOS 和 Linux：用 `$OSTYPE` 区分系统，可选工具先用 `command -v` 判断。
- 修改文件时沿用其原有缩进。

## 新增或重命名脚本

1. 遵循上述规范。
2. 在 `README.md` 的脚本表格中新增或更新对应行。

## 验证

- 用 `bash -n <script>` 检查语法；装了 `shellcheck` 的话也跑一下。
- 有必填参数的脚本，不带参数运行，确认会输出 usage。

以下脚本有副作用，未经要求不要运行：

- `dg_set_codeup_identity.sh`：用于在 Codeup 仓库内运行，以 repo 级别的 user/email 覆盖全局 `~/.gitconfig` 身份。不要在本仓库运行，本仓库使用全局身份。
- `dg_check_network.sh`：会访问外网（ipinfo.io、Google 等）。
- `dg_sync_pwa.sh`：会对 `~/repo_projects/codeup/pwa` 下的仓库执行 `git fetch -p` 和 `git rebase`。
- `dg_check_hardware.sh`：在 Linux 上会调用 `sudo dmidecode`。

## Git

- 在 `dev` 分支开发，向 `main` 提 PR。
- Commit message 用英文祈使句，单行（如 `Add dg_foo_bar.sh to ...`）。
