// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Safe} from "../lib/Safe.sol";
import {Assertion} from "../lib/credible-std/Assertion.sol";

contract SafeProxyAssertions is Assertion, Safe {
    Safe public safe;

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](5);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionValidThreshold.selector);
        triggers[1] = Trigger(TriggerType.STORAGE, this.assertionThresholdNotOne.selector);
        triggers[2] = Trigger(TriggerType.STORAGE, this.assertionInvariantNonce.selector);
        triggers[3] = Trigger(TriggerType.STORAGE, this.assertionNoDuplicateOwners.selector);
        triggers[4] = Trigger(TriggerType.STORAGE, this.assertionChainIdNeverChanges.selector);
        return triggers;
    }

    // The threshold should always be greater than zero and less than or equal to the number of owners
    function assertionValidThreshold() external returns (bool) {
        ph.forkPostState();
        uint256 threshold = safe.getThreshold();
        address[] memory owners = safe.getOwners();
        return threshold > 0 && threshold <= owners.length;
    }

    // The threshold should never be set to one if threshold was previously greater than one
    function assertionThresholdNotOne() external returns (bool) {
        ph.forkPreState();
        uint256 newThreshold = safe.getThreshold();
        ph.forkPostState();
        if (previousThreshold > 1) {
            return newThreshold > 1;
        }
        return true;
    }

    // The nonce should always increase by 1
    function assertionInvariantNonce() external returns (bool) {
        ph.forkPreState();
        uint256 prevNonce = safe.nonce();
        ph.forkPostState();
        uint256 newNonce = safe.nonce();
        return newNonce == prevNonce + 1;
    }

    // Must not have two identical owners
    function assertionNoDuplicateOwners() external returns (bool) {
        ph.forkPostState();
        address[] memory owners = safe.getOwners();
        for (uint256 i = 0; i < owners.length; i++) {
            for (uint256 j = i + 1; j < owners.length; j++) {
                if (owners[i] == owners[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    // The chain ID should never change
    function assertionChainIdNeverChanges() external returns (bool) {
        ph.forkPreState();
        uint256 prevChainId = safe.getChainId();
        ph.forkPostState();
        uint256 newChainId = safe.getChainId();
        return prevChainId == newChainId;
    }
}
