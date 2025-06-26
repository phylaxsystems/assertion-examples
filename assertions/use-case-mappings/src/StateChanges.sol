// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract MonotonicallyIncreasingValue {
    uint256 public value;

    function setValue(uint256 value_) external {
        value = value_;
    }
}

/// It is possible to get all values assigned to any slot within a transaction.
/// This is very helpful if you want to test that state invariants were never violated, even intra tx.
/// Note: Sometimes it is useful to know the inputs of a function call which led to the state change.
/// It should be noted that if the assertion queries call inputs and state changes separately (which there exists no other way right now),
/// there is no guarantee that each index of the two arrays are related.
/// Note: The returned array is ordered by the timely order of the state changes.
contract StateChangesAssertion is Assertion {
    MonotonicallyIncreasingValue public protocol;

    constructor(MonotonicallyIncreasingValue protocol_) {
        protocol = protocol_;
    }

    function triggers() public view override {
        registerCallTrigger(this.assertionStateChanges.selector);
    }

    function assertionStateChanges() public view {
        uint256[] memory changes = getStateChangesUint(address(protocol), 0x0);
        for (uint256 i = 0; i < changes.length - 1; i++) {
            require(changes[i] < changes[i + 1], "Value is not monotonically increasing");
        }
    }
}
