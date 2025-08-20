// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../lib/credible-std/Assertion.sol";

interface IAerodromePoolFactory {
    function pauser() external view returns (address);

    function implementation() external view returns (address);

    function voter() external view returns (address);

    function feeManager() external view returns (address);

    function fee() external view returns (uint256);

    function maxFee() external view returns (uint256);
}

abstract contract AerodromePoolFactoryAssertions is Assertion {
    IAerodromePoolFactory public poolFactory = IAerodromePoolFactory(0x420DD381b31aEf6683db6B902084cB0FFECe40Da); // AeroDrome PoolFactory on Base

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](6);
        assertions[0] = this.assertionPoolPauserChanged.selector;
        assertions[1] = this.assertionImplementationChanged.selector;
        assertions[2] = this.assertionVoterChanged.selector;
        assertions[3] = this.assertionFeeManagerChanged.selector;
        assertions[4] = this.assertionFeeChanged.selector;
        assertions[5] = this.assertionMaxFeeChanged.selector;
    }

    function assertionPoolPauserChanged() external returns (bool) {
        ph.forkPreTx();
        address prevPauser = poolFactory.pauser();
        ph.forkPostTx();
        address newPauser = poolFactory.pauser();
        return prevPauser == newPauser;
    }

    function assertionImplementationChanged() external returns (bool) {
        ph.forkPreTx();
        address prevImplementation = poolFactory.implementation();
        ph.forkPostTx();
        address newImplementation = poolFactory.implementation();
        return prevImplementation == newImplementation;
    }

    function assertionVoterChanged() external returns (bool) {
        ph.forkPreTx();
        address prevVoter = poolFactory.voter();
        ph.forkPostTx();
        address newVoter = poolFactory.voter();
        return prevVoter == newVoter;
    }

    function assertionFeeManagerChanged() external returns (bool) {
        ph.forkPreTx();
        address prevFeeManager = poolFactory.feeManager();
        ph.forkPostTx();
        address newFeeManager = poolFactory.feeManager();
        return prevFeeManager == newFeeManager;
    }

    function assertionFeeChanged() external returns (bool) {
        ph.forkPreTx();
        uint256 prevFee = poolFactory.fee();
        ph.forkPostTx();
        uint256 newFee = poolFactory.fee();
        return prevFee == newFee;
    }

    function assertionMaxFeeChanged() external returns (bool) {
        ph.forkPreTx();
        uint256 prevMaxFee = poolFactory.maxFee();
        ph.forkPostTx();
        uint256 newMaxFee = poolFactory.maxFee();
        return prevMaxFee == newMaxFee;
    }
}
