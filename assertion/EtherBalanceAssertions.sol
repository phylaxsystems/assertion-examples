// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../lib/credible-std/Assertion.sol";

contract EtherBalanceAssertions is Assertion {
    address public smartContract = address(0x0000000000000000000000000000000000000000);

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](3);
        triggers[0] = Trigger(TriggerType.ETHER, this.assertionEtherBalance.selector);
        triggers[1] = Trigger(TriggerType.ETHER, this.assertionEtherReduced90.selector);
        triggers[2] = Trigger(TriggerType.ETHER, this.assertionEtherDrained.selector);
        return triggers;
    }

    // Unexpected ether balance
    // Some contracts should never have an ether balance
    // Note: This does not cover cases where selfdestruct is called or
    // where the contract address has been funded prior to deployment
    // Don't allow ether balance to be more than 0
    function assertionEtherBalance() external returns (bool) {
        ph.forkPostState();
        return address(smartContract).balance == 0;
    }

    // Don't allow ether balance to be reduced by more than 90%
    function assertionEtherReduced90() external returns (bool) {
        ph.forkPreState();
        uint256 previousBalance = address(smartContract).balance;
        ph.forkPostState();
        return address(smartContract).balance >= (previousBalance / 10);
    }

    // Dont allow ether balance to be drained
    function assertionEtherDrained() external returns (bool) {
        ph.forkPostState();
        return address(smartContract).balance >= 0;
    }
}
