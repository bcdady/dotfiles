#!/bin/sh
# gitlab-token.sh — POSIX-compatible, safe to source from .profile and .bashrc
# Caches GITLAB_TOKEN for 24h to avoid running glab on every shell or login.

# Already set (e.g. sourced earlier in this session) — skip
[ -n "${GITLAB_TOKEN:-}" ] && return 0 2>/dev/null

_glcache="$HOME/.cache/glab_token"
if [ -f "$_glcache" ] && [ "$(( $(command date +%s) - $(stat -c %Y "$_glcache") ))" -lt 86400 ]; then
  GITLAB_TOKEN=$(cat "$_glcache")
elif command -v glab >/dev/null 2>&1; then
  GITLAB_TOKEN=$(glab auth status --show-token 2>&1 | grep "Token found" | awk '{print $NF}')
  if [ -n "$GITLAB_TOKEN" ]; then
    mkdir -p "${_glcache%/*}"
    printf '%s' "$GITLAB_TOKEN" > "$_glcache"
  fi
fi
[ -n "$GITLAB_TOKEN" ] && export GITLAB_TOKEN
unset _glcache
