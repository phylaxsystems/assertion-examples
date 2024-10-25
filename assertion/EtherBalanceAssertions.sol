// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

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

abstract contract EtherBalanceAssertions is Assertion {
    address public smartContract;
    uint256 public previousBalance;

    function fnSelectors() external pure returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.ETHER, this.assertionEther.selector);
        return triggers;
    }

    function setUp() public {
        smartContract = address(0x0000000000000000000000000000000000000000); // init to something real
        previousBalance = address(smartContract).balance;
    }


    function assertionEther() external returns (bool) {
        return
            assertionEtherBalance() &&
            assertionEtherReduced90() &&
            assertionEtherDrained(); // This syntax should not be used, myabe make all of it as requires with errors for the specific functions
    }

    // Unexpected ether balance
    // Some contracts should never have an ether balance
    // Note: This does not cover cases where selfdestruct is called or
    // where the contract address has been funded prior to deployment
    // Don't allow ether balance to be more than 0
    function assertionEtherBalance() external returns (bool) {
        return address(smartContract).balance == 0;
    }

    // Don't allow ether balance to be reduced by more than 90%
    function assertionEtherReduced90() external returns (bool) {
        return address(smartContract).balance >= (previousBalance / 10);
    }

    // Dont allow ether balance to be drained
    function assertionEtherDrained() external returns (bool) {
        return address(smartContract).balance >= 0;
    }
}
