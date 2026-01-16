---
name: poc-generation
description: >
  This skill should be used when the user asks to "generate PoC", "validate attack scenario",
  "create exploit test from findings", "run Phase 2.5", "validate findings with PoC",
  or when Phase 2 auditors have completed and attack scenarios need validation with executable code.
  Reads attack scenarios from findings and generates Foundry PoC tests to validate exploitability.
version: 1.0.0
---

# PoC Generation & Validation

Generate and validate Foundry PoC tests from Phase 2 attack scenarios.

## Overview

After Phase 2 auditors generate attack scenarios, this skill transforms them into executable
Foundry tests to validate exploitability. Invalid findings are filtered out, strengthening
the final audit report.

**CRITICAL**: Generate and validate ONE PoC at a time, not in batch.

| Input | Process | Output |
|-------|---------|--------|
| Single attack scenario | Generate PoC → Run single test → Fix errors → Record result | ONE `test/poc/{id}.t.sol` + status |

## Core Principle: One PoC Per Scenario

```
❌ WRONG: Generate all PoCs → Run all tests → Handle all failures
✅ RIGHT: For each finding → Generate PoC → Run test → Handle result → Next
```

**Why Sequential?**
- Easier debugging per finding
- User can make decisions per finding (HITL)
- Clear validation status tracking
- Avoids cascading failures

## Workflow (Sequential)

### For Each Attack Scenario:

**Step 1: Read Single Finding**

Read the attack scenario document:
```
Read(".vigilo/findings/{severity}/{finding-id}.md")
```

Extract:
- Finding ID (e.g., H-01, M-03)
- Bug class (reentrancy, access-control, etc.)
- Attack scenario section
- Code location and vulnerable function

**Step 2: Generate Single PoC**

1. **Parse Attack Scenario**
   - Preconditions (attacker role, protocol state)
   - Attack steps (function calls, parameters)
   - Expected impact (funds drained, state corrupted)

2. **Generate Test Contract**
   - Use bug-class-specific template from `references/poc-templates.md`
   - Map attack steps to Foundry test code
   - Include appropriate cheatcodes (vm.prank, vm.deal, etc.)

3. **Write ONE test file**
   ```
   test/poc/{finding-id}-{bug-class}.t.sol
   ```

**Step 3: Run Single Test**

Execute ONLY this finding's test:

```bash
# ✅ Correct: Single file
forge test --match-path "test/poc/H-01-*.t.sol" -vvv

# ❌ Wrong: Batch all
# forge test --match-path "test/poc/*.t.sol" -vvv
```

### Step 4: Handle Failures (Critical)

For each failed test, analyze and fix:

| Error Type | Solution | Retry |
|------------|----------|-------|
| Compile Error | Fix imports, types, signatures | Yes |
| Assertion Failure | Adjust attack parameters | Yes (max 3) |
| Setup Failure | Fix deployment, funding | Yes |
| Logic Error | Re-read attack scenario | Yes |

**Retry limit: 3 attempts per finding**

After 3 failures, mark finding as `NEEDS_REVIEW` and document the issue.

### Step 5: Record Results

Update each finding with validation status:

| Status | Meaning |
|--------|---------|
| VALIDATED | PoC test passes, exploit confirmed |
| INVALIDATED | PoC fails after 3 retries, likely false positive |
| NEEDS_REVIEW | Complex scenario, manual review needed |

## PoC Validation Requirement (CRITICAL)

**PoC must PROVE the exploit works by demonstrating actual asset theft.**

```
❌ WRONG: Just call vulnerable function and check it doesn't revert
✅ RIGHT: Show attacker gains assets OR victim loses assets
```

### What Makes a Valid PoC?

| Validation Type | Assertion Example | When to Use |
|-----------------|-------------------|-------------|
| **Attacker Profit** | `assertGt(attackerAfter, attackerBefore)` | Fund drain, theft |
| **Victim Loss** | `assertLt(victimAfter, victimBefore)` | When attacker doesn't directly receive |
| **Protocol Insolvency** | `assertLt(protocolBalance, totalDeposits)` | Accounting manipulation |
| **Unauthorized State** | `assertTrue(attacker.hasRole(ADMIN))` | Privilege escalation |
| **Invariant Violation** | `assertLt(totalAssets, totalSupply)` | Share inflation |

### PoC Must Answer: "Did the attacker succeed?"

```solidity
// ❌ BAD: Just checks function call succeeds
function test_Bad_PoC() public {
    vm.prank(attacker);
    target.withdraw(amount);  // No validation!
}

// ✅ GOOD: Proves attacker actually stole funds
function test_Good_PoC() public {
    uint256 attackerBefore = token.balanceOf(attacker);
    uint256 victimBefore = token.balanceOf(address(target));

    vm.prank(attacker);
    target.withdraw(amount);

    uint256 attackerAfter = token.balanceOf(attacker);
    uint256 victimAfter = token.balanceOf(address(target));

    // PROVE the exploit
    assertGt(attackerAfter, attackerBefore, "Attacker should profit");
    assertLt(victimAfter, victimBefore, "Protocol should lose funds");

    // Log for evidence
    console.log("Stolen amount:", attackerAfter - attackerBefore);
}
```

## PoC Structure Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "forge-std/console.sol";
// Import target contracts

