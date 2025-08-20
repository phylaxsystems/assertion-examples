// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {Staking} from "src/ass3-pending-balance-bedrock-staking.sol";
import {PhEvm} from "credible-std/PhEvm.sol";
import {Test} from "forge-std/Test.sol";

contract StakingAssertions is Assertion, Staking, Test {
    function triggers() public view override {
        triggerRecorder.registerCallTrigger(this.assertTotalPendingOnMint.selector, Staking.mint.selector);
    }

    // Assertion PostTotalPending = PreTotalPending + ethersToMint
    function assertTotalPendingOnMint() public {
        Staking staking = Staking(payable(ph.getAssertionAdopter()));

        PhEvm.CallInputs[] memory mintCalls = ph.getCallInputs(address(staking), Staking.mint.selector);

        ph.forkPreTx();
        uint256 preTotalPending = staking.getPendingEthers();

        uint256 expectedPostTotalPending = preTotalPending;
        for (uint256 i = 0; i < mintCalls.length; i++) {
            (uint256 minToMint,) = abi.decode(mintCalls[i].input, (uint256, uint256));
            expectedPostTotalPending += minToMint;
        }

        ph.forkPostTx();

        require(staking.getPendingEthers() == expectedPostTotalPending, "ExpectedTotalPendingInvalid");
    }

    function _load(bytes32 slot) internal view returns (bytes32 value) {
        value = ph.load(ph.getAssertionAdopter(), slot);
    }
}
