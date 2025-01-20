// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/Assertion.sol";

// Beefy style interface
interface IBeefyVault {
    function paused() external view returns (bool);
    function balance() external view returns (uint256);
}

contract BeefyPanicAssertion is Assertion {
    IBeefyVault public vault = IBeefyVault(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1); // Define the number of triggers
        assertions[0] = this.assertionPanickedCanOnlyDecreaseBalance.selector; // Define the trigger
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
