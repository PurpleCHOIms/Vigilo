---
name: poc
description: Generate and validate Foundry PoC from attack scenario document
argument-hint: <attack-scenario.md>
---

# /poc - PoC Generation & Validation

Generate Foundry PoC test code from an attack scenario document and validate it.

## Arguments

- `$ARGUMENTS` - Path to attack scenario document (e.g., `.vigilo/findings/high/reentrancy/H-01-vault-drain.md`)

## Your Task

Generate executable PoC code from the attack scenario and validate with Foundry.

**Use the `poc-generation` skill for templates and error patterns.**

### Step 1: Read Attack Scenario

```
Read("$ARGUMENTS")
```

Extract from the document:
- **Finding ID**: From filename or `# [H/M/L]-XX:` title pattern
- **Bug Class**: reentrancy, access-control, flash-loan, etc.
- **Code Location**: Target contract, function, line numbers
- **Preconditions**: Initial state, actor setup, funding requirements
- **Attack Steps**: Sequence of calls/operations
- **Expected Impact**: What the exploit achieves (fund drain, privilege escalation, etc.)

### Step 2: Identify Target Contracts

Read the vulnerable contract(s) mentioned in the finding:
```
Read("src/VulnerableContract.sol")  # Adjust path based on finding
```

Understand:
- Contract interface (function signatures)
- State variables involved
- Import dependencies

### Step 3: Generate PoC Code

Using `poc-generation` skill templates, generate the test file:

**Template Structure:**
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
// Import target contracts based on project structure

contract PoC_{FindingID} is Test {
    // Target contracts
    // VulnerableContract target;

    // Actors
    address attacker = address(0xBAD);
    address victim = address(0x1);

    function setUp() public {
        // Deploy contracts (from preconditions)
        // Fund actors (from preconditions)
        // Set initial state (from preconditions)
    }

    function test_Exploit_{FindingID}() public {
        // Record initial state
        uint256 attackerBalanceBefore = attacker.balance;

        // Execute attack (from attack steps)
        vm.startPrank(attacker);
        // ... map attack steps to code ...
        vm.stopPrank();

        // Verify impact (from expected impact)
        uint256 attackerBalanceAfter = attacker.balance;
        assertGt(attackerBalanceAfter, attackerBalanceBefore, "Exploit should profit");

        // Log results
        console.log("Profit:", (attackerBalanceAfter - attackerBalanceBefore) / 1e18, "ETH");
    }
}
```

**Bug Class Specific Patterns:**
- **Reentrancy**: Include attacker contract with `receive()` callback
- **Flash Loan**: Include `onFlashLoan` callback
- **Access Control**: Direct function call test
- **Input Validation**: Edge case input values
- **Logic Error**: State manipulation sequence

### Step 4: Write Test File

```
Write("test/poc/{finding-id}-{bug-class}.t.sol", generatedCode)
```

Naming convention:
- `H-01-reentrancy.t.sol`
- `M-03-access-control.t.sol`

### Step 5: Build and Run Test

**5.1 Check Dependencies**
```
Bash("ls lib/")
```

If `forge-std` missing:
```
Bash("forge install foundry-rs/forge-std --no-commit")
```

**5.2 Build Contracts**
```
Bash("forge build")
```

If build fails:
- Check Solidity version in `foundry.toml`
- Verify import paths match project structure
- Check `remappings.txt` for correct mappings

**5.3 Run Single Test** (CRITICAL - ONE FILE ONLY!)

**✅ CORRECT - Single file execution:**
```
Bash("forge test --match-path 'test/poc/H-01-*.t.sol' -vvv")
```

**Alternative - Match by test name:**
```
Bash("forge test --match-test test_Exploit_H01 -vvv")
```

**❌ WRONG - Never batch all PoCs:**
```
# DO NOT DO THIS
Bash("forge test --match-path 'test/poc/*.t.sol' -vvv")
```

**Why Single File?**
- One PoC = One finding = One test run
- Isolates failures for precise debugging
- Enables HITL decision per finding

### Step 6: Handle Failures (CRITICAL)

If test fails, analyze error and apply fixes:

**Compile Errors:**
| Error | Fix |
|-------|-----|
| `Source not found` | Fix import paths relative to project |
| `Member not found` | Read contract to verify function signature |
| `Type mismatch` | Add explicit cast |
| `Undeclared identifier` | Define interface inline |

**Runtime Errors:**
| Error | Fix |
|-------|-----|
| `Revert` | Add verbose `-vvvv` to see reason |
| `Insufficient funds` | Increase `vm.deal` amounts |
| `Unauthorized` | Check prank target address |
| `OutOfGas` | Increase gas limit |

**Assertion Failures:**
| Error | Fix |
|-------|-----|
| `Balance unchanged` | Verify attack logic matches scenario |
| `State not changed` | Check target contract reads |
| `Wrong profit` | Adjust attack parameters |

**Retry limit: 3 attempts**

After 3 failures, ask user how to proceed:

```json
AskUserQuestion({
  "questions": [{
    "question": "PoC for {finding_id} failed 3 times. Error: {error_type}. How should we proceed?",
    "header": "PoC Fail",
    "options": [
      { "label": "Debug with -vvvv", "description": "Run with maximum verbosity to analyze failure" },
      { "label": "Mark as NEEDS_REVIEW", "description": "Flag for manual review and continue" },
      { "label": "Skip this finding", "description": "Mark as INVALIDATED and move on" },
      { "label": "Modify approach", "description": "I'll provide guidance on how to fix the PoC" }
    ],
    "multiSelect": false
  }]
})
```

Based on user choice, proceed accordingly.

### Step 7: Report Result

Display final result:

```markdown
## PoC Validation Result

**Finding**: {finding-id}
**Status**: VALIDATED | INVALIDATED | NEEDS_REVIEW
**Test File**: test/poc/{finding-id}-{bug-class}.t.sol

### Test Output
{forge test output}

### Metrics (if applicable)
- Initial attacker balance: X ETH
- Final attacker balance: Y ETH
- Profit: Z ETH

### Notes
{Any observations or manual review notes}
```

## Status Definitions

| Status | Meaning |
|--------|---------|
| **VALIDATED** | PoC test passes, exploit confirmed |
| **INVALIDATED** | PoC fails after 3 retries, likely false positive |
| **NEEDS_REVIEW** | Complex scenario requiring manual review |

## Examples

### Example 1: Reentrancy Finding
```bash
/poc .vigilo/findings/high/reentrancy/H-01-vault-drain.md
```

### Example 2: Access Control Finding
```bash
/poc .vigilo/findings/high/access-control/H-02-missing-auth.md
```

### Example 3: Any Attack Scenario Document
```bash
/poc docs/attack-scenario.md
```

## Guidelines

1. **Read Before Generate**: Always read target contracts before generating PoC
2. **Match Attack Steps**: PoC code must follow the exact attack steps in the scenario
3. **Verify Impact**: Assertions should verify the claimed impact
4. **Preserve Evidence**: Log profit/impact metrics for report
5. **Document Failures**: If validation fails, document why in notes
6. **Use Skill Resources**: Refer to `poc-generation` skill for templates and error patterns
