// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

interface IExampleContract {}

contract EtherDrainAssertion is Assertion {
    IExampleContract public example = IExampleContract(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1); // Define the number of triggers
        assertions[0] = this.assertionEtherDrain.selector; // Define the trigger
    }

    // Don't allow more than x% of the total ether balance to be drained in a single transaction
    // revert if the assertion fails
    function assertionEtherDrain() external {
        ph.forkPreState();
        uint256 preBalance = address(example).balance;
        ph.forkPostState();
        uint256 postBalance = address(example).balance;
        uint256 drainAmount = preBalance - postBalance;
        uint256 tenPercentOfPreBalance = preBalance / 10; // Change according to the percentage you want to allow
        require(drainAmount <= tenPercentOfPreBalance, "Drain amount is greater than 10% of the pre-balance");
    }
}
