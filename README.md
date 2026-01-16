# Vigilo

AI-powered smart contract security reconnaissance and audit assistance for Solidity, Rust, Cairo, and Move.

## Features

- **Two-Phase Audit**: Phase 1 reconnaissance + Phase 2 deep vulnerability analysis
- **6 Bug Class Auditors**: Parallel analysis for comprehensive coverage
- **Code4rena Standard**: Industry-standard severity classification and report format
- **Cross-Contract Analysis**: Call Graph, State Flow, Trust Boundary analysis
- **Multi-Language Support**: Solidity, Rust (Anchor), Cairo (Starknet), Move (Aptos/Sui)
- **LSP Integration**: Code intelligence for supported languages

## Installation

### Option 1: Plugin Directory

```bash
claude --plugin-dir /path/to/claude-code-plugin
```

### Option 2: Project-Local

Copy to your project's `.claude-plugin/` directory:

```bash
cp -r claude-code-plugin /your/project/.claude-plugin/Vigilo
```

## Commands

| Command | Description |
|---------|-------------|
| `/Vigilo:recon` | Quick reconnaissance scan |
| `/Vigilo:audit [files]` | Full security audit (Phase 1 + Phase 2) |
| `/Vigilo:report [action]` | View and manage reports |

### Examples

```bash
# Quick recon on current project
/Vigilo:recon

# Full audit (runs Phase 1 + Phase 2)
/Vigilo:audit

# Audit specific files
/Vigilo:audit src/Pool.sol src/Token.sol

# List all reports
/Vigilo:report

# View specific report
/Vigilo:report findings/high/access-control/H-01.md
```

## Audit Workflow

```
/Vigilo:audit
    │
    ├── Phase 1: Reconnaissance
    │   ├── doc-reader ──────────┐
    │   └── code-analyzer ───────┼─→ .Vigilo/recon/
    │                            │
    │   [Wait for completion]    │
    │                            ▼
    └── Phase 2: Deep Analysis (6 Auditors in Parallel)
        ├── access-control-auditor ──┐
        ├── logic-error-auditor ─────┤
        ├── input-validation-auditor ┼─→ .Vigilo/findings/
        ├── reentrancy-auditor ──────┤
        ├── flash-loan-auditor ──────┤
        └── external-call-auditor ───┘
                    │
                    ▼
        .Vigilo/reports/{timestamp}_audit.md
```

## Agents

### Phase 1: Reconnaissance

| Agent | Model | Purpose |
|-------|-------|---------|
| `doc-reader` | haiku | Extract protocol invariants and trust assumptions from documentation |
| `code-analyzer` | haiku | Map contract architecture and identify attack surfaces |

### Phase 2: Deep Security Analysis

| Agent | Model | Bug Class | 2025 Stats |
|-------|-------|-----------|------------|
| `access-control-auditor` | sonnet | Access Control, Privilege Escalation | $953.2M losses |
| `logic-error-auditor` | sonnet | Business Logic, Calculation Errors | $63.8M+ losses |
| `input-validation-auditor` | sonnet | Input Validation, Parameter Checks | 34.6% frequency |
| `reentrancy-auditor` | sonnet | Reentrancy (all variants) | $35.7M losses |
| `flash-loan-auditor` | sonnet | Flash Loan, Oracle, Price Manipulation | $33.8M losses |
| `external-call-auditor` | sonnet | External Calls, Cross-Contract | 18% of vulns |

## Output Structure

```
.Vigilo/
├── recon/                    # Phase 1 reconnaissance
│   ├── doc-findings.md
│   └── code-findings.md
├── findings/                 # Phase 2 vulnerability findings
│   ├── high/
│   │   ├── access-control/
│   │   ├── reentrancy/
│   │   ├── flash-loan/
│   │   └── ...
│   ├── medium/
│   ├── low/
│   └── qa/
└── reports/                  # Integrated audit reports
    └── {timestamp}_audit.md
```

## Severity Classification (Code4rena Standard)

