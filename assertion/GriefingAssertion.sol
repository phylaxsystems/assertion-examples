// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {DelayedWithdrawal} from "../lib/DelayedWithdrawal.sol";
import {Assertion} from "../lib/credible-std/Assertion.sol";

abstract contract GriefingAssertion is Assertion, DelayedWithdrawal {
    DelayedWithdrawal public delayedWithdrawal = new DelayedWithdrawal(100);

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionOnlyBeneficiaryCanDeposit.selector);
        return triggers;
    }

    // Avoid griefing by checking that only the beneficiary can deposit or potentially no one can deposit
    function assertionOnlyBeneficiaryCanDeposit() external returns (bool) {
        // Assume some cheat code that allows us to check the sender of a function
        ph.forkPostState();
        Transaction memory transaction = ph.getTransaction(); // Doesn't work yet
        return transaction.sender == delayedWithdrawal.beneficiary();
    }
}
