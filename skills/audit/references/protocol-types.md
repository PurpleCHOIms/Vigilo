# Protocol-Specific Audit Strategies

Audit strategies tailored to different protocol types.

---

## DEX / AMM Protocols

### Key Contracts
- Pool/Pair contracts
- Router contracts
- Factory contracts
- Fee collectors

### Priority Bug Classes
1. **flash-loan** - Price manipulation, sandwich attacks
2. **reentrancy** - Callback during swap
3. **input-validation** - Slippage, deadline checks

### Critical Functions
| Function | Risk Areas |
|----------|------------|
| `swap()` | Slippage, reentrancy, price calculation |
| `addLiquidity()` | First depositor attack, share calculation |
| `removeLiquidity()` | Reentrancy, minimum amounts |
| `flashLoan()` | Callback security, fee calculation |

### Common Vulnerabilities
- Missing slippage protection (amountOutMin = 0)
- Deadline bypass (deadline = block.timestamp)
- First depositor inflation attack
- Oracle manipulation via reserves
- Fee-on-transfer token handling

### Audit Checklist
- [ ] Slippage parameters enforced
- [ ] Deadline validated (> block.timestamp)
- [ ] K invariant maintained
- [ ] Reentrancy guards on swap
- [ ] Flash loan callback restrictions
- [ ] Fee-on-transfer token support

---

## Lending / Borrowing Protocols

### Key Contracts
- Lending Pool
- Interest Rate Model
- Price Oracle
- Liquidation Engine
- Collateral Manager

### Priority Bug Classes
1. **flash-loan** - Oracle manipulation, liquidation exploits
2. **logic-error** - Interest calculation, health factor
3. **access-control** - Liquidation permissions

### Critical Functions
| Function | Risk Areas |
|----------|------------|
| `deposit()` | Share calculation, first depositor |
| `borrow()` | Collateral valuation, health check |
| `repay()` | Interest calculation, rounding |
| `liquidate()` | Bad debt handling, incentives |
| `updatePrice()` | Oracle staleness, manipulation |

### Common Vulnerabilities
- Oracle price manipulation
- Interest rate model exploits
- Bad debt accumulation
- Liquidation front-running
- Flash loan + borrow attacks
- Collateral factor manipulation

### Audit Checklist
- [ ] TWAP oracle (not spot price)
- [ ] Staleness checks on oracle
- [ ] Interest accrual correct
- [ ] Liquidation incentives balanced
- [ ] Flash loan borrow restrictions
- [ ] Pause functionality exists

---

## Vault / Yield Protocols

### Key Contracts
- ERC4626 Vault
- Strategy contracts
- Reward distributors
- Fee managers

### Priority Bug Classes
1. **reentrancy** - Deposit/withdraw callbacks
2. **input-validation** - Share calculation, bounds
3. **logic-error** - Reward distribution, fees

### Critical Functions
| Function | Risk Areas |
|----------|------------|
| `deposit()` | Share inflation, first depositor |
| `withdraw()` | Reentrancy, share calculation |
| `harvest()` | Reward manipulation, MEV |
| `compound()` | Slippage, flash loan |

### Common Vulnerabilities
- First depositor share inflation
- Donation attacks
- Reward token flash manipulation
- Strategy migration issues
- Fee calculation errors
- Withdrawal queue attacks

### ERC4626 Specific Checks
```solidity
// Inflation attack protection
function _decimalsOffset() internal pure override returns (uint8) {
    return 3;  // Adds 1000 virtual shares
}

// Or minimum deposit
function deposit(uint256 assets) public override {
    require(assets >= MIN_DEPOSIT, "Too small");
    // ...
}
```

### Audit Checklist
- [ ] First depositor attack mitigated
- [ ] Share calculation uses proper rounding
- [ ] Reentrancy guards on deposit/withdraw
- [ ] Strategy can't drain vault
- [ ] Rewards distributed fairly
- [ ] Emergency withdrawal exists

---

## Governance / DAO Protocols

### Key Contracts
- Governor contract
- Timelock
- Token (voting power)
- Treasury

### Priority Bug Classes
1. **access-control** - Proposal/execution permissions
2. **logic-error** - Vote counting, quorum
3. **input-validation** - Proposal validation

### Critical Functions
| Function | Risk Areas |
|----------|------------|
| `propose()` | Threshold bypass, malicious actions |
| `vote()` | Flash loan voting, double voting |
| `execute()` | Timelock bypass, reentrancy |
| `cancel()` | Griefing, unauthorized cancel |