contract PoC_{FindingID} is Test {
    // Target contracts
    // Tokens involved

    // Actors
    address attacker = address(0xBAD);
    address victim = address(0x1);

    function setUp() public {
        // 1. Deploy contracts
        // 2. Fund actors (realistic amounts)
        // 3. Set initial state (from preconditions)
    }

    function test_Exploit_{FindingID}() public {
        // ========== 1. RECORD INITIAL STATE ==========
        uint256 attackerBalanceBefore = address(attacker).balance;
        uint256 attackerTokenBefore = token.balanceOf(attacker);
        uint256 protocolBalanceBefore = address(target).balance;

        console.log("=== Before Attack ===");
        console.log("Attacker ETH:", attackerBalanceBefore);
        console.log("Attacker Token:", attackerTokenBefore);
        console.log("Protocol Balance:", protocolBalanceBefore);

        // ========== 2. EXECUTE ATTACK ==========
        vm.startPrank(attacker);
        // ... attack steps from scenario ...
        vm.stopPrank();

        // ========== 3. RECORD FINAL STATE ==========
        uint256 attackerBalanceAfter = address(attacker).balance;
        uint256 attackerTokenAfter = token.balanceOf(attacker);
        uint256 protocolBalanceAfter = address(target).balance;

        console.log("=== After Attack ===");
        console.log("Attacker ETH:", attackerBalanceAfter);
        console.log("Attacker Token:", attackerTokenAfter);
        console.log("Protocol Balance:", protocolBalanceAfter);

        // ========== 4. VALIDATE EXPLOIT SUCCESS ==========
        // At least ONE of these must pass to prove exploit:

        // Option A: Attacker gained assets
        assertGt(attackerBalanceAfter, attackerBalanceBefore, "Attacker should profit ETH");
        // OR
        assertGt(attackerTokenAfter, attackerTokenBefore, "Attacker should profit tokens");

        // Option B: Protocol/Victim lost assets
        assertLt(protocolBalanceAfter, protocolBalanceBefore, "Protocol should lose funds");

        // ========== 5. LOG EVIDENCE ==========
        uint256 profit = attackerBalanceAfter - attackerBalanceBefore;
        console.log("=== EXPLOIT SUCCESSFUL ===");
        console.log("Profit:", profit);
    }
}
```

## Essential Cheatcodes

| Cheatcode | Purpose |
|-----------|---------|
| `vm.deal(addr, amt)` | Set ETH balance |
| `vm.prank(addr)` | Next call from addr |
| `vm.startPrank(addr)` / `vm.stopPrank()` | Multiple calls from addr |
| `vm.warp(timestamp)` | Set block.timestamp |
| `vm.roll(blockNum)` | Set block.number |
| `deal(token, addr, amt)` | Set ERC20 balance |
| `vm.expectRevert()` | Expect revert |

## Foundry Setup & Build

Before running PoC tests, ensure Foundry environment is ready:

### Step 1: Check Dependencies

```bash
# Verify lib/ exists (forge-std required)
ls lib/

# If missing, install forge-std
forge install foundry-rs/forge-std --no-commit
```

### Step 2: Check foundry.toml

Common issues to fix:
- Empty RPC URL: Comment out `eth_rpc_url = ""`
- Missing remappings: Check `remappings.txt` exists
- Invalid paths: Verify `libs` and `src` paths

### Step 3: Build Contracts

```bash
# Compile all contracts including PoC tests
forge build

# If build fails, check:
# 1. Solidity version compatibility
# 2. Import paths
# 3. Missing dependencies
```

### Step 4: Run Tests

```bash
# Run specific PoC
forge test --match-test test_Exploit_H01 -vvv

# Run all PoCs
forge test --match-path "test/poc/*.t.sol" -vvv

# Run with gas report
forge test --match-path "test/poc/*.t.sol" -vvv --gas-report

# Run on fork (requires RPC URL)
forge test --fork-url $ETH_RPC_URL --match-path "test/poc/*.t.sol" -vvv
```

## Validation Commands (Quick Reference)

```bash
# Full workflow
forge build && forge test --match-path "test/poc/*.t.sol" -vvv

# Debug failing test
forge test --match-test test_Exploit_H01 -vvvv
```

## Output Summary Format

After validation, generate summary:

```markdown
## PoC Validation Summary

| Finding | Status | Test File | Notes |
|---------|--------|-----------|-------|
| H-01 | VALIDATED | test/poc/H-01-reentrancy.t.sol | Exploit confirmed |
| H-02 | INVALIDATED | - | Attack requires impossible state |
| M-01 | VALIDATED | test/poc/M-01-access-control.t.sol | Confirmed |
| M-02 | NEEDS_REVIEW | test/poc/M-02-logic.t.sol | Complex oracle dependency |

**Validation Rate**: 3/4 (75%)
```

## Edge Cases

### Finding Without Attack Scenario
Skip findings that lack attack scenario section. Log warning and continue.

### Complex Multi-Transaction Attacks
Break into separate test functions if needed:
- `test_Exploit_Step1()`
- `test_Exploit_Step2()`
- `test_Exploit_FullChain()`

### External Dependencies (Oracles, DEXs)
Use fork testing or mock contracts:
```solidity
// Fork mainnet for real oracle data
vm.createSelectFork("mainnet", blockNumber);

// Or mock oracle
MockOracle oracle = new MockOracle();
oracle.setPrice(manipulatedPrice);
```

### Protocol-Specific Patterns
Consult `references/poc-templates.md` for bug-class-specific templates:
- Reentrancy: Attacker contract with receive()
- Flash Loan: onFlashLoan callback
- Access Control: Direct privilege escalation test

## Additional Resources

### Reference Files
- **`references/poc-templates.md`** - Detailed templates by bug class
- **`references/error-patterns.md`** - Common errors and fixes

### Related Skills
- **poc-testing** - Running and debugging PoC tests
- **audit** - Full audit workflow including this phase
