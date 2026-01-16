#!/bin/bash
# vigilo previous audit context loading

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

load_previous_context() {
    local vigilo_root="$(get_vigilo_root)"
    local recon_dir="$vigilo_root/recon"
    local context=""

    # Check Phase 1 outputs
    if [ -f "$recon_dir/doc-findings.md" ]; then
        context="Phase 1 doc-findings exists. "
    fi

    if [ -f "$recon_dir/code-findings.md" ]; then
        context="${context}Phase 1 code-findings exists. "
    fi

    # Count existing findings
    local finding_count=0
    if [ -d "$vigilo_root/findings" ]; then
        finding_count=$(find "$vigilo_root/findings" -name "*.md" 2>/dev/null | wc -l || echo "0")
    fi

    if [ "$finding_count" -gt 0 ]; then
        context="${context}$finding_count existing findings."
    fi

    # Report status
    if [ -n "$context" ]; then
        log_cyan "Previous audit: $context"
    fi

    echo "$context"
}

# Get summary of previous audit
get_audit_summary() {
    local vigilo_root="$(get_vigilo_root)"
    local summary=""

    # Count findings by severity
    local high_count=0
    local medium_count=0
    local low_count=0
    local qa_count=0

    if [ -d "$vigilo_root/findings/high" ]; then
        high_count=$(find "$vigilo_root/findings/high" -name "*.md" 2>/dev/null | wc -l || echo "0")
    fi
    if [ -d "$vigilo_root/findings/medium" ]; then
        medium_count=$(find "$vigilo_root/findings/medium" -name "*.md" 2>/dev/null | wc -l || echo "0")
    fi
    if [ -d "$vigilo_root/findings/low" ]; then
        low_count=$(find "$vigilo_root/findings/low" -name "*.md" 2>/dev/null | wc -l || echo "0")
    fi
    if [ -d "$vigilo_root/findings/qa" ]; then
        qa_count=$(find "$vigilo_root/findings/qa" -name "*.md" 2>/dev/null | wc -l || echo "0")
    fi

    echo "Findings: High=$high_count, Medium=$medium_count, Low=$low_count, QA=$qa_count"
}

# Check if audit has started
is_audit_started() {
    local vigilo_root="$(get_vigilo_root)"

    if [ -d "$vigilo_root" ]; then
        return 0
    fi
    return 1
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-load}" in
        "load")
            load_previous_context
            ;;
        "summary")
            get_audit_summary
            ;;
        "started")
            if is_audit_started; then
                echo "Audit has started"
                exit 0
            else
                echo "No audit found"
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 [load|summary|started]"
            ;;
    esac
fi
