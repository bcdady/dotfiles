#!/bin/bash
# Login to bitwarden CLI
test "$(command -v bw)" || (
    echo 'Bitwarden (bw command) Not Found'
    exit 5
)

# if BW_SESSION is Not set, run bw unlock
test "$(command -v bw)" && {
    BW_STATUS=$(bw status | jq .status)
    printf 'Bitwarden Status: %s\n' "${BW_STATUS}"

    echo "${BW_STATUS}" | grep -c "unlocked" >/dev/null 2>&1 || {
        echo ''
        echo 'Bitwarden Login'
        bw login
    }
}

# if BW_SESSION is Not set, run bw unlock
test -z "$BW_SESSION" && {
    echo ''
    echo 'Unlocking Bitwarden vault'
    echo '!!!'
    echo bw unlock # --passwordenv bwpswd | grep -B1 export
    echo '!!!'
    echo ''
    echo 'After setting BW_SESSION, run: `bw status | jq .status` to confirm vault is unlocked'
}
