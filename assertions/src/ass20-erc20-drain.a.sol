// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract ERC20DrainAssertion is Assertion {
    // Maximum percentage of token balance that can be withdrawn in a single tx (in basis points)
    // 1000 basis points = 10%
    uint256 public constant MAX_DRAIN_PERCENTAGE_BPS = 1000;

    // Denominator for basis points calculation
    uint256 public constant BPS_DENOMINATOR = 10000;

    address public tokenAddress;

    constructor(address tokenAddress_) {
        tokenAddress = tokenAddress_;
    }

    function triggers() external view override {
        // This assertion doesn't need specific function triggers since it monitors
        // the overall balance change regardless of which function caused it
        // We register a generic trigger that will run after every transaction
        registerCallTrigger(this.assertERC20Drain.selector);
    }

    /// @notice Checks that the token balance doesn't decrease by more than MAX_DRAIN_PERCENTAGE_BPS in a single transaction
    /// @dev This assertion captures state before and after the transaction to detect excessive token outflows
    function assertERC20Drain() external {
        // Get the assertion adopter address (this is the protocol contract)
        ITokenVault protocol = ITokenVault(ph.getAssertionAdopter());

        // Get token balance before the transaction
        ph.forkPreTx();
        uint256 preBalance = IERC20(tokenAddress).balanceOf(address(protocol));

        // Get token balance after the transaction
        ph.forkPostTx();
        uint256 postBalance = IERC20(tokenAddress).balanceOf(address(protocol));

        // If balance decreased, check if the decrease exceeds our threshold
        if (preBalance > postBalance) {
            uint256 drainAmount = preBalance - postBalance;

            // Calculate maximum allowed drain amount (e.g., 10% of pre-balance)
            uint256 maxAllowedDrainAmount = (preBalance * MAX_DRAIN_PERCENTAGE_BPS) / BPS_DENOMINATOR;

            // Revert if the drain amount exceeds the allowed percentage
            require(
                drainAmount <= maxAllowedDrainAmount, "ERC20Drain: Token outflow exceeds maximum allowed percentage"
            );
        }
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface ITokenVault {
    function withdraw(address recipient, uint256 amount) external;
    function getBalance() external view returns (uint256);
    function deposit(uint256 amount) external;
}
