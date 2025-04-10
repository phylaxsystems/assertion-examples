// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

interface IGovernance {
    struct Timelock {
        address admin;
        uint256 timelockDelay;
        bool isActive;
    }

    function timelock() external view returns (Timelock memory);
}

contract TimelockVerification is Assertion {
    IGovernance public governance = IGovernance(address(0xbeef));

    function triggers() external view override {
        // Register trigger for changes to the timelock storage slot
        registerStorageChangeTrigger(this.assertionTimelock.selector, bytes32(uint256(0)));
    }

    // Verify that a timelock is working as expected after some governance action
    function assertionTimelock() external {
        // Get pre-state timelock information
        ph.forkPreState();
        address preAdmin = governance.timelock().admin;
        bool preActive = governance.timelock().isActive;

        // If timelock was already active, no need to check further
        if (preActive) {
            return;
        }

        // Get post-state timelock information
        ph.forkPostState();

        // If timelock is now active, verify all parameters
        if (governance.timelock().isActive) {
            // Verify timelock delay is within acceptable bounds
            bool minDelayCorrect = governance.timelock().timelockDelay >= 1 days;
            bool maxDelayCorrect = governance.timelock().timelockDelay <= 2 weeks;

            // Verify admin hasn't changed
            bool adminCorrect = governance.timelock().admin == preAdmin;

            // Require all parameters to be correct
            require(minDelayCorrect && maxDelayCorrect && adminCorrect, "Timelock parameters invalid");
        }
    }
}
