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

/// @notice This assertion is unsupported for now
/// Currently only fetching function call inputs for a specific call is supported
/// The order of function calls of different selectors might influence the expected outcome (resulting state) of the transaction.
/// To properly validate transaction traces, function call inputs of different selectors need to be sequenced.
contract SequencedFunctionCallInputsAssertion is Assertion {
    Protocol public protocol;

    constructor(Protocol protocol_) {
        protocol = protocol_;
    }

    function triggers() public view override {
        /*
        registerCallFrameTrigger(this.assertionSequencedFunctionCallInputs.selector, protocol.transfer.selector);
        */
    }

    function assertionSequencedFunctionCallInputs() public view {
        /*
        // unsupported for now
        // Returns the function call inputs for the specific call
        bytes4[] memory selectors = [Protocol.transfer.selector, Protocol.mint.selector];
        PhEvm.CallInputs memory callInputs = ph.getCallInputs(address(protocol), selectors);

        for (uint256 i = 0; i < callInputs.length; i++) {
            if (callInputs[i].selector == Protocol.transfer.selector) {
                processTransferCallInputs(callInputs[i]);
            } else if (callInputs[i].selector == Protocol.mint.selector) {
                processMintCallInputs(callInputs[i]);
            }
        }
        */
    }
}
