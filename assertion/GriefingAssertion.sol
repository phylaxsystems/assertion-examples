// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {DelayedWithdrawal} from "lib/DelayedWithdrawal.sol";

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

abstract contract GriefingAssertion is Assertion, DelayedWithdrawal {
    DelayedWithdrawal public delayedWithdrawal = new DelayedWithdrawal(100);
    address public withdrawer = 0x0000000000000000000000000000000000000000;

    function fnSelectors() external pure returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionStorage.selector);
        return triggers;
    }

    function setUp() public {}

    function assertionStorage() external returns (bool) {
        return true;
    }

    // Avoid griefing by checking that only the beneficiary can deposit or potentially no one can deposit
    function assertionOnlyBeneficiaryCanDeposit() external returns (bool) {
        // Assume some cheat code that allows us to check the sender of a function
        return msg.sender(delayedWithdrawal.deposit()) == delayedWithdrawal.beneficiary();
    }
}
