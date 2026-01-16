#!/bin/bash
# vigilo common utilities

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[vigilo]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[vigilo]${NC} $1"
}

log_error() {
    echo -e "${RED}[vigilo]${NC} $1"
}

log_cyan() {
    echo -e "${CYAN}[vigilo]${NC} $1"
}

# Get project directory
get_project_dir() {
    echo "${CLAUDE_PROJECT_DIR:-.}"
}

# Get vigilo root directory
get_vigilo_root() {
    echo "$(get_project_dir)/.vigilo"
}
