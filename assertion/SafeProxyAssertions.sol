// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {SafeProxy} from "../lib/SafeProxy.sol";

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

contract SafeProxyAssertions is Assertion, SafeProxy {
    address public constant FACTORY_ADDRESS = 0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67;
    address public constant SAFE_SINGLETON = 0x41675C099F32341bf84BFc5382aF534df5C7461a;
    address public constant SPECIFIC_PROXY = 0xd3c6D54A4C16F0938b7AB4937C7fF5ec64a44E4b;

    SafeProxyFactory public factory;
    Safe public safeSingleton;
    SafeProxy public specificProxy;
    Safe public safe;
    uint256 public previousNonce;
    uint256 public previousThreshold;
    uint256 public previousChainId;

    function fnSelectors() external pure returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionStorage.selector);
        return triggers;
    }

    function setUp() public {
        factory = SafeProxyFactory(FACTORY_ADDRESS);
        safeSingleton = Safe(SAFE_SINGLETON);
        specificProxy = SafeProxy(SPECIFIC_PROXY);
        safe = Safe(specificProxy.owner());
        previousNonce = safe.nonce();
        previousThreshold = safe.getThreshold();
        previousChainId = safe.getChainId();
    }

    function assertionStorage() external returns (bool) {
        return
            assertionValidThreshold() &&
            assertionThresholdNotOne() &&
            assertionInvariantNonce() &&
            assertionNoDuplicateOwners() &&
            assertionChainIdNeverChanges();
    }

    // The threshold should always be greater than zero and less than or equal to the number of owners
    function assertionValidThreshold() external returns (bool) {
        return threshold > 0 && threshold <= owners.length;
    }

    // The threshold should never be set to one if threshold was previously greater than one
    function assertionThresholdNotOne() external returns (bool) {
        uint256 newThreshold = safe.getThreshold();
        if (previousThreshold > 1) {
            return newThreshold > 1;
        }
        return true;
    }

    // The nonce should always increase by 1
    function assertionInvariantNonce() external returns (bool) {
        uint256 newNonce = safe.nonce();
        return newNonce == previousNonce + 1;
    }

    // Must not have two identical owners
    function assertionNoDuplicateOwners() external returns (bool) {
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
        uint256 newChainId = safe.getChainId();
        return newChainId == previousChainId;
    }
}
