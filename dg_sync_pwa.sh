#!/bin/bash
# dg_sync_pwa.sh
# Sync the PWA repos under ~/repo_projects/codeup/pwa (git fetch -p + git rebase).
# Stops at the first error and leaves that repo as is for manual handling.
# Usage: ./dg_sync_pwa.sh [repo ...]   (no args: all repos)

PWA_DIR="$HOME/repo_projects/codeup/pwa"

if [ $# -gt 0 ]; then
  repos=("$@")
else
  repos=()
  for dir in "$PWA_DIR"/*/; do
    [ -d "$dir/.git" ] && repos+=("$(basename "$dir")")
  done
fi

if [ ${#repos[@]} -eq 0 ]; then
  echo "Error: no git repos found in $PWA_DIR."
  exit 1
fi

for repo in "${repos[@]}"; do
  path="$PWA_DIR/$repo"
  echo -e "\n===== $repo ====="

  if [ ! -d "$path/.git" ]; then
    echo "Error: $path is not a git repo."
    exit 1
  fi

  echo "Branch: $(git -C "$path" branch --show-current)"
  if ! git -C "$path" fetch -p || ! git -C "$path" rebase; then
    echo -e "\nStopped at $repo. Handle it manually in $path"
    exit 1
  fi
done

echo -e "\nAll synced."
