#!/bin/bash
# vigilo LSP server installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Solidity LSP (vscode-solidity via npm)
install_solidity_lsp() {
    if command -v vscode-solidity-server &> /dev/null; then
        log_info "Solidity LSP already installed"
        return 0
    fi

    if command -v npm &> /dev/null; then
        log_info "Installing Solidity LSP server..."
        npm install -g vscode-solidity-server 2>/dev/null && \
            log_info "Solidity LSP installed" || \
            log_warn "Failed to install Solidity LSP"
    else
        log_warn "npm not found. Install Node.js: https://nodejs.org/"
    fi
}

# Rust LSP (rust-analyzer)
install_rust_lsp() {
    if command -v rust-analyzer &> /dev/null; then
        log_info "Rust Analyzer already installed"
        return 0
    fi

    if command -v rustup &> /dev/null; then
        log_info "Installing Rust Analyzer via rustup..."
        rustup component add rust-analyzer 2>/dev/null && \
            log_info "Rust Analyzer installed" || \
            log_warn "Failed to install rust-analyzer via rustup"
    elif command -v cargo &> /dev/null; then
        log_info "Installing Rust Analyzer via cargo..."
        cargo install rust-analyzer 2>/dev/null && \
            log_info "Rust Analyzer installed" || \
            log_warn "Failed to install rust-analyzer"
    else
        log_warn "Rustup not found. Install Rust: https://rustup.rs/"
    fi
}

# Cairo LSP (cairo-language-server via scarb)
install_cairo_lsp() {
    if command -v cairo-language-server &> /dev/null; then
        log_info "Cairo LSP already installed"
        return 0
    fi

    if command -v scarb &> /dev/null; then
        log_info "Cairo LSP available via Scarb"
        return 0
    else
        log_warn "Scarb not found. Install: https://docs.swmansion.com/scarb/"
    fi
}

# Move LSP (Aptos)
install_aptos_lsp() {
    if command -v aptos-move-analyzer &> /dev/null; then
        log_info "Aptos Move Analyzer already installed"
        return 0
    fi

    if command -v cargo &> /dev/null; then
        log_info "Installing Aptos Move Analyzer..."
        cargo install --git https://github.com/aptos-labs/aptos-core aptos-move-analyzer 2>/dev/null && \
            log_info "Aptos Move Analyzer installed" || \
            log_warn "Failed to install aptos-move-analyzer"
    else
        log_warn "Cargo not found. Install Rust first."
    fi
}

# Move LSP (Sui)
install_sui_lsp() {
    if command -v sui-move-analyzer &> /dev/null; then
        log_info "Sui Move Analyzer already installed"
        return 0
    fi

    if command -v cargo &> /dev/null; then
        log_info "Installing Sui Move Analyzer..."
        cargo install --git https://github.com/MystenLabs/sui sui-move-analyzer 2>/dev/null && \
            log_info "Sui Move Analyzer installed" || \
            log_warn "Failed to install sui-move-analyzer"
    else
        log_warn "Cargo not found. Install Rust first."
    fi
}

# Go LSP (gopls)
install_go_lsp() {
    if command -v gopls &> /dev/null; then
        log_info "Go LSP (gopls) already installed"
        return 0
    fi

    if command -v go &> /dev/null; then
        log_info "Installing Go LSP (gopls)..."
        go install golang.org/x/tools/gopls@latest 2>/dev/null && \
            log_info "gopls installed" || \
            log_warn "Failed to install gopls"
    else
        log_warn "Go not found. Install Go: https://go.dev/dl/"
    fi
}

# Check LSP status (does NOT install - just reports)
check_lsp_status() {
    local type_info="$1"
    local project_type="${type_info%%:*}"

    local lsp_needed=""
    local lsp_installed=true

    case "$project_type" in
        "solidity")
            lsp_needed="vscode-solidity-server"
            command -v vscode-solidity-server &> /dev/null || lsp_installed=false
            ;;
        "rust")
            lsp_needed="rust-analyzer"
            command -v rust-analyzer &> /dev/null || lsp_installed=false
            ;;
        "cairo")
            lsp_needed="cairo-language-server or scarb"
            command -v cairo-language-server &> /dev/null || command -v scarb &> /dev/null || lsp_installed=false
            ;;
        *)
            return 0
            ;;
    esac

    if [ "$lsp_installed" = true ]; then
        log_info "LSP ($lsp_needed): ✓ Installed"
    else
        log_warn "LSP ($lsp_needed): ✗ Not installed"
        log_warn "Install before starting Claude Code for code intelligence"
    fi
}

# Install LSP based on detected project type
install_lsp_for_project() {
    local type_info="$1"
    local project_type="${type_info%%:*}"
    local framework="${type_info##*:}"

    case "$project_type" in
        "solidity")
            install_solidity_lsp
            ;;
        "rust")
            install_rust_lsp
            ;;
        "cairo")
            install_cairo_lsp
            ;;
        "move")
            case "$framework" in
                "aptos")
                    install_aptos_lsp
                    ;;
                "sui")
                    install_sui_lsp
                    ;;
                *)
                    log_info "Generic Move project - install LSP manually"
                    ;;
            esac
            ;;
        "go")
            install_go_lsp
            ;;
        *)
            log_info "No specific LSP required for this project type"
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [ -n "${1:-}" ]; then
        install_lsp_for_project "$1"
    else
        echo "Usage: $0 <project_type:framework>"
        echo "Example: $0 solidity:foundry"
    fi
fi
