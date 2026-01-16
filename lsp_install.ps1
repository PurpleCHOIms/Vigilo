# Vigilo Development Tools Installation Script for Windows
# Run this BEFORE starting Claude Code to enable code intelligence and testing
#
# Usage:
#   .\lsp_install.ps1           # Install all supported LSP servers + Foundry
#   .\lsp_install.ps1 solidity  # Install only Solidity LSP
#   .\lsp_install.ps1 foundry   # Install only Foundry
#   .\lsp_install.ps1 status    # Check installation status

param(
    [Parameter(Position=0)]
    [string[]]$Languages = @()
)

$ErrorActionPreference = "Continue"

# Colors
function Write-Info { Write-Host "[INFO] $args" -ForegroundColor Cyan }
function Write-Success { Write-Host "[OK] $args" -ForegroundColor Green }
function Write-Warn { Write-Host "[WARN] $args" -ForegroundColor Yellow }
function Write-Err { Write-Host "[ERROR] $args" -ForegroundColor Red }

# ============================================================
# LSP Installation Functions
# ============================================================

function Install-SolidityLsp {
    Write-Host ""
    Write-Info "=== Solidity LSP (NomicFoundation) ==="

    $existing = Get-Command nomicfoundation-solidity-language-server -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Success "Already installed: $($existing.Source)"
        return $true
    }

    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npm) {
        Write-Err "npm not found. Install Node.js first: https://nodejs.org/"
        return $false
    }

    Write-Info "Installing via npm..."
    npm install -g @nomicfoundation/solidity-language-server
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Solidity LSP installed successfully"
        return $true
    } else {
        Write-Err "Failed to install Solidity LSP"
        return $false
    }
}

function Install-RustLsp {
    Write-Host ""
    Write-Info "=== Rust LSP (rust-analyzer) ==="

    $existing = Get-Command rust-analyzer -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Success "Already installed: $($existing.Source)"
        return $true
    }

    $rustup = Get-Command rustup -ErrorAction SilentlyContinue
    if ($rustup) {
        Write-Info "Installing via rustup..."
        rustup component add rust-analyzer
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Rust Analyzer installed successfully"
            return $true
        }
    }

    $cargo = Get-Command cargo -ErrorAction SilentlyContinue
    if ($cargo) {
        Write-Info "Installing via cargo..."
        cargo install rust-analyzer
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Rust Analyzer installed successfully"
            return $true
        }
    }

    Write-Err "Rust toolchain not found. Install Rust first: https://rustup.rs/"
    return $false
}

function Install-CairoLsp {
    Write-Host ""
    Write-Info "=== Cairo LSP (cairo-language-server) ==="

    $existing = Get-Command cairo-language-server -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Success "Already installed: $($existing.Source)"
        return $true
    }

    $scarb = Get-Command scarb -ErrorAction SilentlyContinue
    if ($scarb) {
        Write-Success "Cairo LSP available via Scarb: $($scarb.Source)"
        return $true
    }

    Write-Warn "Scarb not found. Install from: https://docs.swmansion.com/scarb/"
    return $false
}

function Install-GoLsp {
    Write-Host ""
    Write-Info "=== Go LSP (gopls) ==="

    $existing = Get-Command gopls -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Success "Already installed: $($existing.Source)"
        return $true
    }

    $go = Get-Command go -ErrorAction SilentlyContinue
    if (-not $go) {
        Write-Err "Go not found. Install from: https://go.dev/dl/"
        return $false
    }

    Write-Info "Installing via go install..."
    go install golang.org/x/tools/gopls@latest
    if ($LASTEXITCODE -eq 0) {
        Write-Success "gopls installed successfully"
        return $true
    } else {
        Write-Err "Failed to install gopls"
        return $false
    }
}

function Install-TypeScriptLsp {
    Write-Host ""
    Write-Info "=== TypeScript LSP (typescript-language-server) ==="

    $existing = Get-Command typescript-language-server -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Success "Already installed: $($existing.Source)"
        return $true
    }

    $npm = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $npm) {
        Write-Err "npm not found. Install Node.js first: https://nodejs.org/"
        return $false
    }

    Write-Info "Installing via npm..."
    npm install -g typescript-language-server typescript
    if ($LASTEXITCODE -eq 0) {
        Write-Success "TypeScript LSP installed successfully"
        return $true
    } else {
        Write-Err "Failed to install TypeScript LSP"
        return $false
    }
}

