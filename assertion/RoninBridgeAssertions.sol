// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {RoninBridge} from "lib/RoninBridge.sol";
import {Assertion} from "lib/credible-std/Assertion.sol";

contract RoninBridgeAssertions is Assertion, RoninBridge {
    RoninBridge public roninBridge = RoninBridge(0x0000000000000000000000000000000000000000);

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionTotalWeightNeverZero.selector);
        return triggers;
    }

    function assertionTotalWeightNeverZero() external returns (bool) {
        ph.forkPostState();
        return roninBridge.totalWeight() > 0;
    }
}
