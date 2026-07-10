#!/bin/sh
# gitlab-token.sh — POSIX-compatible, safe to source from .profile and .bashrc
# Caches GITLAB_TOKEN (1h) and GITLAB_HOST (persistent, prompted on first use).
# Cache is auto-invalidated when ~/.config/glab-cli/config.yml is newer.
#
# Token rotation workflow:
#   1. Rotate token in GitLab UI
#   2. glab auth login --hostname subsplash.io   # updates config.yml
#   3. gitlab-token-refresh                       # or open a new shell
#
# Force-refresh in the current shell:
#   . ~/.config/shell/gitlab-token.sh refresh

_gldir="$HOME/.cache"
_gl_force_refresh=0
case "${1:-}" in refresh|force|-f) _gl_force_refresh=1 ;; esac

# --- GITLAB_HOST (persistent cache, interactive prompt on first use) ---
if [ -z "${GITLAB_HOST:-}" ]; then
  _glhost_cache="$_gldir/glab_host"
  if [ -f "$_glhost_cache" ]; then
    GITLAB_HOST=$(cat "$_glhost_cache")
  elif [ -t 0 ]; then
    # Interactive shell — prompt for the GitLab host URL
    printf 'Enter your GitLab host URL (https://...): '
    read -r _glhost_input
    case "$_glhost_input" in
      https://*.*)
        mkdir -p "$_gldir"
        printf '%s' "$_glhost_input" > "$_glhost_cache"
        GITLAB_HOST="$_glhost_input"
        ;;
      *)
        echo "Invalid: must be an https:// URL (e.g. https://gitlab.example.com)" >&2
        ;;
    esac
    unset _glhost_input
  fi
  [ -n "${GITLAB_HOST:-}" ] && export GITLAB_HOST
  unset _glhost_cache
fi

# --- GITLAB_TOKEN (1h cache, auto-invalidated when config.yml is newer) ---
# Skip if already set AND not forcing a refresh.
if [ -z "${GITLAB_TOKEN:-}" ] || [ "$_gl_force_refresh" -eq 1 ]; then
  _gltoken_cache="$_gldir/glab_token"
  _glconfig="$HOME/.config/glab-cli/config.yml"
  # Use cache if: not forcing refresh, exists, <1h old, and not older than config.yml
  if [ "$_gl_force_refresh" -eq 0 ] \
      && [ -f "$_gltoken_cache" ] \
      && [ "$(( $(command date +%s) - $(stat -c %Y "$_gltoken_cache") ))" -lt 3600 ] \
      && { [ ! -f "$_glconfig" ] || [ "$_gltoken_cache" -nt "$_glconfig" ]; }; then
    GITLAB_TOKEN=$(cat "$_gltoken_cache")
  elif command -v glab >/dev/null 2>&1; then
    # Unset so glab reads from config.yml, not the (possibly stale) env var.
    # Prefer `glab config get` (reads config.yml directly, no API call, no fragile parse).
    _gl_prev_token="${GITLAB_TOKEN:-}"
    unset GITLAB_TOKEN
    GITLAB_TOKEN=$(glab config get --host subsplash.io token 2>/dev/null)
    if [ -n "$GITLAB_TOKEN" ]; then
      mkdir -p "$_gldir"
      printf '%s' "$GITLAB_TOKEN" > "$_gltoken_cache"
    else
      # Fall back to previous value if the refresh failed
      GITLAB_TOKEN="$_gl_prev_token"
      echo "Warning: could not read GITLAB_TOKEN from glab config (~/.config/glab-cli/config.yml). Run: glab auth login --hostname subsplash.io" >&2
    fi
    unset _gl_prev_token
  fi
  [ -n "${GITLAB_TOKEN:-}" ] && export GITLAB_TOKEN
  unset _gltoken_cache _glconfig
fi

unset _gldir _gl_force_refresh
