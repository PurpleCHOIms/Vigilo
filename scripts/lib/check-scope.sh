#!/bin/bash
# vigilo scope file detection and validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

check_scope_file() {
    local project_dir="$(get_project_dir)"
    local scope_file="$project_dir/scope.txt"

    if [ -f "$scope_file" ]; then
        local file_count
        file_count=$(grep -v "^#" "$scope_file" | grep -v "^$" | wc -l || echo "0")
        log_info "Scope defined: $file_count files in scope.txt"

        # Copy scope to .vigilo for reference
        cp "$scope_file" "$(get_vigilo_root)/scope.txt" 2>/dev/null

        # Persist scope info
        if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
            echo "export vigilo_SCOPE_FILE=\"$scope_file\"" >> "$CLAUDE_ENV_FILE"
            echo "export vigilo_SCOPE_COUNT=\"$file_count\"" >> "$CLAUDE_ENV_FILE"
        fi

        return 0
    else
        log_warn "No scope.txt found in project root"
        log_warn "Create scope.txt with files to audit (one per line)"
        log_cyan "Example scope.txt:"
        log_cyan "  src/Pool.sol"
        log_cyan "  src/Token.sol"
        log_cyan "  # Comments start with #"
        return 1
    fi
}

# Get list of files in scope
get_scope_files() {
    local project_dir="$(get_project_dir)"
    local scope_file="$project_dir/scope.txt"

    if [ -f "$scope_file" ]; then
        grep -v "^#" "$scope_file" | grep -v "^$"
    fi
}

# Check if a file is in scope
is_in_scope() {
    local file="$1"
    local project_dir="$(get_project_dir)"
    local scope_file="$project_dir/scope.txt"

    if [ ! -f "$scope_file" ]; then
        # No scope file = everything in scope
        return 0
    fi

    # Normalize file path
    local normalized_file="${file#$project_dir/}"

    if grep -qF "$normalized_file" "$scope_file" 2>/dev/null; then
        return 0
    fi

    return 1
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-check}" in
        "check")
            check_scope_file
            ;;
        "list")
            get_scope_files
            ;;
        "is-in-scope")
            if [ -n "${2:-}" ]; then
                if is_in_scope "$2"; then
                    echo "In scope: $2"
                    exit 0
                else
                    echo "Not in scope: $2"
                    exit 1
                fi
            else
                echo "Usage: $0 is-in-scope <file_path>"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [check|list|is-in-scope <file>]"
            ;;
    esac
fi
