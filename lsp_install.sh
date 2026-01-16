#!/bin/bash
# Vigilo LSP Installation Script
# Run this BEFORE starting Claude Code to enable code intelligence
#
# Usage:
#   ./lsp_install.sh           # Install all supported LSP servers
#   ./lsp_install.sh solidity  # Install only Solidity LSP
#   ./lsp_install.sh rust      # Install only Rust LSP

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

log_info() { echo -e "${CYAN}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[OK]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# ============================================================
# LSP Installation Functions
# ============================================================

install_solidity_lsp() {
    echo ""
    log_info "=== Solidity LSP (vscode-solidity-server) ==="

    if command -v vscode-solidity-server &> /dev/null; then
        log_success "Already installed: $(which vscode-solidity-server)"
        return 0
    fi

    if ! command -v npm &> /dev/null; then
        log_error "npm not found. Install Node.js first: https://nodejs.org/"
        return 1
    fi

    log_info "Installing via npm..."
    if npm install -g @nomicfoundation/solidity-language-server; then
        log_success "Solidity LSP installed successfully"
    else
        log_error "Failed to install Solidity LSP"
        return 1
    fi
}

install_rust_lsp() {
    echo ""
    log_info "=== Rust LSP (rust-analyzer) ==="

    if command -v rust-analyzer &> /dev/null; then
        log_success "Already installed: $(which rust-analyzer)"
        return 0
    fi

    if command -v rustup &> /dev/null; then
        log_info "Installing via rustup..."
        if rustup component add rust-analyzer; then
            log_success "Rust Analyzer installed successfully"
            return 0
        fi
    fi

    if command -v cargo &> /dev/null; then
        log_info "Installing via cargo..."
        if cargo install rust-analyzer; then
            log_success "Rust Analyzer installed successfully"
            return 0
        fi
    fi

    log_error "Rust toolchain not found. Install Rust first: https://rustup.rs/"
    return 1
}

install_cairo_lsp() {
    echo ""
    log_info "=== Cairo LSP (cairo-language-server) ==="

    if command -v cairo-language-server &> /dev/null; then
        log_success "Already installed: $(which cairo-language-server)"
        return 0
    fi

    if command -v scarb &> /dev/null; then
        log_success "Cairo LSP available via Scarb: $(which scarb)"
        return 0
    fi

    log_warn "Scarb not found. Install from: https://docs.swmansion.com/scarb/"
    return 1
}

install_go_lsp() {
    echo ""
    log_info "=== Go LSP (gopls) ==="

    if command -v gopls &> /dev/null; then
        log_success "Already installed: $(which gopls)"
        return 0
    fi

    if ! command -v go &> /dev/null; then
        log_error "Go not found. Install from: https://go.dev/dl/"
        return 1
    fi

    log_info "Installing via go install..."
    if go install golang.org/x/tools/gopls@latest; then
        log_success "gopls installed successfully"
    else
        log_error "Failed to install gopls"
        return 1
    fi
}

install_typescript_lsp() {
    echo ""
    log_info "=== TypeScript LSP (typescript-language-server) ==="

    if command -v typescript-language-server &> /dev/null; then
        log_success "Already installed: $(which typescript-language-server)"
        return 0
    fi

    if ! command -v npm &> /dev/null; then
        log_error "npm not found. Install Node.js first: https://nodejs.org/"
        return 1
    fi

    log_info "Installing via npm..."
    if npm install -g typescript-language-server typescript; then
        log_success "TypeScript LSP installed successfully"
    else
        log_error "Failed to install TypeScript LSP"
        return 1
    fi
}

# ============================================================
# Status Check
# ============================================================

check_status() {
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║         Vigilo LSP Status Check            ║"
    echo "╚════════════════════════════════════════════════╝"
    echo ""

    local all_ok=true

    # Solidity
    if command -v vscode-solidity-server &> /dev/null; then
        log_success "Solidity LSP: Installed"
    else
        log_warn "Solidity LSP: Not installed"
        all_ok=false
    fi

    # Rust
    if command -v rust-analyzer &> /dev/null; then
        log_success "Rust LSP: Installed"
    else
        log_warn "Rust LSP: Not installed"
        all_ok=false
    fi

    # Cairo
    if command -v cairo-language-server &> /dev/null || command -v scarb &> /dev/null; then
        log_success "Cairo LSP: Available"
    else
        log_warn "Cairo LSP: Not installed"
        all_ok=false
    fi

    # Go
    if command -v gopls &> /dev/null; then
        log_success "Go LSP: Installed"
    else
        log_warn "Go LSP: Not installed"
        all_ok=false
    fi

    # TypeScript
    if command -v typescript-language-server &> /dev/null; then
        log_success "TypeScript LSP: Installed"
    else
        log_warn "TypeScript LSP: Not installed"
        all_ok=false
    fi

    echo ""
    if [ "$all_ok" = true ]; then
        log_success "All LSP servers installed!"
    else
        log_warn "Some LSP servers missing. Run './lsp_install.sh' to install."
    fi
}

# ============================================================
# Main
# ============================================================

show_help() {
    echo "Vigilo LSP Installation Script"
    echo ""
    echo "Usage:"
    echo "  ./lsp_install.sh              Install all LSP servers"
    echo "  ./lsp_install.sh [language]   Install specific LSP"
    echo "  ./lsp_install.sh status       Check installation status"
    echo ""
    echo "Languages:"
    echo "  solidity    Solidity LSP (vscode-solidity-server)"
    echo "  rust        Rust LSP (rust-analyzer)"
    echo "  cairo       Cairo LSP (scarb)"
    echo "  go          Go LSP (gopls)"
    echo "  typescript  TypeScript LSP"
    echo ""
    echo "Examples:"
    echo "  ./lsp_install.sh                # Install all"
    echo "  ./lsp_install.sh solidity rust  # Install Solidity and Rust only"
    echo "  ./lsp_install.sh status         # Check what's installed"
}

main() {
    echo ""
    echo "╔════════════════════════════════════════════════╗"
    echo "║        Vigilo LSP Installer                ║"
    echo "║   Smart Contract Security Audit Framework      ║"
    echo "╚════════════════════════════════════════════════╝"

    if [ $# -eq 0 ]; then
        # Install primary smart contract LSPs
        install_solidity_lsp || true
        install_rust_lsp || true
        install_cairo_lsp || true
        echo ""
        check_status
        return
    fi

    for arg in "$@"; do
        case "$arg" in
            solidity)
                install_solidity_lsp
                ;;
            rust)
                install_rust_lsp
                ;;
            cairo)
                install_cairo_lsp
                ;;
            go)
                install_go_lsp
                ;;
            typescript|ts)
                install_typescript_lsp
                ;;
            status)
                check_status
                ;;
            help|-h|--help)
                show_help
                ;;
            *)
                log_error "Unknown language: $arg"
                show_help
                exit 1
                ;;
        esac
    done

    echo ""
    log_info "Installation complete. Restart Claude Code to use LSP features."
}

main "$@"
