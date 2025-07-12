#!/bin/bash
# Script to ensure Bitwarden CLI is unlocked

set -e

# Lock file to prevent concurrent runs
LOCK_FILE="/tmp/bw_unlock.lock"
if [[ -f "$LOCK_FILE" ]]; then
    echo "Bitwarden unlock already in progress, waiting..."
    while [[ -f "$LOCK_FILE" ]]; do sleep 1; done
    # Check if we're now unlocked
    [[ -f ~/.bw_session ]] && source ~/.bw_session 2>/dev/null
    [[ "$(get_bw_status)" == "unlocked" ]] && { echo "✓ Bitwarden is ready"; exit 0; }
fi

# Create lock file
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Check if bw command exists
if ! command -v bw &>/dev/null; then
    echo "Error: Bitwarden CLI (bw command) not found. Install with: mise install bitwarden"
    exit 1
fi

# Check if jq exists (required for JSON parsing)
if ! command -v jq &>/dev/null; then
    echo "Error: jq command not found (required for JSON parsing)"
    echo "  (re)install jq by running 'mise use jq'"
    exit 1
fi

# Function to get current status
get_bw_status() {
    local status_json
    status_json=$(bw status 2>/dev/null || echo '{"status":"error"}')
    echo "$status_json" | jq -r .status
}

# Function to unlock vault
unlock_vault() {
    echo "Enter your master password to unlock the vault:"
    if BW_SESSION=$(bw unlock --raw); then
        # Write session to a secure temp file for other shells
        echo "export BW_SESSION='$BW_SESSION'" >~/.bw_session
        chmod 600 ~/.bw_session
        export BW_SESSION
        echo "✓ Bitwarden vault unlocked successfully"
        echo "Run 'source ~/.bw_session' in other shells to use the session"
        return 0
    else
        echo "✗ Failed to unlock Bitwarden vault"
        return 1
    fi
}

# Check for existing session first
if [[ -f ~/.bw_session ]]; then
    source ~/.bw_session 2>/dev/null || true
fi

echo "Checking Bitwarden status..."
BW_STATUS=$(get_bw_status)

case "$BW_STATUS" in
"unauthenticated")
    echo "Bitwarden is not logged in. Please log in first:"
    echo "Run: bw login"
    exit 2
    ;;
"locked")
    echo "Bitwarden vault is locked."
    unlock_vault || exit 3
    ;;
"unlocked")
    echo "✓ Bitwarden vault is already unlocked"
    ;;
"error")
    echo "Error: Unable to determine Bitwarden status"
    exit 4
    ;;
*)
    echo "Error: Unexpected Bitwarden status: $BW_STATUS"
    exit 5
    ;;
esac

# Final verification
if [ "$(get_bw_status)" != "unlocked" ]; then
    echo "✗ Bitwarden vault is still not unlocked"
    exit 6
fi

echo "✓ Bitwarden is ready to use"
rm -f "$LOCK_FILE"
