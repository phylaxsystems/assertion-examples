// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";

contract Protocol {
    uint256 public value1;
    uint256 public value2;

    function setValue1(uint256 value1_) public {
        value1 = value1_;
    }

    function setValue2(uint256 value2_) public {
        value2 = value2_;
    }
}

/// @notice This assertion is unsupported for now
/// When fetching state changes of a slot, it might be of interest what values other slots had at the time of the state change
/// This is not possible to do with the current state change API
/// State changes could be synchronized to capture the state of multiple slots at the time of a state change of any of them.
contract SynchronizedStateChangesAssertion is Assertion {
    Protocol public protocol;

    constructor(Protocol protocol_) {
        protocol = protocol_;
    }

    function triggers() public view override {
        /*
        registerStateChangeTrigger(this.assertionSynchronizedStateChanges.selector, 0x0);
        */
    }

    function assertionSynchronizedStateChanges() public view {
        /*
        // unsupported for now
        // Returns the state changes that were synchronized in the transaction
        bytes32[2] memory synchronizedSlots = [0x0, 0x1];
        uint256[][] memory stateChanges = ph.getSynchronizedStateChangesUint(synchronizedSlots);

        for (uint256 i = 0; i < stateChanges.length; i++) {
            uint256[] memory stateChange = stateChanges[i];

            // validate the state changes here
            // i.e. require(stateChange[0] != stateChange[1], "Values should be different");
        }
        */
    }
}
