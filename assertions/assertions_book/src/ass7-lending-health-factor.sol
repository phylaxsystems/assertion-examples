// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

// We use Morpho as an example, but this could be any lending protocol
interface IMorpho {
    struct MarketParams {
        uint256 marketId;
    }

    struct Position {
        uint256 supplyShares;
        uint128 borrowShares;
        uint128 collateral;
    }

    function idToMarketParams(uint256) external view returns (MarketParams memory);
    function position(uint256, address) external view returns (Position memory);
    function _isHealthy(MarketParams memory marketParams, uint256 marketId, address borrower)
        external
        view
        returns (bool);

    // Functions used in triggers
    function supply(uint256 marketId, uint256 amount) external;
    function borrow(uint256 marketId, uint256 amount) external;
    function withdraw(uint256 marketId, uint256 amount) external;
    function repay(uint256 marketId, uint256 amount) external;
}

contract LendingHealthFactorAssertion is Assertion {
    IMorpho public morpho = IMorpho(address(0xbeef));

    // Storage slot for the position mapping
    // This is the slot where the position mapping is stored in the contract
    bytes32 constant POSITION_MAPPING_SLOT = bytes32(uint256(2)); // Adjust this based on actual storage layout

    function triggers() external view override {
        // Register triggers for functions that should maintain healthy positions
        // For example: supply, borrow, withdraw, repay functions
        registerCallTrigger(this.assertionHealthFactor.selector, morpho.supply.selector);
        registerCallTrigger(this.assertionHealthFactor.selector, morpho.borrow.selector);
        registerCallTrigger(this.assertionHealthFactor.selector, morpho.withdraw.selector);
        registerCallTrigger(this.assertionHealthFactor.selector, morpho.repay.selector);
    }

    // Check that all updated positions are still healthy after operations
    // that should maintain healthy positions
    function assertionHealthFactor() external {
        // Get all state changes for the position mapping
        // We need to check each position that might have changed
        // This is a simplified example - in practice you would need to:
        // 1. Track which positions are affected by the current transaction
        // 2. Calculate their storage slots
        // 3. Check state changes for each slot

        // Example: Check a specific position (in practice you'd need to track affected positions)
        uint256 id = 1; // Example ID
        address borrower = address(0x123); // Example borrower

        // Get state changes for the position using the mapping accessor
        bytes32[] memory changes = getStateChangesBytes32(
            address(morpho),
            POSITION_MAPPING_SLOT,
            id,
            0 // No additional offset needed for the first level
        );

        // If there were changes to this position, verify it's still healthy
        if (changes.length > 0) {
            IMorpho.MarketParams memory marketParams = IMorpho.MarketParams({marketId: id});
            require(morpho._isHealthy(marketParams, id, borrower), "Health factor is not healthy");
        }
    }
}