# ============================================================
# Foundry Installation (forge, cast, anvil)
# ============================================================

function Install-Foundry {
    Write-Host ""
    Write-Info "=== Foundry (forge, cast, anvil) ==="

    # Check if forge is already installed
    $forge = Get-Command forge -ErrorAction SilentlyContinue
    if ($forge) {
        Write-Success "Foundry already installed: $($forge.Source)"
        # Show version
        $version = forge --version 2>$null | Select-Object -First 1
        if ($version) {
            Write-Info "Version: $version"
        }
        return $true
    }

    # Check if foundryup exists
    $foundryup = Get-Command foundryup -ErrorAction SilentlyContinue
    if ($foundryup) {
        Write-Info "Running foundryup to install/update Foundry..."
        foundryup
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Foundry installed successfully"
            return $true
        } else {
            Write-Err "foundryup failed"
            return $false
        }
    }

    # Install foundryup first
    Write-Info "Installing foundryup..."

    # Windows installation via PowerShell
    try {
        # Download and run foundryup installer
        $env:FOUNDRY_DIR = "$env:USERPROFILE\.foundry"

        # Check if curl is available
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl) {
            Write-Info "Downloading foundryup installer..."
            $installerUrl = "https://foundry.paradigm.xyz"
            $tempScript = "$env:TEMP\foundryup_install.sh"

            # For Windows, we need to use the pre-built binaries directly
            Write-Info "Downloading Foundry binaries for Windows..."

            # Create .foundry\bin directory
            $foundryBin = "$env:USERPROFILE\.foundry\bin"
            if (-not (Test-Path $foundryBin)) {
                New-Item -ItemType Directory -Path $foundryBin -Force | Out-Null
            }

            # Download latest release
            $releases = Invoke-RestMethod -Uri "https://api.github.com/repos/foundry-rs/foundry/releases/latest"
            # Filter for Windows zip file only (exclude .attestation.txt and other files)
            $winAsset = $releases.assets | Where-Object {
                ($_.name -like "*win32*.zip" -or $_.name -like "*windows*.zip") -and
                $_.name -notlike "*.attestation*"
            } | Select-Object -First 1

            if ($winAsset) {
                Write-Info "Downloading: $($winAsset.name)"
                $zipPath = "$env:TEMP\foundry.zip"
                Invoke-WebRequest -Uri $winAsset.browser_download_url -OutFile $zipPath

                Write-Info "Extracting to $foundryBin..."
                Expand-Archive -Path $zipPath -DestinationPath $foundryBin -Force
                Remove-Item $zipPath -Force

                # Add to PATH for current session
                $env:PATH = "$foundryBin;$env:PATH"

                # Add to user PATH permanently
                $userPath = [Environment]::GetEnvironmentVariable("PATH", "User")
                if ($userPath -notlike "*$foundryBin*") {
                    [Environment]::SetEnvironmentVariable("PATH", "$foundryBin;$userPath", "User")
                    Write-Info "Added $foundryBin to user PATH"
                }

                Write-Success "Foundry installed successfully!"
                Write-Info "Tools installed: forge, cast, anvil, chisel"
                Write-Warn "Restart your terminal or run: `$env:PATH = `"$foundryBin;`$env:PATH`""
                return $true
            } else {
                Write-Err "Could not find Windows release"
                Write-Info "Try manual installation: https://book.getfoundry.sh/getting-started/installation"
                return $false
            }
        } else {
            Write-Err "curl not found"
            Write-Info "Install Foundry manually: https://book.getfoundry.sh/getting-started/installation"
            return $false
        }
    } catch {
        Write-Err "Failed to install Foundry: $_"
        Write-Info "Try manual installation: https://book.getfoundry.sh/getting-started/installation"
        return $false
    }
}

# ============================================================
# Status Check
# ============================================================

