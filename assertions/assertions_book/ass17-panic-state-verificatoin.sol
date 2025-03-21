// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

// Beefy style interface
interface IBeefyVault {
    function paused() external view returns (bool);
    function balance() external view returns (uint256);
}

contract BeefyPanicAssertion is Assertion {
    IBeefyVault public vault = IBeefyVault(address(0xbeef));

    function triggers() external view override {
        registerCallTrigger(this.assertionPanickedCanOnlyDecreaseBalance.selector);
    }

    // Check that if the state is panicked that the pool balance can only decrease
    // The tokens can increase in value, but the balance can only decrease
    // This is a more robust check as it doesn't rely on the function selectors
    function assertionPanickedCanOnlyDecreaseBalance() external {
        ph.forkPreState();
        bool isPanicked = vault.paused();
        uint256 preBalance = vault.balance();
        ph.forkPostState();
        uint256 postBalance = vault.balance();
        if (isPanicked) {
            require(postBalance <= preBalance, "Balance can only decrease when panicked");
        }
    }
}
