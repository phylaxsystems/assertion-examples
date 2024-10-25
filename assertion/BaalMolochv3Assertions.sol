// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Baal} from "lib/Baal.sol";

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

abstract contract BaalMolochv3Assertions is Assertion, Baal {
    Baal public baal;
    address public previousOwner;

    function fnSelectors() external pure returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionStorage.selector);
        return triggers;
    }

    function setUp() public {
        baal = Baal(0x0000000000000000000000000000000000000000);
        previousOwner = baal.owner();
    }

    function assertionStorage() external returns (bool) {
        return assertionOwnerChanged();
    }

    function assertionOwnerChanged() external returns (bool) {
        return baal.owner() != previousOwner;
    }

    // Don't set sponsorship threshold to 0
    function assertionSponsorshipThresholdNotZero() external returns (bool) {
        return baal.sponsorshipThreshold() != 0;
    }

    // Trusted forwarder changed to non-zero address
    function assertionTrustedForwarderNotZero() external returns (bool) {
        return baal.trustedForwarder() != address(0);
    }
}