function Show-Status {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       Vigilo LSP Status Check     " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    $allOk = $true

    # Solidity
    if (Get-Command nomicfoundation-solidity-language-server -ErrorAction SilentlyContinue) {
        Write-Success "Solidity LSP: Installed (NomicFoundation)"
    } else {
        Write-Warn "Solidity LSP: Not installed"
        $allOk = $false
    }

    # Rust
    if (Get-Command rust-analyzer -ErrorAction SilentlyContinue) {
        Write-Success "Rust LSP: Installed"
    } else {
        Write-Warn "Rust LSP: Not installed"
        $allOk = $false
    }

    # Cairo
    if ((Get-Command cairo-language-server -ErrorAction SilentlyContinue) -or
        (Get-Command scarb -ErrorAction SilentlyContinue)) {
        Write-Success "Cairo LSP: Available"
    } else {
        Write-Warn "Cairo LSP: Not installed"
        $allOk = $false
    }

    # Go
    if (Get-Command gopls -ErrorAction SilentlyContinue) {
        Write-Success "Go LSP: Installed"
    } else {
        Write-Warn "Go LSP: Not installed"
        $allOk = $false
    }

    # TypeScript
    if (Get-Command typescript-language-server -ErrorAction SilentlyContinue) {
        Write-Success "TypeScript LSP: Installed"
    } else {
        Write-Warn "TypeScript LSP: Not installed"
        $allOk = $false
    }

    Write-Host ""
    Write-Host "--- Development Tools ---" -ForegroundColor Cyan

    # Foundry
    $forge = Get-Command forge -ErrorAction SilentlyContinue
    if ($forge) {
        Write-Success "Foundry: Installed"
        $version = forge --version 2>$null | Select-Object -First 1
        if ($version) { Write-Info "  $version" }
    } else {
        Write-Warn "Foundry: Not installed (required for PoC testing)"
        $allOk = $false
    }

    Write-Host ""
    if ($allOk) {
        Write-Success "All tools installed!"
    } else {
        Write-Warn "Some tools missing. Run '.\lsp_install.ps1' to install."
    }
}

# ============================================================
# Help
# ============================================================

function Show-Help {
    Write-Host "Vigilo Development Tools Installation Script"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\lsp_install.ps1              Install all LSP servers + Foundry"
    Write-Host "  .\lsp_install.ps1 [tool]       Install specific tool"
    Write-Host "  .\lsp_install.ps1 status       Check installation status"
    Write-Host ""
    Write-Host "LSP Servers:"
    Write-Host "  solidity    Solidity LSP (NomicFoundation)"
    Write-Host "  rust        Rust LSP (rust-analyzer)"
    Write-Host "  cairo       Cairo LSP (scarb)"
    Write-Host "  go          Go LSP (gopls)"
    Write-Host "  typescript  TypeScript LSP"
    Write-Host ""
    Write-Host "Development Tools:"
    Write-Host "  foundry     Foundry (forge, cast, anvil) - Required for PoC testing"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\lsp_install.ps1                  # Install all"
    Write-Host "  .\lsp_install.ps1 solidity foundry # Install Solidity LSP and Foundry"
    Write-Host "  .\lsp_install.ps1 foundry          # Install only Foundry"
    Write-Host "  .\lsp_install.ps1 status           # Check what's installed"
}

# ============================================================
# Main
# ============================================================

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "      Vigilo LSP Installer         " -ForegroundColor Cyan
Write-Host " Smart Contract Security Audit Framework" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

if ($Languages.Count -eq 0) {
    # Install primary smart contract LSPs + Foundry
    Install-SolidityLsp | Out-Null
    Install-RustLsp | Out-Null
    Install-CairoLsp | Out-Null
    Install-GoLsp | Out-Null
    Install-Foundry | Out-Null
    Write-Host ""
    Show-Status
} else {
    foreach ($lang in $Languages) {
        switch ($lang.ToLower()) {
            "solidity" { Install-SolidityLsp | Out-Null }
            "rust" { Install-RustLsp | Out-Null }
            "cairo" { Install-CairoLsp | Out-Null }
            "go" { Install-GoLsp | Out-Null }
            "typescript" { Install-TypeScriptLsp | Out-Null }
            "ts" { Install-TypeScriptLsp | Out-Null }
            "foundry" { Install-Foundry | Out-Null }
            "forge" { Install-Foundry | Out-Null }
            "status" { Show-Status }
            "help" { Show-Help }
            "-h" { Show-Help }
            "--help" { Show-Help }
            default {
                Write-Err "Unknown tool: $lang"
                Show-Help
                exit 1
            }
        }
    }
}

Write-Host ""
Write-Info "Installation complete. Restart Claude Code to use LSP features."
