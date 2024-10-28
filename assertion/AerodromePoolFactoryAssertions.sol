// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {PoolFactory} from "../lib/PoolFactory.sol";
import {Assertion} from "../lib/credible-std/Assertion.sol";

abstract contract AerodromePoolFactoryAssertions is Assertion {
    PoolFactory public poolFactory = PoolFactory(0x420DD381b31aEf6683db6B902084cB0FFECe40Da); // AeroDrome PoolFactory on Base

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](6);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionPoolPauserChanged.selector);
        triggers[1] = Trigger(TriggerType.STORAGE, this.assertionImplementationChanged.selector);
        triggers[2] = Trigger(TriggerType.STORAGE, this.assertionVoterChanged.selector);
        triggers[3] = Trigger(TriggerType.STORAGE, this.assertionFeeManagerChanged.selector);
        triggers[4] = Trigger(TriggerType.STORAGE, this.assertionFeeChanged.selector);
        triggers[5] = Trigger(TriggerType.STORAGE, this.assertionMaxFeeChanged.selector);
        return triggers;
    }

    function assertionPoolPauserChanged() external returns (bool) {
        ph.forkPreState();
        address prevPauser = poolFactory.pauser();
        ph.forkPostState();
        address newPauser = poolFactory.pauser();
        return prevPauser == newPauser;
    }

    function assertionImplementationChanged() external returns (bool) {
        ph.forkPreState();
        address prevImplementation = poolFactory.implementation();
        ph.forkPostState();
        address newImplementation = poolFactory.implementation();
        return prevImplementation == newImplementation;
    }

    function assertionVoterChanged() external returns (bool) {
        ph.forkPreState();
        address prevVoter = poolFactory.voter();
        ph.forkPostState();
        address newVoter = poolFactory.voter();
        return prevVoter == newVoter;
    }

    function assertionFeeManagerChanged() external returns (bool) {
        ph.forkPreState();
        address prevFeeManager = poolFactory.feeManager();
        ph.forkPostState();
        address newFeeManager = poolFactory.feeManager();
        return prevFeeManager == newFeeManager;
    }

    function assertionFeeChanged() external returns (bool) {
        ph.forkPreState();
        uint256 prevFee = poolFactory.fee();
        ph.forkPostState();
        uint256 newFee = poolFactory.fee();
        return prevFee == newFee;
    }

    function assertionMaxFeeChanged() external returns (bool) {
        ph.forkPreState();
        uint256 prevMaxFee = poolFactory.maxFee();
        ph.forkPostState();
        uint256 newMaxFee = poolFactory.maxFee();
        return prevMaxFee == newMaxFee;
    }
}
