---
name: state-sync-analysis
description: >
  This skill should be used when the user asks to "check for reentrancy", "analyze state dependencies",
  "find read-only reentrancy", "check CEI pattern", "analyze callback risks", "find timing attacks",
  or when state-interaction-auditor needs to identify state inconsistency windows during external calls
  and construct exploitation scenarios for reentrancy and cross-contract state manipulation.
---

# State Sync Analysis Framework

## Purpose
**"When can state become inconsistent? How can that gap be exploited?"**

Identify state inconsistency windows that occur during external calls and analyze attack vectors.

---

## 1. State Synchronization Dependency Identification

### 1.1 Same-Contract State Dependencies
```solidity
// Dependencies between variables
uint256 totalSupply;       // A
uint256 totalAssets;       // B
// Invariant: B >= A * minRatio

// Risk: Inconsistency if A, B update order differs
```

### 1.2 Cross-Contract State Dependencies
```solidity
// Contract A depends on Contract B state
function getCollateralValue() external view returns (uint256) {
    return token.balanceOf(address(this)) * oracle.getPrice();
    //     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^   ^^^^^^^^^^^^^^^^
    //     Contract A state                   Contract B state (external)
}
```

### 1.3 View Function Dependencies
```solidity
// External protocol depends on our view function
function totalAssets() public view returns (uint256) {
    return s_depositedAssets + s_assetsInAMM;
}
// Other protocol: ourVault.totalAssets() to calculate collateral value
```

---

## 2. State Inconsistency Windows

### 2.1 State Before/After External Call
```
Time T0: Initial state
├── s_depositedAssets = 1000
├── s_assetsInAMM = 500
└── totalAssets() = 1500

Time T1: withdraw() called → state updated
├── s_depositedAssets -= 100  ← Updated
└── s_assetsInAMM = 500

Time T2: External call (token.safeTransfer)
└── ⚠️ Callback possible!

Time T2.5: During callback (inconsistency window)
├── s_depositedAssets = 900 (updated)
├── Actual tokens: Not yet transferred (1000)
└── totalAssets() = 900 + 500 = 1400 ← INCONSISTENT!
    (Actual: 1000 + 500 = 1500)

Time T3: Transfer complete
└── State consistency restored
```

### 2.2 Inconsistency Window Types

| Type | Description | Risk Level |
|------|-------------|------------|
| **Pre-Update** | External call before state update | Critical |
| **Partial Update** | External call after partial state update | High |
| **Post-Update** | External call after all state updates | Low |

### 2.3 CEI Pattern and Inconsistency
```solidity
// SAFE: Checks → Effects → Interactions
function withdraw(uint256 amount) external {
    // Checks
    require(balances[msg.sender] >= amount);

    // Effects (state updates first)
    balances[msg.sender] -= amount;
    totalAssets -= amount;

    // Interactions (external calls last)
    token.safeTransfer(msg.sender, amount);
}

// DANGER: Checks → Interactions → Effects
function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount);
    token.safeTransfer(msg.sender, amount);  // State inconsistent during callback
    balances[msg.sender] -= amount;          // Too late!
}
```

---

## 3. Timing Attack Analysis

### 3.1 Read-Only Reentrancy
```solidity
// Contract A (victim)
function totalAssets() public view returns (uint256) {
    return s_depositedAssets + s_assetsInAMM;
}

function withdraw(uint256 assets) external {
    s_depositedAssets -= assets;  // State updated

    // External call - callback occurs
    token.safeTransfer(msg.sender, assets);

    // During callback: totalAssets() call sees s_depositedAssets
    // already decreased but actual tokens not yet transferred
}

// Contract B (exploited by attacker)
function liquidate(address user) external {
    uint256 collateral = vaultA.totalAssets();  // Manipulated value!
    // If called during callback, gets lower collateral value than actual
}
```

### 3.2 Cross-Contract State Race
```solidity
// When two contracts depend on same state
// Contract A: uses oracle.getPrice()
// Contract B: uses oracle.getPrice()

// Attack:
// 1. Call A.function() → reads oracle → external call
// 2. In callback, manipulate oracle
// 3. Call B.function() → reads manipulated oracle
// 4. A.function() returns → already corrupted
```

