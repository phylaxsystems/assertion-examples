// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../lib/credible-std/Assertion.sol";

interface IDelayedWithdrawal {
    function beneficiary() external view returns (address);
}

abstract contract GriefingAssertion is Assertion {
    IDelayedWithdrawal public delayedWithdrawal = IDelayedWithdrawal(0x0000000000000000000000000000000000000000);

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1);
        assertions[0] = this.assertionOnlyBeneficiaryCanDeposit.selector;
    }

    // Avoid griefing by checking that only the beneficiary can deposit or potentially no one can deposit
    function assertionOnlyBeneficiaryCanDeposit() external returns (bool) {
        // Assume some cheat code that allows us to check the sender of a function
        ph.forkPostState();
        (address from, , ) = ph.getTransaction(); // TODO: Check if this works once we have the cheatcode
        return from == delayedWithdrawal.beneficiary();
    }
}
