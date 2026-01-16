#!/bin/bash
# vigilo project type detection

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

detect_project_type() {
    local project_dir="$(get_project_dir)"

    # Solidity (Foundry) - 87.45% TVL
    if [ -f "$project_dir/foundry.toml" ]; then
        echo "solidity:foundry"
        return
    fi

    # Solidity (Hardhat)
    if [ -f "$project_dir/hardhat.config.js" ] || [ -f "$project_dir/hardhat.config.ts" ]; then
        echo "solidity:hardhat"
        return
    fi

    # Rust (Anchor/Solana) - 2.31% TVL
    if [ -f "$project_dir/Anchor.toml" ]; then
        echo "rust:anchor"
        return
    fi

    # Rust (CosmWasm)
    if [ -f "$project_dir/Cargo.toml" ] && grep -q "cosmwasm" "$project_dir/Cargo.toml" 2>/dev/null; then
        echo "rust:cosmwasm"
        return
    fi

    # Cairo (Starknet) - 875% growth
    if [ -f "$project_dir/Scarb.toml" ]; then
        echo "cairo:scarb"
        return
    fi

    # Move (Aptos)
    if [ -f "$project_dir/Move.toml" ] && grep -qE "aptos|AptosFramework" "$project_dir/Move.toml" 2>/dev/null; then
        echo "move:aptos"
        return
    fi

    # Move (Sui)
    if [ -f "$project_dir/Move.toml" ] && grep -qE "sui|SuiFramework" "$project_dir/Move.toml" 2>/dev/null; then
        echo "move:sui"
        return
    fi

    # Move (Generic)
    if [ -f "$project_dir/Move.toml" ]; then
        echo "move:generic"
        return
    fi

    # Rust (Generic)
    if [ -f "$project_dir/Cargo.toml" ]; then
        echo "rust:cargo"
        return
    fi

    # Go
    if [ -f "$project_dir/go.mod" ]; then
        echo "go:go"
        return
    fi

    echo "unknown:unknown"
}

# Persist environment variables
persist_env() {
    local type_info="$1"
    local project_type="${type_info%%:*}"
    local framework="${type_info##*:}"

    if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
        {
            echo "export vigilo_PROJECT_TYPE=\"$project_type\""
            echo "export vigilo_FRAMEWORK=\"$framework\""
            echo "export vigilo_ROOT=\"$(get_vigilo_root)\""
        } >> "$CLAUDE_ENV_FILE"
    fi

    log_info "Detected: $project_type ($framework)"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    type_info=$(detect_project_type)
    persist_env "$type_info"
    echo "$type_info"
fi