### 3.3 Flash Loan Timing
```solidity
// State manipulation within single transaction
flashLoanProvider.flashLoan(amount)
    → onFlashLoan() callback
        → manipulate pool reserves
        → call vulnerable function (sees manipulated state)
        → restore reserves
    → repay flash loan
```

---

## 4. State Dependency Graph

### 4.1 Dependency Mapping Template
```
┌──────────────────────────────────────────────────┐
│              State Dependency Graph              │
├──────────────────────────────────────────────────┤
│                                                  │
│  ┌─────────┐      reads       ┌─────────────┐   │
│  │ Vault   │ ───────────────► │ Price Oracle │   │
│  │ .sol    │                  └─────────────┘   │
│  └────┬────┘                         ▲          │
│       │                              │ manipulate│
│       │ callback                     │          │
│       ▼                        ┌─────┴─────┐    │
│  ┌─────────┐      reads       │ Attacker  │    │
│  │ Token   │ ◄──────────────  │ Contract  │    │
│  │ .sol    │                  └───────────┘    │
│  └─────────┘                                    │
│                                                  │
│  Risk Path: Vault → callback → Attacker → Oracle│
│            → Vault reads manipulated Oracle     │
│                                                  │
└──────────────────────────────────────────────────┘
```

### 4.2 Inconsistency Scenario Table
| Scenario | Inconsistent State | Exploitation Method | Impact |
|----------|-------------------|-------------------|--------|
| withdraw callback | s_deposited decreased, tokens not transferred | totalAssets() manipulation | Collateral undervaluation |
| deposit ERC777 callback | tokens received, shares not minted | Reentrancy for duplicate mint | Share inflation |
| swap callback | reserves not yet updated | Price manipulation | Favorable price obtained |

---

## 5. Output Format

```markdown
## State Sync Analysis Results

### State Dependencies

| Contract | Function | Dependent State | External Source |
|----------|----------|-----------------|-----------------|
| Vault | getCollateralValue | totalAssets | Oracle.getPrice |
| Pool | swap | reserves | Token.balanceOf |

### Inconsistency Windows

| Location | Function | External Call | Inconsistent Variable | CEI Compliant |
|----------|----------|---------------|----------------------|---------------|
| Vault.sol:142 | withdraw | safeTransfer | s_deposited | ❌ |
| Pool.sol:89 | deposit | transferFrom | userShares | ⚠️ |

### Timing Attack Scenarios

#### Read-Only Reentrancy via totalAssets()
```
T0: Vault.withdraw(100) called
T1: s_depositedAssets = 1000 → 900
T2: token.safeTransfer() → callback
T3: [CALLBACK] ExternalProtocol.liquidate() called
    → Vault.totalAssets() = 900 + 500 = 1400 (actual: 1500)
    → Liquidation executed with incorrect collateral valuation
T4: Transfer complete
```

- **Impact**: Incorrect collateral valuation in external protocol
- **Risk Level**: High
- **Recommendation**: Use updateLock modifier or tstore

### Recommended Protections

1. **Enforce CEI Pattern**: All state updates → external calls
2. **Reentrancy Guard**: Apply nonReentrant modifier
3. **Read-Only Guard**: Add isUpdating check to view functions
4. **Transient Storage**: Use EIP-1153 tstore/tload
```

---

## 6. Agent Usage Guide

### Usage in state-interaction-auditor
```markdown
1. Identify external call points
2. Track state changes before/after calls
3. Analyze callback possibilities (ERC777, ERC1155, flash loan)
4. Identify inconsistency windows
5. Construct exploitation scenarios
```

### Applying Attacker Mindset
- "What state can be read during callbacks?"
- "If read state differs from actual, what can I gain?"
- "Does an external protocol trust our view functions?"

### Pattern Detection Queries
```
# State update after external call (DANGER)
Grep("transfer.*\\n.*=|-=|\\+=" glob="**/*.sol")

# Read-only risk view functions
Grep("view.*returns.*totalAssets|totalSupply", glob="**/*.sol")

# ERC777 callback reception
Grep("tokensReceived|IERC777", glob="**/*.sol")
```
