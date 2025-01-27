// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Test} from "forge-std/Test.sol";
import {ETHFaucet} from "src/Faucet.sol";
import "forge-std/console.sol";

contract ETHFaucetTest is SymTest, Test {
    ETHFaucet faucet;
    address public owner;

    function setUp() public {
        uint256 allowedAmount = svm.createUint256("allowedAmount");
        uint256 waitTime = svm.createUint256("waitTime");
        owner = svm.createAddress("owner");

        vm.assume(waitTime < 7 days);

        vm.startPrank(owner);
        faucet = new ETHFaucet(allowedAmount, waitTime);
        vm.stopPrank();

        // Fund the faucet
        vm.deal(address(faucet), 100 ether);
    }

    function check_claim_eth(address user) public {
        vm.assume(user != address(0));
        vm.assume(user != owner);

        vm.deal(user, 0);

        uint256 initialUserBalance = user.balance;
        uint256 initialFaucetBalance = address(faucet).balance;
        uint256 allowedAmount = faucet.allowedAmount();

        // Only proceed if faucet has enough balance
        vm.assume(initialFaucetBalance >= allowedAmount);

        // Fast forward if user needs to wait
        uint256 unlockTime = faucet.userUnlockTime(user);
        if (block.timestamp < unlockTime) {
            vm.warp(unlockTime);
        }

        vm.startPrank(user);
        faucet.claimETH();
        vm.stopPrank();

        // Verify balances
        assertEq(user.balance, initialUserBalance + allowedAmount);
        assertEq(address(faucet).balance, initialFaucetBalance - allowedAmount);
    }

    function check_owner_functions(uint256 newAmount, uint256 newWaitTime) public {
        vm.startPrank(owner);

        uint256 oldAmount = faucet.allowedAmount();
        uint256 oldWaitTime = faucet.waitTime();

        faucet.setAllowedAmount(newAmount);
        faucet.setWaitTime(newWaitTime);

        assertEq(faucet.allowedAmount(), newAmount);
        assertEq(faucet.waitTime(), newWaitTime);
        assertTrue(faucet.allowedAmount() != oldAmount || newAmount == oldAmount);
        assertTrue(faucet.waitTime() != oldWaitTime || newWaitTime == oldWaitTime);

        vm.stopPrank();
    }

    function check_withdraw(uint256 amount) public {
        vm.assume(amount <= address(faucet).balance);

        deal(owner, 0);
        uint256 initialOwnerBalance = owner.balance;
        uint256 initialFaucetBalance = address(faucet).balance;

        vm.prank(owner);
        faucet.withdraw(amount);

        assertEq(owner.balance, initialOwnerBalance + amount);
        assertEq(address(faucet).balance, initialFaucetBalance - amount);
    }

    receive() external payable {}
}
