#!/bin/bash
# List, check, or update the current user's global skills (~/.agents/skills), i.e. npx skills <cmd> -g.
# Usage: ./dg_manage_skills.sh [list | check | update [skill ...]]
#
#   ./dg_manage_skills.sh                   npx skills list -g              List installed global skills
#   ./dg_manage_skills.sh check             npx skills check -g             Check which skills have updates
#   ./dg_manage_skills.sh update lark-doc   npx skills update lark-doc -g   Update lark-doc only
#   ./dg_manage_skills.sh update            npx skills update -g            Update all global skills with updates
#
# Not covered by this script, run directly in the terminal:
#   open ~/.agents/skills                     Open the skills directory in Finder (macOS)
#   less ~/.agents/skills/lark-doc/SKILL.md   Read a skill's description

if ! command -v npx >/dev/null 2>&1; then
    echo "Error: npx not found. Install Node.js first." >&2
    exit 1
fi

cmd=${1:-list}
shift
case "$cmd" in
    list|check|update) exec npx skills "$cmd" -g "$@" ;;
    *) echo "Usage: $0 [list | check | update [skill ...]]" >&2; exit 1 ;;
esac
