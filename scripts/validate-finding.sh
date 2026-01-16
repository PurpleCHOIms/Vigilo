#!/bin/bash
# vigilo finding validation hook (PreToolUse:Write)
# Validates that findings written to .vigilo/findings/ follow Code4rena format

set -euo pipefail

# Read input from stdin
input=$(cat)

# Extract file path from tool input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Skip if not writing to findings directory
if [[ ! "$file_path" == *".vigilo/findings/"* ]]; then
    exit 0
fi

# Extract content to validate
content=$(echo "$input" | jq -r '.tool_input.content // empty')

# Skip if no content
if [ -z "$content" ]; then
    exit 0
fi

# Validation checks
errors=""

# Check 1: Title format (e.g., # [H-01]: Title or # H-01: Title)
if ! echo "$content" | grep -qE "^#\s*\[?[HMLQhmlq]-?[0-9]+\]?:"; then
    errors="${errors}Missing severity-numbered title (e.g., '# [H-01]: Title'). "
fi

# Check 2: Required sections
required_sections=("Summary" "Vulnerability Detail" "Impact")
for section in "${required_sections[@]}"; do
    if ! echo "$content" | grep -qiE "^##\s*$section"; then
        errors="${errors}Missing '## $section' section. "
    fi
done

# Check 3: Code reference (file:line format)
if ! echo "$content" | grep -qE "[a-zA-Z0-9_/]+\.(sol|rs|cairo|move):[0-9]+"; then
    errors="${errors}Missing code reference (file.sol:123 format). "
fi

# Check 4: Severity classification consistency
filename=$(basename "$file_path")
dir_severity=$(echo "$file_path" | grep -oE "findings/(high|medium|low|qa)/" | cut -d'/' -f2)

if [ -n "$dir_severity" ]; then
    case "$dir_severity" in
        "high")
            if ! echo "$content" | grep -qiE "\[?H-?[0-9]+\]?:"; then
                errors="${errors}High severity finding should have H-XX title. "
            fi
            ;;
        "medium")
            if ! echo "$content" | grep -qiE "\[?M-?[0-9]+\]?:"; then
                errors="${errors}Medium severity finding should have M-XX title. "
            fi
            ;;
        "low")
            if ! echo "$content" | grep -qiE "\[?L-?[0-9]+\]?:"; then
                errors="${errors}Low severity finding should have L-XX title. "
            fi
            ;;
        "qa")
            if ! echo "$content" | grep -qiE "\[?Q-?[0-9]+\]?:"; then
                errors="${errors}QA finding should have Q-XX title. "
            fi
            ;;
    esac
fi

# Output result
if [ -n "$errors" ]; then
    # Return feedback to Claude (exit 2 feeds to Claude)
    echo "{\"systemMessage\": \"Finding format validation warnings: ${errors}Consider fixing before writing.\"}" >&2
    exit 2
fi

# All checks passed
exit 0
