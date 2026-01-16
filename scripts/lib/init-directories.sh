#!/bin/bash
# vigilo directory structure initialization

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

create_directories() {
    local base_dir="$(get_vigilo_root)"

    # Phase 1: Reconnaissance
    mkdir -p "$base_dir/recon"
    mkdir -p "$base_dir/notes"

    # Phase 2: Findings by severity
    mkdir -p "$base_dir/findings/high"
    mkdir -p "$base_dir/findings/medium"
    mkdir -p "$base_dir/findings/low"
    mkdir -p "$base_dir/findings/qa"

    # Reports
    mkdir -p "$base_dir/reports"

    # Metadata
    mkdir -p "$base_dir/.meta"

    log_info "Created .vigilo directory structure"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    create_directories
fi
