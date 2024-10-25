// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Voter} from "lib/Voter.sol";

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

abstract contract AerodromeVoterAssertions is Assertion {
    Voter public voterContract = Voter(0x16613524e02ad97eDfeF371bC883F2F5d6C480A5); // AeroDrome Voter contract on Base
    address public emergencyCouncil;
    address public epochGovernor;
    address public factoryRegistry;
    address public forwarder;

    function fnSelectors() external pure returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionStorage.selector);
        return triggers;
    }

    function setUp() public {
        emergencyCouncil = voterContract.emergencyCouncil(); // Emergency council address
        epochGovernor = voterContract.epochGovernor(); // Epoch governor address
        factoryRegistry = voterContract.factoryRegistry(); // Factory registry address
        forwarder = voterContract.forwarder(); // Forwarder address
    }

    function assertionStorage() external returns (bool) {
        return true;
    }

    function assertionEmergencyCouncilChanged() external returns (bool) {
        return voterContract.emergencyCouncil() == emergencyCouncil;
    }

    function assertionEpochGovernorChanged() external returns (bool) {
        return voterContract.epochGovernor() == epochGovernor;
    }

    function assertionFactoryRegistryChanged() external returns (bool) {
        return voterContract.factoryRegistry() == factoryRegistry;
    }

    function assertionForwarderChanged() external returns (bool) {
        return voterContract.forwarder() == forwarder;
    }
}
