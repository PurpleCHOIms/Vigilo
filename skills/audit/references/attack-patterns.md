# Attack Patterns by Bug Class

Comprehensive attack patterns for each vulnerability category.

---

## Access Control Attacks

### Pattern 1: Missing Authorization
```solidity
// VULNERABLE
function withdraw(uint256 amount) external {
    token.transfer(msg.sender, amount);  // No auth check!
}

// SECURE
function withdraw(uint256 amount) external onlyOwner {
    token.transfer(msg.sender, amount);
}
```

### Pattern 2: Incorrect Modifier Logic
```solidity
// VULNERABLE
modifier onlyAdmin() {
    require(msg.sender == admin);
    _;  // Underscore AFTER checks
}

// Even worse - underscore before checks
modifier badModifier() {
    _;  // Code runs before check!
    require(msg.sender == admin);
}
```

### Pattern 3: Privilege Escalation via Proxy
```solidity
// VULNERABLE: Implementation can be called directly
function initialize(address _admin) external {
    admin = _admin;  // No initializer guard
}

// SECURE
function initialize(address _admin) external initializer {
    admin = _admin;
}
```

### Attack Scenario: Access Control Bypass
1. Attacker identifies unprotected admin function
2. Calls function directly (no modifier check)
3. Gains unauthorized privileges or drains funds

---

## Logic Error Attacks

### Pattern 1: Incorrect Calculation Order
```solidity
// VULNERABLE: Integer division truncation
function calculateReward(uint256 amount) returns (uint256) {
    return amount / totalSupply * rewardRate;  // Truncates to 0!
}

// SECURE: Multiply first
function calculateReward(uint256 amount) returns (uint256) {
    return amount * rewardRate / totalSupply;
}
```

### Pattern 2: Off-by-One Errors
```solidity
// VULNERABLE
for (uint i = 0; i <= users.length; i++) {  // Should be <
    process(users[i]);  // Array out of bounds on last iteration
}
```

### Pattern 3: State Machine Violations
```solidity
// VULNERABLE: Can finalize before deadline
function finalize() external {
    require(state == State.Active);  // Missing: block.timestamp > deadline
    state = State.Finalized;
}
```

### Attack Scenario: Precision Loss Exploit
1. Attacker deposits small amount repeatedly
2. Each deposit loses precision due to division-before-multiplication
3. Over many iterations, attacker extracts value from rounding errors

---

## Input Validation Attacks

### Pattern 1: Missing Zero-Address Check
```solidity
// VULNERABLE
function setRecipient(address _recipient) external {
    recipient = _recipient;  // Can be address(0), locking funds
}

// SECURE
function setRecipient(address _recipient) external {
    require(_recipient != address(0), "Zero address");
    recipient = _recipient;
}
```

### Pattern 2: Unbounded Array Input
```solidity
// VULNERABLE: DoS via gas exhaustion
function processAll(address[] calldata users) external {
    for (uint i = 0; i < users.length; i++) {
        process(users[i]);  // Attacker passes huge array
    }
}

// SECURE
function processAll(address[] calldata users) external {
    require(users.length <= MAX_BATCH, "Too many");
    // ...
}
```

### Pattern 3: Missing Slippage Protection
```solidity
// VULNERABLE
function swap(uint256 amountIn) external {
    router.swap(amountIn, 0, path);  // amountOutMin = 0
}

// SECURE
function swap(uint256 amountIn, uint256 minOut) external {
    require(minOut > 0, "Invalid slippage");
    router.swap(amountIn, minOut, path);
}
```

### Attack Scenario: Sandwich Attack
1. Attacker sees victim's swap with no slippage protection
2. Front-runs with large buy, moving price up
3. Victim's swap executes at inflated price
4. Attacker back-runs with sell, profiting from spread

---

## Reentrancy Attacks

### Pattern 1: Classic Reentrancy
```solidity
// VULNERABLE
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount);
    (bool success,) = msg.sender.call{value: amount}("");  // External call
    require(success);
    balances[msg.sender] -= amount;  // State update AFTER call
}

// SECURE (CEI pattern)
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;  // State update BEFORE call
    (bool success,) = msg.sender.call{value: amount}("");
    require(success);
}
```

### Pattern 2: Cross-Function Reentrancy
```solidity
// VULNERABLE: Attacker calls transfer() during withdraw()
function withdraw() external {
    uint256 amount = balances[msg.sender];
    (bool success,) = msg.sender.call{value: amount}("");
    // Attacker's receive() calls transfer() before this executes
    balances[msg.sender] = 0;
}

function transfer(address to, uint256 amount) external {
    require(balances[msg.sender] >= amount);
    balances[msg.sender] -= amount;
    balances[to] += amount;
}
```

