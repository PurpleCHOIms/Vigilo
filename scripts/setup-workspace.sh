#!/bin/bash
# vigilo workspace setup hook (SessionStart)
# Orchestrates workspace initialization using modular lib scripts

set -euo pipefail

# Get script directory and source lib modules
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

source "$LIB_DIR/common.sh"
source "$LIB_DIR/init-directories.sh"
source "$LIB_DIR/detect-project.sh"
source "$LIB_DIR/install-lsp.sh"
source "$LIB_DIR/check-scope.sh"
source "$LIB_DIR/load-context.sh"

# ============================================================
# Main Execution
# ============================================================

main() {
    log_cyan "=== vigilo Security Audit Framework ==="

    # 1. Create directories
    create_directories

    # 2. Detect project type
    local type_info
    type_info=$(detect_project_type)

    # 3. Persist environment
    persist_env "$type_info"

    # 4. Check scope file
    check_scope_file || true

    # 5. Check LSP status (installation skipped - must be done before Claude Code starts)
    # Note: LSP servers must be installed BEFORE starting Claude Code
    # See README.md for installation instructions
    if [ -z "${CI:-}" ] && [ -z "${vigilo_SKIP_LSP:-}" ]; then
        check_lsp_status "$type_info"
    fi

    # 6. Load previous context
    load_previous_context

    log_info "Ready for smart contract security audit"
}

# Run if not disabled
if [ -z "${vigilo_SKIP_SETUP:-}" ]; then
    main
fi

exit 0
