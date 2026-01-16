# Common PoC Errors and Fixes

Reference for diagnosing and fixing common errors in PoC test generation.

## Pre-Build Errors

### Invalid RPC URL

**Error**: `invalid provider URL: ""`
```
Error: invalid provider URL: ""
```

**Cause**: Empty `eth_rpc_url` in foundry.toml

**Fix**: Comment out the empty RPC URL
```toml
# foundry.toml
# eth_rpc_url = ""  # Comment out or remove
```

### Missing Dependencies

**Error**: `forge-std not found`
```
Error: Source "forge-std/Test.sol" not found
```

**Fix**: Install forge-std
```bash
forge install foundry-rs/forge-std --no-commit
```

### Remapping Issues

**Error**: `File not found` for library imports

**Fix**: Check remappings.txt exists and contains:
```
forge-std/=lib/forge-std/src/
```

Or add to foundry.toml:
```toml
remappings = ["forge-std/=lib/forge-std/src/"]
```

## Compilation Errors

### Import Errors

**Error**: `Source not found`
```
Error: Source "forge-std/Test.sol" not found
```

**Fix**: Ensure forge-std is installed
```bash
forge install foundry-rs/forge-std --no-commit
```

**Error**: `File not found`
```
Error: File "../src/Contract.sol" not found
```

**Fix**: Adjust import path to match project structure
```solidity
// Before
import "../src/Contract.sol";

// After (check actual path)
import "src/Contract.sol";
// or
import "contracts/Contract.sol";
```

### Type Errors

**Error**: `Type mismatch`
```
TypeError: Type uint256 is not implicitly convertible to expected type int256
```

**Fix**: Add explicit cast
```solidity
// Before
int256 value = someUint;

// After
int256 value = int256(someUint);
```

**Error**: `Interface mismatch`
```
TypeError: Member "withdraw" not found
```

**Fix**: Check actual function signature in target contract
```solidity
// Read contract to verify signature
// Maybe it's: withdraw(uint256 amount, address recipient)
// Not: withdraw(uint256 amount)
```

### Visibility Errors

**Error**: `Cannot access private/internal`
```
TypeError: Member "internalVar" is not visible
```

**Fix**: Use storage read cheatcode
```solidity
// Read private storage directly
bytes32 value = vm.load(address(target), SLOT_NUMBER);
```

### Interface Errors

**Error**: `Undeclared identifier`
```
DeclarationError: Undeclared identifier "ITarget"
```

**Fix**: Define interface inline
```solidity
interface ITarget {
    function vulnerableFunction(uint256 amount) external;
    function balanceOf(address) external view returns (uint256);
}
```

## Runtime Errors

### Revert Errors

**Error**: Unexpected revert
```
[FAIL] test_Exploit(): EvmError: Revert
```

**Diagnosis**: Add verbose flag to see revert reason
```bash
forge test --match-test test_Exploit -vvvv
```

**Common causes and fixes**:

1. **Insufficient funds**
```solidity
// Fix: Fund attacker before attack
vm.deal(attacker, 10 ether);
```

2. **Missing approval**
```solidity
// Fix: Approve before transfer
vm.prank(attacker);
token.approve(address(target), type(uint256).max);
```

3. **Access control**
```solidity
// Fix: Prank as authorized address
vm.prank(admin);
target.adminFunction();
```

4. **State precondition**
```solidity
// Fix: Setup required state first
target.initialize();
target.setState(requiredValue);
```

### Out of Gas

**Error**: `OutOfGas`
```
[FAIL] test_Exploit(): EvmError: OutOfGas
```

**Fix**: Increase gas limit
```bash
forge test --gas-limit 30000000 --match-test test_Exploit
```

Or in test:
```solidity
target.expensiveFunction{gas: 30_000_000}();
```

### Arithmetic Errors

**Error**: `Arithmetic over/underflow`
```
[FAIL] test_Exploit(): Arithmetic over/underflow
```

**Fix**: Use unchecked for intentional overflow testing
```solidity
unchecked {
    uint256 result = a - b; // Intentional underflow test
}
```

Or ensure proper bounds:
```solidity
// Ensure a >= b before subtraction
require(a >= b, "Would underflow");
uint256 result = a - b;
```

## Assertion Failures

### Balance Assertions

**Error**: `Assertion failed: Should profit`
```
[FAIL] test_Exploit(): Assertion failed
  Expected: attacker.balance > before
  Actual: attacker.balance == before
```

