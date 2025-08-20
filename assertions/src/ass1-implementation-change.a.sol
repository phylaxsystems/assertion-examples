// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract ImplementationChangeAssertion is Assertion {
    function triggers() external view override {
        // Register trigger for changes to the implementation address storage slot
        // The implementation address is typically stored in the first storage slot (slot 0)
        registerStorageChangeTrigger(this.implementationChange.selector, bytes32(uint256(0)));
    }

    // Assert that the implementation contract address doesn't change
    // during the state transition
    function implementationChange() external {
        // Get the assertion adopter address
        IImplementation adopter = IImplementation(ph.getAssertionAdopter());

        // Get pre-state implementation
        ph.forkPreTx();
        address preImpl = adopter.implementation();

        // Get post-state implementation
        ph.forkPostTx();
        address postImpl = adopter.implementation();

        // Get all state changes for the implementation slot
        address[] memory changes = getStateChangesAddress(
            address(adopter),
            bytes32(uint256(0)) // First storage slot for implementation address
        );

        // Verify implementation hasn't changed
        require(preImpl == postImpl, "Implementation changed");

        // Additional check: verify no unauthorized changes to implementation slot
        for (uint256 i = 0; i < changes.length; i++) {
            require(changes[i] == preImpl, "Unauthorized implementation change detected");
        }
    }
}

interface IImplementation {
    function implementation() external view returns (address);
}
