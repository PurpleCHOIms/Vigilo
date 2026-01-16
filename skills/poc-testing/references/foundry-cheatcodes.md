# Foundry Cheatcodes Reference

Complete reference for Foundry cheatcodes commonly used in PoC testing.

## Account Manipulation

### vm.deal
Set ETH balance for any address.
```solidity
vm.deal(address(target), 100 ether);
vm.deal(attacker, 1 ether);
```

### deal (ERC20)
Set ERC20 token balance (requires forge-std).
```solidity
deal(address(usdc), attacker, 1000000e6);  // 1M USDC
deal(address(weth), attacker, 100 ether);
```

### vm.prank
Execute next call as specified address.
```solidity
vm.prank(attacker);
target.withdraw(100 ether);  // Called as attacker
```

### vm.startPrank / vm.stopPrank
Execute multiple calls as specified address.
```solidity
vm.startPrank(attacker);
target.deposit{value: 1 ether}();
target.withdraw(1 ether);
target.exploit();
vm.stopPrank();
```

### vm.addr
Generate address from private key.
```solidity
uint256 privateKey = 0x1234;
address signer = vm.addr(privateKey);
```

## Time Manipulation

### vm.warp
Set block.timestamp.
```solidity
vm.warp(block.timestamp + 1 days);
vm.warp(1700000000);  // Specific timestamp
```

### vm.roll
Set block.number.
```solidity
vm.roll(block.number + 100);
vm.roll(18000000);  // Specific block
```

### skip
Advance time by duration.
```solidity
skip(1 days);
skip(1 hours);
```

### rewind
Go back in time.
```solidity
rewind(1 hours);
```

## Storage Manipulation

### vm.store
Write to storage slot.
```solidity
// Set storage slot 0 to value
vm.store(address(target), bytes32(0), bytes32(uint256(100)));

// Common pattern: find slot with cast
// cast index address <key> <slot>
```

### vm.load
Read from storage slot.
```solidity
bytes32 value = vm.load(address(target), bytes32(0));
```

## Transaction Context

### vm.fee
Set tx.gasprice.
```solidity
vm.fee(100 gwei);
```

### vm.txGasPrice
Set tx.gasprice for current transaction.
```solidity
vm.txGasPrice(100 gwei);
```

### vm.chainId
Set block.chainid.
```solidity
vm.chainId(1);  // Mainnet
vm.chainId(137);  // Polygon
```

## Expectations

### vm.expectRevert
Expect next call to revert.
```solidity
vm.expectRevert();
target.withdraw(type(uint256).max);

// With specific message
vm.expectRevert("Insufficient balance");
target.withdraw(100 ether);

// With custom error
vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector));
target.withdraw(100 ether);
```

### vm.expectEmit
Expect specific event.
```solidity
vm.expectEmit(true, true, false, true);
emit Transfer(from, to, amount);
target.transfer(to, amount);
```

### vm.expectCall
Expect specific external call.
```solidity
vm.expectCall(
    address(token),
    abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
);
target.withdraw(amount);
```

## Snapshots

### vm.snapshot
Create state snapshot.
```solidity
uint256 snapshot = vm.snapshot();
```

### vm.revertTo
Revert to snapshot.
```solidity
vm.revertTo(snapshot);
```

## Logging

### console.log
Log values during test.
```solidity
import "forge-std/console.sol";

console.log("Balance:", balance);
console.log("Address:", address(target));
console.log("Attack count:", attackCount);
```

### console2.log
Enhanced logging with format strings.
```solidity
import "forge-std/console2.sol";

console2.log("Balance: %s ETH", balance / 1e18);
```

## Fork Testing

### vm.createFork
Create fork from RPC.
```solidity
uint256 mainnetFork = vm.createFork("mainnet");
uint256 polygonFork = vm.createFork("polygon");
```

### vm.selectFork
Switch to fork.
```solidity
vm.selectFork(mainnetFork);
```

### vm.activeFork
Get current fork ID.
```solidity
uint256 currentFork = vm.activeFork();
```

### vm.rollFork
Roll fork to specific block.
```solidity
vm.rollFork(18000000);
```

## Signatures

### vm.sign
Sign message with private key.
```solidity
(uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, messageHash);
```

### vm.signP256
Sign with P256 curve (for EIP-7212).
```solidity
(bytes32 r, bytes32 s) = vm.signP256(privateKey, messageHash);
```

## Labels & Debugging

### vm.label
Label address for traces.
```solidity
vm.label(address(target), "VulnerableVault");
vm.label(attacker, "Attacker");
```

### vm.startBroadcast / vm.stopBroadcast
Record transactions for deployment.
```solidity
vm.startBroadcast(deployerPrivateKey);
new MyContract();
vm.stopBroadcast();
```

## Common PoC Patterns

### Setup Victim and Attacker
```solidity
function setUp() public {
    // Deploy target
    target = new VulnerableContract();

    // Label for better traces
    vm.label(address(target), "Target");
    vm.label(attacker, "Attacker");

    // Fund target (victim funds)
    vm.deal(address(target), 100 ether);

    // Fund attacker
    vm.deal(attacker, 1 ether);
}
```

### Execute as Attacker
```solidity
function test_Exploit() public {
    vm.startPrank(attacker);

    // All calls here are from attacker
    target.exploit();

    vm.stopPrank();
}
```

### Verify Profit
```solidity
function test_Exploit() public {
    uint256 before = attacker.balance;

    // ... exploit ...

    uint256 after = attacker.balance;
    uint256 profit = after - before;

    assertGt(profit, 0, "Should profit");
    console.log("Profit:", profit / 1e18, "ETH");
}
```

### Time-Based Exploit
```solidity
function test_Exploit_TimeDependent() public {
    // Warp past timelock
    vm.warp(block.timestamp + 7 days);

    // Now exploit is possible
    vm.prank(attacker);
    target.exploitAfterTimelock();
}
```

### Flash Loan Simulation
```solidity
function test_Exploit_FlashLoan() public {
    // Simulate flash loan by giving attacker temporary funds
    vm.deal(attacker, 1000000 ether);

    vm.startPrank(attacker);
    // Use funds for exploit
    // ...
    vm.stopPrank();
}
```
