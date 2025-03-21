// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IExampleContract {}

contract ERC20DrainAssertion is Assertion {
    IERC20 public erc20 = IERC20(address(0xbeef));
    IExampleContract public example = IExampleContract(address(0xf00));

    function triggers() external view override {
        registerCallTrigger(this.assertionERC20Drain.selector);
    }

    // Don't allow for more than x% of the total balance to be transferred out in a single transaction
    // revert if the assertion fails
    function assertionERC20Drain() external {
        ph.forkPreState();
        uint256 preBalance = erc20.balanceOf(address(example));
        ph.forkPostState();
        uint256 postBalance = erc20.balanceOf(address(example));
        if (preBalance > postBalance) {
            uint256 drainAmount = preBalance - postBalance;
            uint256 tenPercentOfPreBalance = preBalance / 10; // Change according to the percentage you want to allow
            require(drainAmount <= tenPercentOfPreBalance, "Drain amount is greater than 10% of the pre-balance");
        }
    }
}
