#!/bin/bash
# 查看、检查或升级当前用户的全局 skills（~/.agents/skills），等同 npx skills <cmd> -g。
# Usage: ./dg_manage_skills.sh [list | check | update [skill ...]]
#   不带参数等同于 list；update 不带 skill 时升级全部有更新的。

if ! command -v npx >/dev/null 2>&1; then
    echo "需要 npx，请先安装 Node.js。" >&2
    exit 1
fi

cmd=${1:-list}
shift
case "$cmd" in
    list|check|update) exec npx skills "$cmd" -g "$@" ;;
    *) echo "Usage: $0 [list | check | update [skill ...]]" >&2; exit 1 ;;
esac
