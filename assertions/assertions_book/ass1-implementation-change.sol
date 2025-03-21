// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

interface IImplementation {
    function implementation() external view returns (address);
}

contract ImplementationChange is Assertion {
    IImplementation public implementation = IImplementation(address(0xbeef));

    function triggers() external view override {
        registerCallTrigger(this.implementationChange.selector);
    }

    // Asssert that the implementation contract address doesn't change
    // during the state transition
    function implementationChange() external {
        ph.forkPreState();
        address preImpl = implementation.implementation();
        ph.forkPostState();
        address postImpl = implementation.implementation();
        require(preImpl == postImpl, "Implementation has changed");
    }
}
