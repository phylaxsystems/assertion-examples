// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

interface IExampleContract {}

contract EtherDrainAssertion is Assertion {
    IExampleContract public example = IExampleContract(address(0xbeef));

    function triggers() external view override {
        registerBalanceChangeTrigger(this.assertionEtherDrain.selector);
    }

    // Don't allow more than x% of the total ether balance to be drained in a single transaction
    // revert if the assertion fails
    function assertionEtherDrain() external {
        ph.forkPreState();
        uint256 preBalance = address(example).balance;
        ph.forkPostState();
        uint256 postBalance = address(example).balance;
        if (preBalance > postBalance) {
            uint256 drainAmount = preBalance - postBalance;
            uint256 tenPercentOfPreBalance = preBalance / 10; // Change according to the percentage you want to allow
            require(drainAmount <= tenPercentOfPreBalance, "Drain amount is greater than 10% of the pre-balance");
        }
    }
}
