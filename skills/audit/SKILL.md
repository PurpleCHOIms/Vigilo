---
name: smart-contract-audit
description: >
  This skill should be used when the user asks to "audit this smart contract",
  "check for vulnerabilities", "review this DeFi protocol", "analyze this Solidity code",
  "find security issues", "run security audit", or mentions "smart contract security",
  "vulnerability scan", "Code4rena audit", "security review". Provides comprehensive
  smart contract security auditing guidance for Solidity, Rust, Cairo, and Move.
---

# vigilo: Smart Contract Security Auditor

## Overview

vigilo is an AI-powered smart contract security audit system that operates in two phases:

| Phase | Focus | Output |
|-------|-------|--------|
| **Phase 1** | Reconnaissance (speed over depth) | `.vigilo/recon/` |
| **Phase 2** | Deep bug class analysis (parallel) | `.vigilo/findings/` |

## Quick Start

To begin an audit, run the `/vigilo:audit` command. This orchestrates:

1. **Phase 1**: doc-reader + code-analyzer agents gather intelligence
2. **Phase 1.5**: Select top 3 bug classes based on reconnaissance
3. **Phase 2**: 3 specialized auditors run in parallel
4. **Phase 3**: Generate consolidated Code4rena report

## Directory Structure

```
.vigilo/
├── notes/              # Phase 1 reconnaissance
│   ├── doc-findings.md
│   └── code-findings.md
├── findings/           # Phase 2 vulnerability reports
│   ├── high/
│   ├── medium/
│   ├── low/
│   └── qa/
└── reports/            # Final consolidated reports
```

## Bug Class Auditors

Four specialized auditors cover the top vulnerability categories:

| Auditor | Bug Class | Coverage |
|---------|-----------|----------|
| access-control-auditor | Privilege escalation, missing auth, role manipulation | High impact ($953M+) |
| logic-error-auditor | Business logic, calculation errors, input validation | Frequent (34.6%+) |
| state-interaction-auditor | Reentrancy, cross-contract state, callbacks, delegatecall | Critical ($35.7M+) |
| economic-attack-auditor | Flash loan, oracle manipulation, price manipulation, MEV | DeFi-specific ($33.8M+) |

## Bug Class Selection Guide

After Phase 1, select the 3 most relevant auditors based on codebase characteristics:

| Protocol Type | Recommended Auditors |
|---------------|---------------------|
| DeFi/AMM/DEX | economic-attack, state-interaction, logic-error |
| Governance/DAO | access-control, logic-error, state-interaction |
| Multi-contract | state-interaction, access-control, logic-error |
| Token/Vault | state-interaction, logic-error, economic-attack |
| Lending/Borrowing | economic-attack, logic-error, access-control |
| NFT/Gaming | access-control, logic-error, state-interaction |

## Attack Surface Markers

Flag these patterns during reconnaissance:

| Pattern | Risk Type | Priority |
|---------|-----------|----------|
| `external` + no modifier | Missing access control | High |
| `.call{value:` | Reentrancy risk | High |
| `delegatecall` | Upgrade/proxy risk | High |
| External oracle calls | Price manipulation | High |
| `block.timestamp` | Timestamp dependence | Medium |
| `tx.origin` | Phishing risk | Medium |
| Unchecked return values | Silent failures | Medium |

## Severity Classification (Code4rena)

| Severity | Criteria |
|----------|----------|
| **High** | Direct fund loss, significant protocol disruption |
| **Medium** | Limited fund loss, conditional exploits |
| **Low** | Best practices, minor issues |
| **QA** | Code quality, informational |

## Workflow Commands

| Command | Purpose |
|---------|---------|
| `/vigilo:audit` | Full audit (Phase 1 + 2 + Report) |
| `/vigilo:report` | Generate report from existing findings |

## Phase 1 Agents

### doc-reader
- Extracts protocol invariants and trust assumptions
- Reads documentation, README, NatSpec comments
- Output: `.vigilo/recon/doc-findings.md`

### code-analyzer
- Maps contract architecture and entry points
- Identifies attack surface markers
- Output: `.vigilo/recon/code-findings.md`

## Phase 2 Workflow

Each bug class auditor:
1. Reads Phase 1 data from `.vigilo/recon/`
2. Performs deep cross-contract analysis
3. Generates attack scenarios with PoC
4. Outputs Code4rena-formatted findings

## Finding Template

```markdown
# [H/M/L]-XX: Title

## Summary
[1-2 sentence description]

## Vulnerability Detail
[Root cause, code location with line numbers]

## Impact
[Likelihood + Impact = Severity]

## Attack Scenario
[Step-by-step exploitation]

## Proof of Concept
[Foundry test code]

## Recommended Mitigation
[Fixed code]
```

## Additional Resources

### Reference Files

For detailed guidance, consult:

- **`references/attack-patterns.md`** - Comprehensive attack patterns by bug class
- **`references/protocol-types.md`** - Protocol-specific audit strategies

### Language Support

| Language | Framework | LSP |
|----------|-----------|-----|
| Solidity | Foundry, Hardhat | vscode-solidity-server |
| Rust | Anchor, CosmWasm | rust-analyzer |
| Cairo | Starknet | cairo-language-server |
| Move | Aptos, Sui | aptos/sui-move-analyzer |

## Best Practices

1. **Read before analyzing** - Always read files before making judgments
2. **Document everything** - Write findings to files, not just responses
3. **Include line numbers** - Reference `file:line` for all findings
4. **Generate attack scenarios** - Concrete exploitation steps with PoC
5. **Quantify impact** - Estimate funds at risk, users affected
6. **Respect scope** - Only analyze specified files if scope is defined
