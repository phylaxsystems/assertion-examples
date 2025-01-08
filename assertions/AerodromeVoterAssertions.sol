// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "lib/credible-std/Assertion.sol";

interface IAerodromeVoter {
    function emergencyCouncil() external view returns (address);

    function epochGovernor() external view returns (address);

    function factoryRegistry() external view returns (address);

    function forwarder() external view returns (address);
}

contract AerodromeVoterAssertions is Assertion {
    IAerodromeVoter public voterContract = IAerodromeVoter(0x16613524e02ad97eDfeF371bC883F2F5d6C480A5); // AeroDrome Voter contract on Base

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](4);
        assertions[0] = this.assertionEmergencyCouncilChanged.selector;
        assertions[1] = this.assertionEpochGovernorChanged.selector;
        assertions[2] = this.assertionFactoryRegistryChanged.selector;
        assertions[3] = this.assertionForwarderChanged.selector;
    }

    function assertionEmergencyCouncilChanged() external returns (bool) {
        ph.forkPreState();
        address previousEmergencyCouncil = voterContract.emergencyCouncil();
        ph.forkPostState();
        return voterContract.emergencyCouncil() != previousEmergencyCouncil;
    }

    function assertionEpochGovernorChanged() external returns (bool) {
        ph.forkPreState();
        address previousEpochGovernor = voterContract.epochGovernor();
        ph.forkPostState();
        return voterContract.epochGovernor() != previousEpochGovernor;
    }

    function assertionFactoryRegistryChanged() external returns (bool) {
        ph.forkPreState();
        address previousFactoryRegistry = voterContract.factoryRegistry();
        ph.forkPostState();
        return voterContract.factoryRegistry() != previousFactoryRegistry;
    }

    function assertionForwarderChanged() external returns (bool) {
        ph.forkPreState();
        address previousForwarder = voterContract.forwarder();
        ph.forkPostState();
        return voterContract.forwarder() != previousForwarder;
    }
}
