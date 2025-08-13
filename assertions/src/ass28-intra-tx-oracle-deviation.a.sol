// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract IntraTxOracleDeviationAssertion is Assertion {
    // Maximum allowed price deviation (10% by default)
    uint256 public constant MAX_DEVIATION_PERCENTAGE = 10;

    function triggers() external view override {
        // Register trigger for oracle price update calls
        registerCallTrigger(this.assertOracleDeviation.selector, IOracle.updatePrice.selector);
    }

    // Check that price updates don't deviate more than the allowed percentage
    // from the initial price at any point during the transaction
    function assertOracleDeviation() external {
        // Get the assertion adopter address
        IOracle adopter = IOracle(ph.getAssertionAdopter());

        // Start with a simple check comparing pre and post state
        ph.forkPreTx();
        uint256 prePrice = adopter.price();

        // Calculate allowed deviation thresholds (10% by default)
        uint256 maxAllowedPrice = (prePrice * (100 + MAX_DEVIATION_PERCENTAGE)) / 100;
        uint256 minAllowedPrice = (prePrice * (100 - MAX_DEVIATION_PERCENTAGE)) / 100;

        // First check post-state price
        ph.forkPostTx();
        uint256 postPrice = adopter.price();

        // Verify post-state price is within allowed deviation from initial price
        require(
            postPrice >= minAllowedPrice && postPrice <= maxAllowedPrice,
            "Oracle post-state price deviation exceeds threshold"
        );

        // Get all price update calls in this transaction
        // Since this assertion is triggered by updatePrice calls, we know there's at least one
        PhEvm.CallInputs[] memory priceUpdates = ph.getCallInputs(address(adopter), adopter.updatePrice.selector);

        // Check each price update to ensure none deviate more than allowed from initial price
        for (uint256 i = 0; i < priceUpdates.length; i++) {
            ph.forkPostCall(priceUpdates[i].id);

            // Call the price function at the given frame in the call stack
            // TODO: This is panicking the application due to the slicing error
            uint256 updatedPrice = adopter.price();

            // Verify each update is within allowed deviation from initial pre-state price
            require(
                updatedPrice >= minAllowedPrice && updatedPrice <= maxAllowedPrice,
                "Oracle intra-tx price deviation exceeds threshold"
            );
        }
    }
}

interface IOracle {
    function updatePrice(uint256 price) external;
    function price() external view returns (uint256);
}
