// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {RoninBridge} from "lib/RoninBridge.sol";

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

contract RoninBridgeAssertions is Assertion, RoninBridge {
    RoninBridge public roninBridge;
    uint256 public previousTotalWeight;

    function fnSelectors() external pure returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionStorage.selector);
        return triggers;
    }

    function setUp() public {
        roninBridge = RoninBridge(0x0000000000000000000000000000000000000000);
        previousTotalWeight = roninBridge.totalWeight();
    }

    function assertionStorage() external returns (bool) {
        return assertionTotalWeightNeverZero();
    }

    function assertionTotalWeightNeverZero() external returns (bool) {
        return roninBridge.totalWeight() > 0;
    }
}
