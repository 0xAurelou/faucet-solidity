// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {ETHFaucet} from "src/Faucet.sol";

contract ETHFaucetScript is Script {
    ETHFaucet public faucet;

    // Parameters for deployment
    uint256 public constant allowedAmount = 0.1 ether; // Amount each user can claim
    uint256 public constant waitTime = 6 hours; // Time between claims

    function setUp() public {}

    function run() public {
        // Uncomment the line below only if you want to deploy it on-chain
        vm.startBroadcast(); // Start broadcasting transactions to the blockchain

        // Deploy the faucet contract
        faucet = new ETHFaucet(allowedAmount, waitTime);

        console.log("ETHFaucet deployed at:", address(faucet));

        // Uncomment the line below only if you want to deploy it on-chain
        // vm.stopBroadcast(); // Stop broadcasting
    }
}