**Diagnosis steps**:

1. **Check attack actually executed**
```solidity
console.log("Attacker balance before:", attacker.balance);
// ... attack ...
console.log("Attacker balance after:", attacker.balance);
```

2. **Verify target has funds**
```solidity
console.log("Target balance:", address(target).balance);
require(address(target).balance > 0, "Target has no funds");
```

3. **Check attack parameters**
```solidity
// Maybe attack amount too small
target.withdraw(1 ether); // Try larger amount
```

### State Assertions

**Error**: State not changed
```
Assertion failed: State should be corrupted
```

**Fix**: Verify attack modifies expected state
```solidity
// Before attack
uint256 stateBefore = target.state();

// Attack
vm.prank(attacker);
target.exploit();

// After attack
uint256 stateAfter = target.state();
console.log("State changed from", stateBefore, "to", stateAfter);

assertNe(stateAfter, stateBefore, "State should change");
```

## Setup Failures

### Deployment Failures

**Error**: Contract deployment fails
```
[FAIL] setUp(): EvmError: Revert
```

**Fix**: Check constructor parameters
```solidity
// Verify constructor args
target = new VulnerableContract(
    validAddress,    // Not address(0)
    validAmount,     // Within expected range
    validToken       // Actual token address
);
```

### Fork Failures

**Error**: Fork RPC error
```
Error: Failed to create fork
```

**Fix**: Check RPC URL and block number
```solidity
// Use environment variable
vm.createSelectFork(vm.envString("ETH_RPC_URL"), 18000000);

// Or use known working RPC
vm.createSelectFork("https://eth.llamarpc.com", 18000000);
```

### Token Setup Failures

**Error**: Token balance not set
```
deal() failed
```

**Fix**: For tokens with custom balance storage
```solidity
// Standard deal
deal(address(token), attacker, 1000e18);

// If deal fails, find storage slot manually
// cast index address <attacker_address> <balance_mapping_slot>
bytes32 slot = keccak256(abi.encode(attacker, uint256(0))); // slot 0 for balanceOf
vm.store(address(token), slot, bytes32(uint256(1000e18)));
```

## Debugging Strategies

### Add Logging

```solidity
import "forge-std/console.sol";

function test_Exploit() public {
    console.log("=== Setup ===");
    console.log("Target balance:", address(target).balance);
    console.log("Attacker balance:", attacker.balance);

    console.log("=== Attack ===");
    vm.prank(attacker);
    target.exploit();

    console.log("=== Result ===");
    console.log("Target balance:", address(target).balance);
    console.log("Attacker balance:", attacker.balance);
}
```

### Use Verbose Traces

```bash
# Maximum verbosity
forge test --match-test test_Exploit -vvvvv

# Show gas for each call
forge test --match-test test_Exploit -vvv --gas-report
```

### Isolate Problem

```solidity
// Break complex attack into steps
function test_Step1_Setup() public {
    // Just test setup
}

function test_Step2_Deposit() public {
    // Test deposit works
}

function test_Step3_Attack() public {
    // Test attack logic
}

function test_FullExploit() public {
    // Full chain
}
```

### Storage Inspection

```solidity
// Read storage to verify state
bytes32 slot0 = vm.load(address(target), bytes32(0));
console.logBytes32(slot0);

// Find mapping slot
bytes32 balanceSlot = keccak256(abi.encode(attacker, uint256(2)));
bytes32 balance = vm.load(address(target), balanceSlot);
console.log("Balance slot value:", uint256(balance));
```

## Retry Decision Matrix

| Error Type | Retryable? | Action |
|------------|------------|--------|
| Import not found | Yes | Fix path |
| Type mismatch | Yes | Fix cast |
| Insufficient funds | Yes | Add vm.deal |
| Access denied | Yes | Add vm.prank |
| Function not found | Yes | Check interface |
| Logic doesn't match scenario | Yes (1x) | Re-read scenario |
| Attack scenario impossible | No | Mark INVALIDATED |
| Requires external state | No | Mark NEEDS_REVIEW |
| Complex oracle dependency | No | Mark NEEDS_REVIEW |

## Max Retry Strategy

```
Attempt 1: Fix obvious errors (imports, types, syntax)
Attempt 2: Fix runtime errors (funding, approvals, pranks)
Attempt 3: Re-analyze attack scenario and adjust parameters
Attempt 4+: Mark as NEEDS_REVIEW
```
