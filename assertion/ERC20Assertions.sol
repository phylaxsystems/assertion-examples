// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Assertion} from "../lib/credible-std/Assertion.sol";

abstract contract ERC20Assertions is Assertion, ERC20 {
    ERC20 public erc20 = ERC20(0x0000000000000000000000000000000000000000);
    address public smartContract = address(0x0000000000000000000000000000000000000000);
    address public someExternalContract = address(0x0000000000000000000000000000000000000000);
    address[] public allowedAddresses = [address(0x1), address(0x2), address(0x3)];

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](6);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionBalanceDrained.selector);
        triggers[1] = Trigger(TriggerType.STORAGE, this.assertionBalanceReduced90.selector);
        triggers[2] = Trigger(TriggerType.STORAGE, this.assertionFullAllowance.selector);
        triggers[3] = Trigger(TriggerType.STORAGE, this.assertionAllowanceReduced90.selector);
        triggers[4] = Trigger(TriggerType.STORAGE, this.assertionMaxAllowance.selector);
        triggers[5] = Trigger(TriggerType.STORAGE, this.assertionOnlyAllowedAddressesHaveAllowance.selector);
        return triggers;
    }

    // Balance vulnerability
    // Don't allow balance to be zero
    function assertionBalanceDrained() external returns (bool) {
        ph.forkPostState();
        return erc20.balanceOf(smartContract) != 0;
    }

    // Balance vulnerability
    // Don't allow balance to be reduced by more than 90%
    function assertionBalanceReduced90() external returns (bool) {
        ph.forkPreState();
        uint256 previousBalance = erc20.balanceOf(smartContract);
        ph.forkPostState();
        uint256 newBalance = erc20.balanceOf(smartContract);
        uint256 tenPercent = previousBalance / 10;
        return newBalance >= tenPercent;
    }

    // Approval vulnerability
    // Don't give full allowance to external contract
    // Probably there are cases where you want to do that, but in most cases you don't
    function assertionFullAllowance() external returns (bool) {
        ph.forkPostState();
        return erc20.allowance(smartContract, someExternalContract) != erc20.balanceOf(smartContract);
    }

    // Approval vulnerability
    // Don't allow allowance over 90%
    // Probably there are cases where you want to do that, but in most cases you don't
    function assertionAllowanceReduced90() external returns (bool) {
        ph.forkPreState();
        uint256 previousAllowance = erc20.allowance(smartContract, someExternalContract);
        ph.forkPostState();
        uint256 newAllowance = erc20.allowance(smartContract, someExternalContract);
        uint256 ninetyPercent = (previousAllowance / 10) * 9;
        return newAllowance <= ninetyPercent;
    }

    // Approval vulnerability
    // Dont allow max allowance to be set
    // Probably there are cases where you want to do that, but in most cases you don't
    function assertionMaxAllowance() external returns (bool) {
        ph.forkPostState();
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
