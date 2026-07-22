#!/bin/bash
# dg_codeup_user.sh
# Set repo-level git identity for Codeup (git config --local).
# Usage: ./dg_codeup_user.sh

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository."
  exit 1
fi

git config --local user.name "yuxiang"
git config --local user.email "yuxiang204@yeah.net"

echo "user.name  = $(git config --local user.name)"
echo "user.email = $(git config --local user.email)"
