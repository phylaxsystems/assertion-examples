// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Baal} from "lib/Baal.sol";
import {Assertion} from "lib/credible-std/Assertion.sol";

abstract contract BaalMolochv3Assertions is Assertion, Baal {
    Baal public baal = Baal(0x0000000000000000000000000000000000000000);

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](3);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionOwnerChanged.selector);
        triggers[1] = Trigger(TriggerType.STORAGE, this.assertionSponsorshipThresholdNotZero.selector);
        triggers[2] = Trigger(TriggerType.STORAGE, this.assertionTrustedForwarderNotZero.selector);
        return triggers;
    }

    function assertionOwnerChanged() external returns (bool) {
        ph.forkPreState();
        address previousOwner = baal.owner();
        ph.forkPostState();
        return baal.owner() != previousOwner;
    }

    // Don't set sponsorship threshold to 0
    function assertionSponsorshipThresholdNotZero() external returns (bool) {
        ph.forkPreState();
        uint256 previousSponsorshipThreshold = baal.sponsorshipThreshold();
        ph.forkPostState();
        return baal.sponsorshipThreshold() != previousSponsorshipThreshold;
    }

    // Trusted forwarder changed to non-zero address
    function assertionTrustedForwarderNotZero() external returns (bool) {
        ph.forkPreState();
        address previousTrustedForwarder = baal.trustedForwarder();
        ph.forkPostState();
        return baal.trustedForwarder() != previousTrustedForwarder;
    }
}
