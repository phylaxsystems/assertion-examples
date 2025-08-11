// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../lib/credible-std/Assertion.sol";

interface ISafe {
    function getThreshold() external view returns (uint256);

    function getOwners() external view returns (address[] memory);

    function nonce() external view returns (uint256);

    function getChainId() external view returns (uint256);
}

contract SafeProxyAssertions is Assertion {
    ISafe public safe;

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](5);
        assertions[0] = this.assertionValidThreshold.selector;
        assertions[1] = this.assertionThresholdNotOne.selector;
        assertions[2] = this.assertionInvariantNonce.selector;
        assertions[3] = this.assertionNoDuplicateOwners.selector;
        assertions[4] = this.assertionChainIdNeverChanges.selector;
    }

    // The threshold should always be greater than zero and less than or equal to the number of owners
    function assertionValidThreshold() external returns (bool) {
        ph.forkPostTx();
        uint256 threshold = safe.getThreshold();
        address[] memory owners = safe.getOwners();
        return threshold > 0 && threshold <= owners.length;
    }

    // The threshold should never be set to one if threshold was previously greater than one
    function assertionThresholdNotOne() external returns (bool) {
        ph.forkPreTx();
        uint256 previousThreshold = safe.getThreshold();
        ph.forkPostTx();
        uint256 newThreshold = safe.getThreshold();
        if (previousThreshold > 1) {
            return newThreshold > 1;
        }
        return true;
    }

    // The nonce should always increase by 1
    function assertionInvariantNonce() external returns (bool) {
        ph.forkPreTx();
        uint256 prevNonce = safe.nonce();
        ph.forkPostTx();
        uint256 newNonce = safe.nonce();
        return newNonce == prevNonce + 1;
    }

    // Must not have two identical owners
    function assertionNoDuplicateOwners() external returns (bool) {
        ph.forkPostTx();
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
        ph.forkPreTx();
        uint256 prevChainId = safe.getChainId();
        ph.forkPostTx();
        uint256 newChainId = safe.getChainId();
        return prevChainId == newChainId;
    }
}
