// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";

contract Protocol {
    uint256 public value;

    function setValueWithCallback(uint256 value_) public {
        value = value_;
        (bool success,) = msg.sender.call("");
        require(success, "Callback failed");
    }
}

// Untrusted callbacks can influence the end state of the contract in unexpected ways.
// In the example, the callback could recursively call the setter function,
// making it nearly impossible to validate the end state.
// In the future, assertions could be made aware of recursive function calls, helping to validate the end state.
contract UntrustedCallbacksAssertion is Assertion {
    Protocol public protocol;

    constructor(Protocol protocol_) {
        protocol = protocol_;
    }

    function triggers() public view override {
        /*
        registerCallFrameTrigger(this.assertionUntrustedCallbacks.selector, protocol.setValueWithCallback.selector);
        */
    }

    function assertionUntrustedCallbacks() public view {
        /*
        CallInputs memory callInputs = getCallFrame();

        // There is a untrusted callback in the function execution which could
        // recursively call the setter function, letting the succeeding require fail.
        // This is not supported yet.
        (uint256 value) = abi.decode(callInputs.input, (uint256));
        require(value == loadUint(0x0), "Value mismatch");
        */
    }
}
