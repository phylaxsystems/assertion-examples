// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

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

abstract contract ERC20Assertions is Assertion, ERC20 {
    ERC20 public erc20;
    address public smartContract;
    address public someExternalContract;
    address[] public allowedAddresses;

    function fnSelectors() external pure returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionStorage.selector);
        return triggers;
    }

    function setUp() public {
        erc20 = ERC20(0x0000000000000000000000000000000000000000); // init to something real
        smartContract = address(0x0000000000000000000000000000000000000000); // init to something real
        someExternalContract = address(0x0000000000000000000000000000000000000000); // init to something real
        allowedAddresses = [address(0x1), address(0x2), address(0x3)];
    }

    function assertionStorage() external returns (bool) {
        return
            assertionBalanceDrained() &&
            assertionBalanceReduced90() &&
            assertionFullAllowance() &&
            assertionAllowanceReduced90() &&
            assertionMaxAllowance();
    }

    // Balance vulnerability
    // Don't allow balance to be zero
    function assertionBalanceDrained() external returns (bool) {
        return erc20.balanceOf(smartContract) != 0;
    }

    // Balance vulnerability
    // Don't allow balance to be reduced by more than 90%
    function assertionBalanceReduced90() external returns (bool) {
        uint256 newBalance = erc20.balanceOf(smartContract);
        uint256 tenPercent = newBalance / 10;
        return newBalance >= tenPercent;
    }

    // Approval vulnerability
    // Don't give full allowance to external contract
    // Probably there are cases where you want to do that, but in most cases you don't
    function assertionFullAllowance() external returns (bool) {
        return erc20.allowance(smartContract, someExternalContract) != erc20.balanceOf(smartContract);
    }

    // Approval vulnerability
    // Don't allow allowance over 90%
    // Probably there are cases where you want to do that, but in most cases you don't
    function assertionAllowanceReduced90() external returns (bool) {
        uint256 newAllowance = erc20.allowance(smartContract, someExternalContract);
        uint256 ninetyPercent = (erc20.balanceOf(smartContract) / 10) * 9;
        return newAllowance >= ninetyPercent;
    }

    // Approval vulnerability
    // Dont allow max allowance to be set
    // Probably there are cases where you want to do that, but in most cases you don't
    function assertionMaxAllowance() external returns (bool) {
        // Here "smartContract" could also be an EOA
        return erc20.allowance(smartContract, someExternalContract) != type(uint256).max;
    }

    // Approval vulnerability
    // Only allow addresses in a list to have allowance
    function assertionOnlyAllowedAddressesHaveAllowance() external returns (bool) {
        // Don't allow any address that is not in the allowedAddresses list to have allowance
        // Probably this needs some cheatcode to check if an allowance is that it is only allowed
        //to be set for addresses in the allowedAddresses list
    }
}