### Common Vulnerabilities
- Flash loan governance attacks
- Proposal spam/griefing
- Timelock bypass
- Vote manipulation
- Quorum manipulation
- Treasury drainage proposals

### Snapshot Voting Pattern
```solidity
// SECURE: Historical voting power
function vote(uint256 proposalId) external {
    uint256 snapshotBlock = proposals[proposalId].snapshotBlock;
    uint256 votes = token.getPastVotes(msg.sender, snapshotBlock);
    // ...
}
```

### Audit Checklist
- [ ] Snapshot-based voting (not current balance)
- [ ] Proposal threshold adequate
- [ ] Quorum requirements met
- [ ] Timelock delay sufficient
- [ ] Emergency actions have proper auth
- [ ] Treasury protected from malicious proposals

---

## Bridge Protocols

### Key Contracts
- Bridge contract
- Validator/Relayer contracts
- Message queue
- Token handlers

### Priority Bug Classes
1. **access-control** - Validator permissions
2. **external-call** - Cross-chain message handling
3. **input-validation** - Message validation

### Critical Functions
| Function | Risk Areas |
|----------|------------|
| `deposit()` | Token accounting, event emission |
| `withdraw()` | Signature validation, replay |
| `processMessage()` | Message verification, execution |
| `updateValidator()` | Validator takeover |

### Common Vulnerabilities
- Signature replay attacks
- Message forgery
- Validator collusion
- Event manipulation
- Cross-chain reentrancy
- Nonce handling issues

### Audit Checklist
- [ ] Signature includes chainId
- [ ] Nonce prevents replay
- [ ] Validator set properly managed
- [ ] Message hash includes all params
- [ ] Withdrawal limits exist
- [ ] Pause mechanism available

---

## NFT / Gaming Protocols

### Key Contracts
- NFT contracts (ERC721/ERC1155)
- Marketplace
- Game logic
- Randomness provider

### Priority Bug Classes
1. **access-control** - Mint permissions, admin functions
2. **input-validation** - Token ID validation, royalties
3. **logic-error** - Game mechanics, rewards

### Critical Functions
| Function | Risk Areas |
|----------|------------|
| `mint()` | Max supply, access control |
| `transfer()` | Approval logic, hooks |
| `list()` / `buy()` | Price manipulation, reentrancy |
| `reveal()` | Randomness manipulation |

### Common Vulnerabilities
- Unlimited minting
- Royalty bypass
- Metadata manipulation
- Randomness prediction
- Reentrancy in marketplace
- Front-running reveals

### Audit Checklist
- [ ] Max supply enforced
- [ ] Minting permissions correct
- [ ] Royalties enforced (ERC2981)
- [ ] Randomness from secure source (VRF)
- [ ] Marketplace reentrancy protected
- [ ] Metadata immutable or controlled

---

## Protocol Type Detection

### Signature Detection
| Protocol Type | Key Signatures |
|---------------|----------------|
| DEX/AMM | `swap`, `addLiquidity`, `removeLiquidity`, `getReserves` |
| Lending | `borrow`, `repay`, `liquidate`, `getHealthFactor` |
| Vault | `deposit`, `withdraw`, `totalAssets`, `convertToShares` |
| Governance | `propose`, `vote`, `execute`, `queue` |
| Bridge | `deposit`, `withdraw`, `processMessage`, `validateSignature` |
| NFT | `mint`, `tokenURI`, `royaltyInfo`, `safeMint` |

### Interface Detection
```solidity
// ERC4626 Vault
interface IERC4626 {
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
}

// Compound-style Lending
interface ICToken {
    function mint(uint256 mintAmount) external returns (uint256);
    function borrow(uint256 borrowAmount) external returns (uint256);
}

// Uniswap-style AMM
interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112, uint112, uint32);
}
```

---

## Cross-Protocol Interactions

### Integration Risk Matrix
| Caller | Target | Key Risks |
|--------|--------|-----------|
| Vault | DEX | Slippage, sandwich attacks |
| Lending | Oracle | Price manipulation |
| Bridge | Token | Non-standard tokens |
| Governance | Treasury | Malicious proposals |
| Any | Any | Reentrancy via callback |

### Common Integration Vulnerabilities
1. **Oracle Trust** - DEX prices are manipulable
2. **Token Assumptions** - Fee-on-transfer, rebasing
3. **Callback Risks** - Reentrancy from external protocols
4. **Upgrade Risks** - External protocol upgrades break integration
5. **Liquidity Assumptions** - Slippage in low liquidity
