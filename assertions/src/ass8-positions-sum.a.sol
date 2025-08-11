// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

// Assert that the sum of all positions is the same as the total supply reported by the protocol
contract PositionSumAssertion is Assertion {
    function triggers() external view override {
        // Register trigger for changes to the total supply
        registerCallTrigger(this.assertionPositionsSum.selector, ILending.deposit.selector);
    }

    // Compare the sum of all updated positions to the total supply reported by the protocol
    function assertionPositionsSum() external {
        // Get the assertion adopter address
        ILending adopter = ILending(ph.getAssertionAdopter());

        // Capture the pre-state total supply
        ph.forkPreTx();
        uint256 preStateTotalSupply = adopter.totalSupply();

        // Execute the transaction
        ph.forkPostTx();

        // Get the new total supply
        uint256 newTotalSupply = adopter.totalSupply();

        // Calculate the expected change in total supply
        uint256 expectedTotalSupplyChange = newTotalSupply - preStateTotalSupply;

        // Track the actual sum of position changes
        uint256 positionChangesSum = 0;

        // Get deposit function call inputs
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.deposit.selector);

        // Process deposit function calls
        for (uint256 i = 0; i < callInputs.length; i++) {
            // Decode the function call input
            (address user, uint256 amount) = abi.decode(callInputs[i].input, (address, uint256));

            // Add the deposit amount to the position changes sum
            positionChangesSum += amount;
        }

        // Note: In a complete implementation, you would also check for withdraw calls
        // and other functions that modify positions. Ideally, you would have separate
        // assertion functions for each type of call to make the code more maintainable
        // and easier to understand.

        // Verify that the sum of position changes equals the change in total supply
        require(positionChangesSum == expectedTotalSupplyChange, "Positions sum does not match total supply");
    }
}

// We use a simple lending contract as an example
// Adjust accordingly to the interface of your protocol
interface ILending {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function deposit(address user, uint256 amount) external;
}
