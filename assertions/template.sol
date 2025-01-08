// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../lib/credible-std/Assertion.sol";

// TODO: Import the contract / interface you want to assert against
interface IExample {
    function owner() external view returns (address);
}

// TODO: Explain the assertion
contract ExampleAssertion is Assertion {
    IExample public example = IExample(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1); // Define the number of triggers
        assertions[0] = this.assertionExample.selector; // Define the trigger
        // assertions[1] = this.assertionAnotherExample.selector; // Example of another assertion
    }

    // TODO: Describe the assertion
    // return true indicates a valid state
    // return false indicates an invalid state
    function assertionExample() external returns (bool) {
        ph.forkPreState();
        address preOwner = example.owner();
        ph.forkPostState();
        address postOwner = example.owner();
        return preOwner == postOwner;
    }

    // function assertionAnotherExample() external returns (bool) {
    //     ph.forkPreState();
    //     address preOwner = example.admin();
    //     ph.forkPostState();
    //     address postOwner = example.admin();
    //     return preOwner == postOwner;
    // }
}
