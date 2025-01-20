// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/Assertion.sol";

interface IYieldFarm {
    function withdraw(uint256 amount) external;
    function userInfo(address user) external view returns (uint256 depositAmount, uint256 rewards);
}

contract YieldFarmWithdrawAssertion is Assertion {
    IYieldFarm public farm = IYieldFarm(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1);
        assertions[0] = this.assertWithdraw.selector;
    }

    // Make sure the withdraw amount is less than or equal to the deposit amount
    // We don't want anyone to be able to withdraw more than they should be able to
    // We're assuming that that rewards are accounted for separately
    function assertWithdraw() external {
        ph.forkPreState();
        // Get withdrawal amount from transaction data
        (address user,,, bytes memory data) = ph.getData(); // TODO: Update when cheatcode is implemented
        uint256 withdrawAmount = abi.decode(data[4:], (uint256));

        // Get pre-withdrawal state
        (uint256 preDeposit,) = farm.userInfo(user);

        require(withdrawAmount <= preDeposit, "Withdraw exceeds deposit");

        // Check post-withdrawal state
        ph.forkPostState();
        (uint256 postDeposit,) = farm.userInfo(user);

        // Verify deposit amount decreased correctly
        require(postDeposit == preDeposit - withdrawAmount, "Incorrect withdrawal amount");
    }
}
