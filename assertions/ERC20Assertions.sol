// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../lib/credible-std/Assertion.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
}

abstract contract ERC20Assertions is Assertion {
    IERC20 public erc20 = IERC20(0x0000000000000000000000000000000000000000);
    address public smartContract = address(0x0000000000000000000000000000000000000000);
    address public someExternalContract = address(0x0000000000000000000000000000000000000000);
    address[] public allowedAddresses = [address(0x1), address(0x2), address(0x3)];

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](6);
        assertions[0] = this.assertionBalanceDrained.selector;
        assertions[1] = this.assertionBalanceReduced90.selector;
        assertions[2] = this.assertionFullAllowance.selector;
        assertions[3] = this.assertionAllowanceReduced90.selector;
        assertions[4] = this.assertionMaxAllowance.selector;
        assertions[5] = this.assertionOnlyAllowedAddressesHaveAllowance.selector;
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
