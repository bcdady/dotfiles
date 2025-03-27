#!/bin/bash
# Script to ensure Bitwarden CLI is unlocked

set -e

# Check if bw command exists
if ! command -v bw &>/dev/null; then
    echo "Error: Bitwarden CLI (bw command) not found"
    exit 1
fi

#  Checking Bitwarden status...
BW_STATUS_JSON=$(bw status 2>/dev/null || echo '{"status":"error"}')
BW_STATUS=$(echo "$BW_STATUS_JSON" | jq -r .status)
# echo "Bitwarden Status: \"$BW_STATUS\""

case "$BW_STATUS" in
"unauthenticated")
    echo "Bitwarden is not logged in. Attempting login..."
    if ! bw login; then
        echo "Error: Failed to log in to Bitwarden"
        exit 2
    fi
    # After login, we need to unlock
    echo "Login successful. Now unlocking..."
    if ! BW_SESSION=$(bw unlock --raw); then
        echo "Error: Failed to unlock Bitwarden vault"
        exit 3
    fi
    export BW_SESSION
    echo "Bitwarden vault unlocked successfully"
    ;;
"locked")
    echo "Bitwarden vault is locked. Unlocking..."
    if ! BW_SESSION=$(bw unlock --raw); then
        echo "Error: Failed to unlock Bitwarden vault"
        exit 3
    fi
    export BW_SESSION
    echo "Bitwarden vault unlocked successfully"
    ;;
"unlocked")
    echo "Bitwarden vault is unlocked"
    ;;
*)
    echo "Error: Unexpected Bitwarden status: $BW_STATUS"
    exit 4
    ;;
esac

# Verify we're now unlocked
BW_STATUS_JSON=$(bw status 2>/dev/null || echo '{"status":"error"}')
BW_STATUS=$(echo "$BW_STATUS_JSON" | jq -r .status)

if [ "$BW_STATUS" != "unlocked" ]; then
    echo "Error: Bitwarden vault is still not unlocked. Status: $BW_STATUS"
    exit 5
fi

# Bitwarden is ready to use
exit 0
