## Dev Garage

个人常用脚本库，放日常提效的小工具。所有脚本以 `dg_` 为前缀。

### 使用

直接运行脚本即可，如 `./dg_find_port.sh 8080`。支持 macOS 和 Linux，部分脚本依赖 `dig`、`whois`、`lsof`、`xxd` 或 `curl`。

### 脚本

| 脚本 | 说明 |
|------|------|
| `dg_check_hardware.sh` | 查看硬件配置（CPU、内存、磁盘、GPU、网卡） |
| `dg_check_image.sh <file>` | 通过 magic bytes 识别图片格式 |
| `dg_check_network.sh` | 检查外网连通性和 proxy/VPN 状态 |
| `dg_domain_lookup.sh <domain>` | 用 `dig` 做 DNS 查询 |
| `dg_reverse_lookup.sh <ip>` | 反向 DNS 查询 |
| `dg_whois_lookup.sh <domain>` | WHOIS 查询 |
| `dg_find_port.sh <port>` | 查看端口被哪个进程占用 |
| `dg_set_codeup_identity.sh` | 在 Codeup 仓库内运行，设置 repo 级别的 git user/email，覆盖全局 `~/.gitconfig` 身份 |
| `dg_sync_pwa.sh [repo ...]` | 对 `~/repo_projects/codeup/pwa` 下各仓库执行 `git fetch -p` + `git rebase`，不带参数时同步全部 |
| `dg_manage_skills.sh [cmd] [skill ...]` | 管理全局 skills，等同 `npx skills <cmd> -g`；`cmd` 为 `list`（默认）、`check` 或 `update` |

### 贡献

新增或修改脚本的规范见 [AGENTS.md](AGENTS.md)。
