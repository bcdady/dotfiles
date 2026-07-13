#!/bin/sh
# gitlab-token.sh — POSIX-compatible, safe to source from .profile and .bashrc
# Caches GITLAB_TOKEN (24h) and GITLAB_HOST (persistent, prompted on first use).

_gldir="$HOME/.cache"

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

# --- GITLAB_TOKEN (24h cache) ---
if [ -z "${GITLAB_TOKEN:-}" ]; then
  _gltoken_cache="$_gldir/glab_token"
  if [ -f "$_gltoken_cache" ] && [ "$(( $(command date +%s) - $(stat -c %Y "$_gltoken_cache") ))" -lt 86400 ]; then
    GITLAB_TOKEN=$(cat "$_gltoken_cache")
  elif [ -f "$HOME/.config/glab-cli/config.yml" ]; then
    # Extract token for the configured host from glab config file
    # Avoids calling glab auth status which may emit warnings when GITLAB_TOKEN isn't set
    # Extract just the hostname from GITLAB_HOST if it's a full URL (e.g. https://subsplash.io/ -> subsplash.io)
    _glhost="${GITLAB_HOST:-gitlab.com}"
    _glhost=$(printf '%s' "$_glhost" | sed 's#^https\?://##; s#/$##')
    GITLAB_TOKEN=$(sed -n "/${_glhost}:/,/^[^ ]/p" "$HOME/.config/glab-cli/config.yml" | grep "token:" | head -1 | awk '{print $2}')
    if [ -n "$GITLAB_TOKEN" ]; then
      mkdir -p "$_gldir"
      printf '%s' "$GITLAB_TOKEN" > "$_gltoken_cache"
    else
      echo "Warning: could not find GITLAB_TOKEN in glab config for host ${_glhost}" >&2
    fi
    unset _glhost
  fi
  [ -n "${GITLAB_TOKEN:-}" ] && export GITLAB_TOKEN
  unset _gltoken_cache
fi

unset _gldir
