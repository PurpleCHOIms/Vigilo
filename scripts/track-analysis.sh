#!/bin/bash
# vigilo analysis tracking hook (PostToolUse:Read)
# Tracks which contract files have been analyzed during audit

set -euo pipefail

# Read input from stdin
input=$(cat)

# Extract file path that was read
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Skip if no file path
if [ -z "$file_path" ]; then
    exit 0
fi

# Only track smart contract files
case "$file_path" in
    *.sol|*.rs|*.cairo|*.move)
        ;;
    *)
        exit 0
        ;;
esac

# Tracking file location
tracking_file="${CLAUDE_PROJECT_DIR:-.}/.vigilo/.meta/analyzed-files.txt"

# Ensure tracking directory exists
mkdir -p "$(dirname "$tracking_file")"

# Get timestamp
timestamp=$(date +"%Y-%m-%d %H:%M:%S")

# Append to tracking file (avoid duplicates for same file in same session)
if ! grep -qF "$file_path" "$tracking_file" 2>/dev/null; then
    echo "$timestamp | $file_path" >> "$tracking_file"
fi

# Success - no output needed
exit 0
