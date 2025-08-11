// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract EmergencyStateAssertion is Assertion {
    function triggers() external view override {
        // Register trigger for all function calls to ensure comprehensive coverage
        registerCallTrigger(this.assertionPanickedCanOnlyDecreaseBalance.selector);
    }

    // Check that if the state is panicked that the pool balance can only decrease
    // This ensures users can withdraw but prevents new deposits
    function assertionPanickedCanOnlyDecreaseBalance() external {
        // Get the assertion adopter address
        IEmergencyPausable adopter = IEmergencyPausable(ph.getAssertionAdopter());

        // Get pre-state values
        ph.forkPreTx();
        bool isPanicked = adopter.paused();
        uint256 preBalance = adopter.balance();

        // Get post-state values
        ph.forkPostTx();
        uint256 postBalance = adopter.balance();

        // If protocol is paused, ensure balance can only decrease
        if (isPanicked) {
            require(postBalance <= preBalance, "Balance can only decrease when panicked");

            // Additional check: verify no unauthorized state changes
            uint256[] memory changes = getStateChangesUint(
                address(adopter),
                bytes32(uint256(1)) // Balance storage slot, change according to your contract
            );

            // Ensure all intermediate states maintain the decrease-only property
            for (uint256 i = 0; i < changes.length; i++) {
                require(changes[i] <= preBalance, "Unauthorized state change during pause");
            }
        }
    }
}

interface IEmergencyPausable {
    function paused() external view returns (bool);
    function balance() external view returns (uint256);
}
