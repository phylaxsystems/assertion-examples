// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "lib/credible-std/Assertion.sol";

interface IBaalMolochv3 {
    function owner() external view returns (address);

    function sponsorshipThreshold() external view returns (uint256);

    function trustedForwarder() external view returns (address);
}

abstract contract BaalMolochv3Assertions is Assertion {
    IBaalMolochv3 public baal = IBaalMolochv3(0x0000000000000000000000000000000000000000);

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](3);
        assertions[0] = this.assertionOwnerChanged.selector;
        assertions[1] = this.assertionSponsorshipThresholdNotZero.selector;
        assertions[2] = this.assertionTrustedForwarderNotZero.selector;
    }

    function assertionOwnerChanged() external returns (bool) {
        ph.forkPreTx();
        address previousOwner = baal.owner();
        ph.forkPostTx();
        return baal.owner() != previousOwner;
    }

    // Don't set sponsorship threshold to 0
    function assertionSponsorshipThresholdNotZero() external returns (bool) {
        ph.forkPreTx();
        uint256 previousSponsorshipThreshold = baal.sponsorshipThreshold();
        ph.forkPostTx();
        return baal.sponsorshipThreshold() != previousSponsorshipThreshold;
    }

    // Trusted forwarder changed to non-zero address
    function assertionTrustedForwarderNotZero() external returns (bool) {
        ph.forkPreTx();
        address previousTrustedForwarder = baal.trustedForwarder();
        ph.forkPostTx();
        return baal.trustedForwarder() != previousTrustedForwarder;
    }
}
