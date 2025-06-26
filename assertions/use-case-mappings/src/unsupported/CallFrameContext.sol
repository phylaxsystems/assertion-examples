// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";

contract Protocol {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function mint(address to, uint256 amount) public {
        balances[to] += amount;
    }
}

// In this use case the assertion runs on context of a specific call instead of the whole transaction.
// This is useful to assert properties about the state of the protocol at the time of a specific call.
contract CallFrameContextAssertion is Assertion {
    Protocol public protocol;

    constructor(Protocol protocol_) {
        protocol = protocol_;
    }

    function triggers() public view override {
        /*
        // unsupported for now
        registerCallFrameTrigger(this.assertionCallFrameContext.selector, protocol.transfer.selector);
        */
    }

    function assertionCallFrameContext() public view {
        /*
        // unsupported for now
        // Returns the CallInputs for the specific call
        PhEvm.CallFrameContext memory callFrameContext = ph.getCallFrameContext();

        // Get the caller
        address caller = callFrameContext.caller;

        // Get the caller of the transaction
        (address to, uint256 amount) = abi.decode(callFrameContext.input, (address, uint256));

        ph.forkPreState();
        // Read the state before the call

        ph.forkPostState();
        // Read the state after the call

        // Assert the expected outcome here
        */
    }
}