| Severity | Criteria |
|----------|----------|
| **High** | Direct fund loss, significant protocol disruption, privilege escalation |
| **Medium** | Limited fund loss, unintended behavior, conditional exploits |
| **Low** | Best practice violations, gas inefficiency, minor issues |
| **QA** | Code quality, documentation gaps, informational |

## Supported Frameworks

| Framework | Detection |
|-----------|-----------|
| Foundry | `foundry.toml` |
| Hardhat | `hardhat.config.js/ts` |
| Anchor (Solana) | `Anchor.toml` |
| Scarb (Cairo) | `Scarb.toml` |

## Prerequisites

> ⚠️ **Important**: Development tools must be installed BEFORE starting Claude Code.

### Quick Install (Recommended)

**Windows (PowerShell):**
```powershell
cd clients\claude-code-plugin
.\lsp_install.ps1          # Install all LSP servers + Foundry
.\lsp_install.ps1 status   # Check installation status
.\lsp_install.ps1 foundry  # Install only Foundry
```

**Linux/macOS:**
```bash
cd clients/claude-code-plugin
./lsp_install.sh          # Install all smart contract LSPs
./lsp_install.sh status   # Check installation status
```

## Foundry Integration (PoC Testing)

Foundry is required for executing Proof of Concept (PoC) code during security audits.

### What Foundry Provides

| Tool | Purpose |
|------|---------|
| `forge test` | Run PoC exploit tests |
| `forge build` | Compile contracts |
| `cast` | Interact with contracts/chains |
| `anvil` | Local Ethereum node for testing |

### PoC Workflow

During audits, the plugin can:
1. Generate PoC code based on discovered vulnerabilities
2. Run `forge test --match-test <poc_name>` to validate exploits
3. Report test results with impact analysis

### Example PoC Test

```solidity
// test/PoC_ReentrancyExploit.t.sol
contract PoCReentrancyTest is Test {
    function test_ReentrancyExploit() public {
        // Setup vulnerable contract
        VulnerableVault vault = new VulnerableVault();
        vault.deposit{value: 10 ether}();

        // Deploy attacker
        Attacker attacker = new Attacker(vault);
        attacker.attack{value: 1 ether}();

        // Verify exploit success
        assertGt(address(attacker).balance, 10 ether);
    }
}
```

Run with:
```bash
forge test --match-test test_ReentrancyExploit -vvv
```

## LSP Support

### Manual Installation

```bash
# Solidity (required for EVM audits) - NomicFoundation LSP (recommended)
npm install -g @nomicfoundation/solidity-language-server

# Rust (required for Solana/Anchor audits)
rustup component add rust-analyzer

# Cairo (required for Starknet audits)
# Install via https://docs.swmansion.com/scarb/
```

### Supported LSP Servers

| Language | Server | Install Command |
|----------|--------|-----------------|
| Solidity | `nomicfoundation-solidity-language-server` | `npm install -g @nomicfoundation/solidity-language-server` |
| Rust | `rust-analyzer` | `rustup component add rust-analyzer` |
| Go | `gopls` | `go install golang.org/x/tools/gopls@latest` |
| Cairo | `scarb` | [Scarb Installation](https://docs.swmansion.com/scarb/) |

> **Note**: The Solidity LSP server must be in your system PATH. After installation, restart your terminal or add npm's global bin directory to PATH.

### Verify Installation

**Windows (PowerShell):**
```powershell
nomicfoundation-solidity-language-server --version
rust-analyzer --version
```

**Linux/macOS:**
```bash
nomicfoundation-solidity-language-server --version
rust-analyzer --version
```

## Session Hooks

- **SessionStart**: Creates `.Vigilo/` directory structure
- **Stop**: Verifies audit completion before stopping
- **PreToolUse (Write)**: Validates finding format
- **PostToolUse (Read)**: Tracks analysis progress

> **Windows Note**: Hooks use bash scripts. Ensure Git Bash is installed and available in PATH.

## License

MIT
