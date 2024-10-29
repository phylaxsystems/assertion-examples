// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "lib/credible-std/Assertion.sol";
import {RoyaltyRegistry} from "lib/RoyaltyRegisty.sol";

contract RoyaltyRegistryAssertions is Assertion, RoyaltyRegistry {
    address public royaltyRegistry = address(0x0000000000000000000000000000000000000000);

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionHashCollision.selector);
        return triggers;
    }

    function assertionHashCollision() external returns (bool) {
        // We need a cheatcode to fetch params given to function calls
        // in order to check if the correct addresses received payout or not
    }
}
