// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "openzeppelin-contracts/access/Ownable.sol";

contract ETHFaucet is Ownable {
    // Custom Errors
    error AlreadyClaimed(uint256 unlockTime);
    error InsufficientFunds();
    error TransferFailed();

    // Events
    event FaucetClaimed(address indexed user, uint256 amount, uint256 nextUnlockTime);
    event FundsDeposited(address indexed sender, uint256 amount);

    // Storage variables
    uint256 public allowedAmount;
    uint256 public waitTime;
    mapping(address => uint256) public userUnlockTime;

    // Constructor
    constructor(uint256 _allowedAmount, uint256 _waitTime) Ownable(msg.sender) {
        allowedAmount = _allowedAmount;
        waitTime = _waitTime;
    }

    // External function for claiming ETH
    function claimETH() external {
        address caller = msg.sender;

        // Check if user is allowed to claim
        if (!isAllowedForTransaction(caller)) {
            revert AlreadyClaimed(userUnlockTime[caller]);
        }

        // Ensure faucet has enough ETH
        if (address(this).balance < allowedAmount) {
            revert InsufficientFunds();
        }

        // Update user's unlock time
        uint256 nextUnlockTime = block.timestamp + waitTime;
        userUnlockTime[caller] = nextUnlockTime;

        // Transfer ETH to the caller
        (bool success,) = payable(caller).call{value: allowedAmount}("");
        if (!success) {
            revert TransferFailed();
        }

        emit FaucetClaimed(caller, allowedAmount, nextUnlockTime);
    }

    // View functions
    function getAllowedTime(address account) external view returns (uint256) {
        return userUnlockTime[account];
    }

    function isAllowedForTransaction(address account) public view returns (bool) {
        uint256 unlockTime = userUnlockTime[account];
        return (block.timestamp >= unlockTime);
    }

    // Owner-only functions
    function setAllowedAmount(uint256 _allowedAmount) external onlyOwner {
        allowedAmount = _allowedAmount;
    }

    function setWaitTime(uint256 _waitTime) external onlyOwner {
        waitTime = _waitTime;
    }

    // Function to deposit ETH into the faucet
    receive() external payable {}

    fallback() external payable {}

    function withdraw(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient balance");
        (bool success,) = payable(owner()).call{value: amount}("");
        require(success, "Withdraw failed");
    }
}
