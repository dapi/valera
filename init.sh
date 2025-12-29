#!/usr/bin/env bash
mise trust
git submodule init
git submodule update

# Copy .envrc from main/master worktree
BASE_DIR=$(git worktree list | grep -E '\[(main|master)\]' | head -1 | awk '{print $1}')
cp "$BASE_DIR/.env*" .

direnv allow