### Pattern 3: Read-Only Reentrancy
```solidity
// VULNERABLE: Price oracle reads stale state during callback
function getPrice() external view returns (uint256) {
    return totalAssets / totalShares;  // Stale during deposit callback
}

function deposit() external {
    // totalAssets updated AFTER external call
    token.transferFrom(msg.sender, address(this), amount);
    // Attacker's callback reads getPrice() with old totalAssets
    totalShares += shares;
    totalAssets += amount;
}
```

### Attack Scenario: Cross-Contract Reentrancy
1. ContractA calls ContractB with external call
2. ContractB calls back to ContractA before A's state is updated
3. ContractA's function sees stale state, allows double-spend

---

## Flash Loan Attacks

### Pattern 1: Oracle Price Manipulation
```solidity
// VULNERABLE: Spot price oracle
function getPrice() external view returns (uint256) {
    return reserve1 / reserve0;  // Manipulable in same block
}

// SECURE: TWAP oracle
function getPrice() external view returns (uint256) {
    return twapOracle.consult(token, period);
}
```

### Pattern 2: Governance Token Flash Loan
```solidity
// VULNERABLE: Voting power from current balance
function vote(uint256 proposalId) external {
    uint256 votes = token.balanceOf(msg.sender);  // Flash borrowed tokens
    proposals[proposalId].votes += votes;
}

// SECURE: Snapshot-based voting
function vote(uint256 proposalId) external {
    uint256 votes = token.getPastVotes(msg.sender, snapshotBlock);
    proposals[proposalId].votes += votes;
}
```

### Pattern 3: Collateral Manipulation
```solidity
// VULNERABLE: Instant collateral valuation
function borrow(uint256 amount) external {
    uint256 collateralValue = getCollateralValue(msg.sender);
    require(collateralValue >= amount * 150 / 100);
    // Attacker inflates collateral value with flash loan
}
```

### Attack Scenario: Flash Loan Price Manipulation
1. Attacker takes flash loan of TokenA
2. Swaps TokenA for TokenB, crashing TokenA price on DEX
3. Protocol uses DEX as oracle, sees crashed TokenA price
4. Attacker liquidates positions or borrows against manipulated price
5. Repays flash loan with profit

---

## External Call Attacks

### Pattern 1: Unchecked Return Value
```solidity
// VULNERABLE
function withdraw(address token, uint256 amount) external {
    IERC20(token).transfer(msg.sender, amount);  // Return ignored
}

// SECURE
function withdraw(address token, uint256 amount) external {
    bool success = IERC20(token).transfer(msg.sender, amount);
    require(success, "Transfer failed");
}

// BETTER: SafeERC20
function withdraw(address token, uint256 amount) external {
    IERC20(token).safeTransfer(msg.sender, amount);
}
```

### Pattern 2: Dangerous delegatecall
```solidity
// VULNERABLE: delegatecall to user-controlled address
function execute(address target, bytes calldata data) external {
    target.delegatecall(data);  // Attacker controls target
}

// Attacker deploys malicious contract:
contract Malicious {
    function attack() external {
        // Runs in context of victim, can modify storage
        selfdestruct(payable(attacker));
    }
}
```

### Pattern 3: Callback Injection
```solidity
// VULNERABLE: Trusts callback data
function onFlashLoan(
    address initiator,
    uint256 amount,
    bytes calldata data
) external returns (bytes32) {
    (address target, bytes memory callData) = abi.decode(data, (address, bytes));
    target.call(callData);  // Arbitrary call from callback
}
```

### Attack Scenario: Storage Collision via Delegatecall
1. Proxy contract uses delegatecall to implementation
2. Attacker finds way to change implementation address
3. Deploys malicious implementation with same storage layout
4. Malicious code modifies proxy's storage (owner, balances)

---

## Cross-Contract Analysis Patterns

### Call Graph Analysis
```
User -> ContractA.deposit()
         -> ContractB.stake()
            -> ContractC.mint()
               -> [External Protocol]
```

Key questions:
- Where does user input flow?
- What external calls happen?
- Which state changes occur?

### Trust Boundary Mapping
```
[UNTRUSTED]     [VALIDATION]     [TRUSTED]        [EXTERNAL]
User Input  ->  require()    ->  Internal  ->    Protocol
msg.sender      modifiers        Functions        Calls
calldata        checks           Storage          Oracles
```

Key questions:
- Where is input validated?
- Are trust assumptions documented?
- Can trusted state be corrupted?

### State Flow Analysis
```
deposit(amount)
  -> balances[user] += amount     [STATE CHANGE]
  -> totalSupply += amount        [STATE CHANGE]
  -> emit Deposit(user, amount)   [EVENT]
  -> externalCall()               [EXTERNAL - REENTRANCY RISK]
```

Key questions:
- Does state update before or after external calls?
- Can state be read during callback?
- Are events emitted at correct time?
