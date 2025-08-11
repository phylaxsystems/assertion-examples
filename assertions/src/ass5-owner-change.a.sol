// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract OwnerChangeAssertion is Assertion {
    function triggers() external view override {
        // Register triggers for changes to both owner and admin storage slots
        registerStorageChangeTrigger(this.assertionOwnerChange.selector, bytes32(uint256(0)));
        registerStorageChangeTrigger(this.assertionAdminChange.selector, bytes32(uint256(1)));
    }

    // Assert that the owner address doesn't change during the state transition
    function assertionOwnerChange() external {
        // Get the assertion adopter address
        IOwnership adopter = IOwnership(ph.getAssertionAdopter());

        // Get pre-state owner
        ph.forkPreTx();
        address preOwner = adopter.owner();

        // Get post-state owner
        ph.forkPostTx();
        address postOwner = adopter.owner();

        // Verify owner hasn't changed after the transaction
        // Fail early if the owner has changed
        require(preOwner == postOwner, "Owner changed");

        // Get all state changes for the owner slot
        // This checks if the owner address has changed throughout the callstack
        address[] memory changes = getStateChangesAddress(
            address(adopter),
            bytes32(uint256(0)) // First storage slot for owner address
        );

        // Additional check: verify no changes take place in the owner slot throughout the callstack
        for (uint256 i = 0; i < changes.length; i++) {
            require(changes[i] == preOwner, "Unauthorized owner change detected");
        }
    }

    // Assert that the admin address doesn't change during the state transition
    function assertionAdminChange() external {
        // Get the assertion adopter address
        IOwnership adopter = IOwnership(ph.getAssertionAdopter());

        // Get pre-state admin
        ph.forkPreTx();
        address preAdmin = adopter.admin();

        // Get post-state admin
        ph.forkPostTx();
        address postAdmin = adopter.admin();

        // Get all state changes for the admin slot
        address[] memory changes = getStateChangesAddress(
            address(adopter),
            bytes32(uint256(1)) // Second storage slot for admin address
        );

        // Verify admin hasn't changed after the transaction
        require(preAdmin == postAdmin, "Admin changed");

        // Additional check: verify no changes take place in the admin slot throughout the callstack
        for (uint256 i = 0; i < changes.length; i++) {
            require(changes[i] == preAdmin, "Unauthorized admin change detected");
        }
    }
}

interface IOwnership {
    function owner() external view returns (address);
    function admin() external view returns (address);
}
