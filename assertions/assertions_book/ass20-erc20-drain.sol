// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

contract ERC20DrainAssertion is Assertion {
    IERC20 public erc20 = IERC20(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1); // Define the number of triggers
        assertions[0] = this.assertionERC20Drain.selector; // Define the trigger
    }

    // Don't allow for more than x% of the total balance to be transferred out in a single transaction
    // revert if the assertion fails
    function assertionERC20Drain() external {
        ph.forkPreState();
        uint256 preBalance = erc20.balanceOf(address(this));
        ph.forkPostState();
        uint256 postBalance = erc20.balanceOf(address(this));
        uint256 drainAmount = preBalance - postBalance;
        uint256 tenPercentOfPreBalance = preBalance / 10; // Change according to the percentage you want to allow
        require(drainAmount <= tenPercentOfPreBalance, "Drain amount is greater than 10% of the pre-balance");
    }
}
