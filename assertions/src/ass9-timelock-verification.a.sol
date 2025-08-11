// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract TimelockVerificationAssertion is Assertion {
    function triggers() external view override {
        // Register trigger for changes to the timelock storage slot
        registerStorageChangeTrigger(this.assertionTimelock.selector, bytes32(uint256(0)));
    }

    // Verify that a timelock is working as expected after some governance action
    function assertionTimelock() external {
        // Get the assertion adopter address
        IGovernance adopter = IGovernance(ph.getAssertionAdopter());

        // Get pre-state timelock information
        ph.forkPreTx();
        bool preActive = adopter.timelockActive();

        // If timelock was already active, no need to check further
        if (preActive) {
            return;
        }

        // Get post-state timelock information
        ph.forkPostTx();

        // If timelock is now active, verify all parameters
        if (adopter.timelockActive()) {
            // Verify timelock delay is within acceptable bounds
            bool minDelayCorrect = adopter.timelockDelay() >= 1 days;
            bool maxDelayCorrect = adopter.timelockDelay() <= 2 weeks;

            // Require all parameters to be correct
            require(minDelayCorrect && maxDelayCorrect, "Timelock parameters invalid");
        }
    }
}

interface IGovernance {
    struct Timelock {
        uint256 timelockDelay;
        bool isActive;
    }

    function timelockActive() external view returns (bool);
    function timelockDelay() external view returns (uint256);
    function activateTimelock() external;
    function setTimelock(uint256 _delay) external;
}
