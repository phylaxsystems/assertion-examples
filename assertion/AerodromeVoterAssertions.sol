// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Voter} from "lib/Voter.sol";
import {Assertion} from "lib/credible-std/Assertion.sol";

abstract contract AerodromeVoterAssertions is Assertion, Voter {
    Voter public voterContract = Voter(0x16613524e02ad97eDfeF371bC883F2F5d6C480A5); // AeroDrome Voter contract on Base
    address public emergencyCouncil;
    address public epochGovernor;
    address public factoryRegistry;
    address public forwarder;

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](4);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionEmergencyCouncilChanged.selector);
        triggers[1] = Trigger(TriggerType.STORAGE, this.assertionEpochGovernorChanged.selector);
        triggers[2] = Trigger(TriggerType.STORAGE, this.assertionFactoryRegistryChanged.selector);
        triggers[3] = Trigger(TriggerType.STORAGE, this.assertionForwarderChanged.selector);
        return triggers;
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
