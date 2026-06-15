#!/bin/sh
# github-token.sh — POSIX-compatible, safe to source from .profile and .bashrc
# Caches GITHUB_TOKEN for 24h to avoid running gh on every shell or login.

# Already set (e.g. sourced earlier in this session) — skip
[ -n "${GITHUB_TOKEN:-}" ] && return 0 2>/dev/null

_ghcache="$HOME/.cache/gh_token"
if [ -f "$_ghcache" ] && [ "$(( $(command date +%s) - $(stat -c %Y "$_ghcache") ))" -lt 86400 ]; then
  GITHUB_TOKEN=$(cat "$_ghcache")
elif command -v gh >/dev/null 2>&1; then
  GITHUB_TOKEN=$(gh auth token 2>/dev/null)
  if [ -n "$GITHUB_TOKEN" ]; then
    mkdir -p "${_ghcache%/*}"
    printf '%s' "$GITHUB_TOKEN" > "$_ghcache"
  fi
fi
[ -n "$GITHUB_TOKEN" ] && export GITHUB_TOKEN
unset _ghcache
