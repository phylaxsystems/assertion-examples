// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {PoolFactory} from "lib/PoolFactory.sol";

interface Assertion {
    enum TriggerType {
        STORAGE,
        ETHER,
        BOTH
    }

    struct Trigger {
        TriggerType triggerType;
        bytes4 fnSelector;
    }
}

abstract contract AerodromePoolFactoryAssertions is Assertion {
    PoolFactory public poolFactory = PoolFactory(0x420DD381b31aEf6683db6B902084cB0FFECe40Da); // AeroDrome PoolFactory on Base
    address public poolPauser; // Address of the pool pauser
    address public implementation; // Current address of the pool implementation
    address public voter; // Address of the Voter contract
    address public feeManager; // Address of the fee manager
    uint256 public fee; // Fee for the pool
    uint256 public maxFee; // Maximum fee for the pool

    function fnSelectors() external pure returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionStorage.selector);
        return triggers;
    }

    function setUp() public {
        poolPauser = poolFactory.pauser();
        implementation = poolFactory.implementation();
        voter = poolFactory.voter();
        feeManager = poolFactory.feeManager();
        fee = poolFactory.fee();
        maxFee = poolFactory.maxFee();
    }

    function assertionStorage() external returns (bool) {
        return true;
    }

    function assertionPoolPauserChanged() external returns (bool) {
        return poolFactory.pauser() == poolPauser;
    }

    function assertionImplementationChanged() external returns (bool) {
        return poolFactory.implementation() == implementation;
    }

    function assertionVoterChanged() external returns (bool) {
        return poolFactory.voter() == voter;
    }

    function assertionFeeManagerChanged() external returns (bool) {
        return poolFactory.feeManager() == feeManager;
    }

    function assertionFeeChanged() external returns (bool) {
        return poolFactory.fee() == fee;
    }

    function assertionMaxFeeChanged() external returns (bool) {
        return poolFactory.maxFee() == maxFee;
    }
}
