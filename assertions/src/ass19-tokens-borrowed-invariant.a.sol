// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

// Assert that the total supply of assets is always greater than or equal to the total borrowed assets
contract TokensBorrowedInvariant is Assertion {
    // Use specific storage slots for the protocol
    bytes32 private constant TOTAL_SUPPLY_SLOT = bytes32(uint256(0)); // Slot 0
    bytes32 private constant TOTAL_BORROW_SLOT = bytes32(uint256(1)); // Slot 1

    function triggers() external view override {
        // Register triggers for changes to either storage slot with the main assertion function
        registerStorageChangeTrigger(this.assertBorrowedInvariant.selector, TOTAL_SUPPLY_SLOT);
        registerStorageChangeTrigger(this.assertBorrowedInvariant.selector, TOTAL_BORROW_SLOT);
    }

    // Check the invariant whenever supply or borrow values change
    function assertBorrowedInvariant() external {
        // Get the assertion adopter address
        IMorpho adopter = IMorpho(ph.getAssertionAdopter());

        // Check the state after the transaction to ensure the invariant holds
        ph.forkPostTx();

        // Get the current protocol state
        uint256 totalSupplyAsset = adopter.totalSupplyAsset();
        uint256 totalBorrowedAsset = adopter.totalBorrowedAsset();

        // Ensure the core invariant is maintained
        require(
            totalSupplyAsset >= totalBorrowedAsset,
            "INVARIANT VIOLATION: Total supply of assets is less than total borrowed assets"
        );
    }
}

interface IMorpho {
    function totalSupplyAsset() external view returns (uint256);
    function totalBorrowedAsset() external view returns (uint256);
}
