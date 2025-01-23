// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/Faucet.sol"; // Adjust path based on your project structure

contract ETHFaucetTest is Test {
    ETHFaucet public faucet;
    address public owner = address(this); // Test contract will be the owner
    address public user1 = address(0x123);
    address public user2 = address(0x456);

    uint256 public allowedAmount = 0.01 ether;
    uint256 public waitTime = 1 hours;

    function setUp() public {
        // Deploy the faucet contract
        faucet = new ETHFaucet(allowedAmount, waitTime);

        // Fund the faucet with 10 ETH
        vm.deal(address(faucet), 10 ether);
    }

    function testInitialSetup() public view {
        assertEq(faucet.allowedAmount(), allowedAmount, "Incorrect allowed amount");
        assertEq(faucet.waitTime(), waitTime, "Incorrect wait time");
        assertEq(address(faucet).balance, 10 ether, "Incorrect initial balance");
    }

    function testFaucetClaimSuccess() public {
        vm.prank(user1); // Simulate `user1` calling the function
        faucet.claimETH();

        // Verify that user1 received the ETH
        assertEq(user1.balance, allowedAmount, "User1 did not receive correct ETH amount");

        // Verify the unlock time is updated
        uint256 expectedUnlockTime = block.timestamp + waitTime;
        assertEq(faucet.userUnlockTime(user1), expectedUnlockTime, "Incorrect unlock time");
    }

    function testFaucetClaimFailBeforeWaitTime() public {
        vm.prank(user1);
        faucet.claimETH();

        // Try to claim again before wait time has passed
        vm.expectRevert(abi.encodeWithSelector(ETHFaucet.AlreadyClaimed.selector, block.timestamp + waitTime));
        vm.prank(user1);
        faucet.claimETH();
    }

    function testFaucetClaimFailsWhenEmpty() public {
        // Drain the faucet
        uint256 faucetBalance = address(faucet).balance;
        vm.prank(user1);
        for (uint256 i = 0; i < faucetBalance / allowedAmount; i++) {
            faucet.claimETH();
        }

        // Try to claim with an empty faucet
        vm.expectRevert(ETHFaucet.InsufficientFunds.selector);
        vm.prank(user2);
        faucet.claimETH();
    }

    function testOwnerCanWithdrawFunds() public {
        uint256 withdrawAmount = 5 ether;
        faucet.withdraw(withdrawAmount);

        // Verify the faucet's balance is reduced
        assertEq(address(faucet).balance, 5 ether, "Incorrect faucet balance after withdraw");

        // Verify the owner's balance increased
        assertEq(owner.balance, withdrawAmount, "Owner did not receive the withdrawn amount");
    }

    function testNonOwnerCannotWithdrawFunds() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(user1);
        faucet.withdraw(1 ether);
    }

    function testSetAllowedAmount() public {
        uint256 newAllowedAmount = 0.02 ether;

        // Update allowed amount
        faucet.setAllowedAmount(newAllowedAmount);

        // Verify the new allowed amount
        assertEq(faucet.allowedAmount(), newAllowedAmount, "Allowed amount was not updated");
    }

    function testSetWaitTime() public {
        uint256 newWaitTime = 2 hours;

        // Update wait time
        faucet.setWaitTime(newWaitTime);

        // Verify the new wait time
        assertEq(faucet.waitTime(), newWaitTime, "Wait time was not updated");
    }

    function testFundsDepositedEvent() public {
        // Expect the `FundsDeposited` event
        vm.expectEmit(true, true, false, true);
        emit ETHFaucet.FundsDeposited(owner, 1 ether);

        // Deposit funds
        vm.deal(owner, 1 ether);
        (bool sent,) = address(faucet).call{value: 1 ether}("");
        require(sent, "Failed to deposit");
    }

    function testFaucetClaimedEvent() public {
        // Expect the `FaucetClaimed` event
        vm.expectEmit(true, true, false, true);
        emit ETHFaucet.FaucetClaimed(user1, allowedAmount, block.timestamp + waitTime);

        // User claims ETH
        vm.prank(user1);
        faucet.claimETH();
    }
}
