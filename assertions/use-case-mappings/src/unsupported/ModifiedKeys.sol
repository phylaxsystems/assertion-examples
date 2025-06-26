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

contract ModifiedKeysAssertion is Assertion {
    Protocol public protocol;

    constructor(Protocol protocol_) {
        protocol = protocol_;
    }

    function triggers() public view override {
        /*
        registerStateChangeTrigger(this.assertionModifiedKeys.selector, 0x0);
        */
    }

    function assertionModifiedKeys() public view {
        /*
        // unsupported for now
        // Returns the keys that were modified in the transaction
        address[] memory modifiedKeys = ph.getModifiedKeys(0x0);

        for (uint256 i = 0; i < modifiedKeys.length; i++) {
            address key = modifiedKeys[i];
            uint256 balance = protocol.balances(key);

            // Validate the value of the modified key here
        }
        */
    }
}
