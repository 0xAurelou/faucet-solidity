// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import {Test} from "forge-std/Test.sol";
import {ETHFaucet} from "src/Faucet.sol";
import "forge-std/console.sol";

contract FaucetTestUnit is SymTest, Test {
    ETHFaucet faucet;
    address public owner;
    uint256 public allowedAmount;
    uint256 public waitTime;

    // Running 3 tests for test/FaucetHalmos.t.sol:ETHFaucetTest
    // Counterexample:
    //     halmos_allowedAmount_uint256_5bfca6c_01 = 0x0000000000000000000000000000000000000000000000040000000001c00000
    //     halmos_owner_address_8320788_03 = 0x0000000000000000010000000000000000000000
    //     halmos_waitTime_uint256_319232a_02 = 0x0000000000000000000000000000000000000000000000000000000000000000
    //     p_user_address_de90aac_00 = 0x00000000000000000000000000000000000000000000000000000000aaaa0002
    function setUp() public {
        owner = address(0x0000000000000000010000000000000000000000);
        allowedAmount = 0x0000000000000000000000000000000000000000000000040000000001c00000;
        waitTime = 0x0000000000000000000000000000000000000000000000000000000000000000;
        vm.startPrank(owner);
        faucet = new ETHFaucet(allowedAmount, waitTime);
        vm.stopPrank();

        // Fund the faucet
        vm.deal(address(faucet), 100 ether);
    }

    function test_claim_eth() public {
        address user1 = address(0x00000000000000000000000000000000000000000000000000000000aaaa0002);

        vm.prank(user1);
        faucet.claimETH();

        assert(user1.balance > 0);
    }
}
