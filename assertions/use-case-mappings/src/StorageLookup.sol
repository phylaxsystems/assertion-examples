// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract Protocol {
    address owner;

    function setOwner(address owner_) public {
        owner = owner_;
    }
}

/// It is possible to get the value of any slot of the state before or after a transaction.
/// This can be used to read private state variables.
/// Note: It is possible to read the state before or after a transaction by using the forkPreTx or forkPostTx cheatcodes.
contract StorageLookupAssertion is Assertion {
    function triggers() public view override {
        registerCallTrigger(this.assertionStorageLookup.selector);
    }

    function assertionStorageLookup() public view {
        Protocol protocol = Protocol(ph.getAssertionAdopter());
        address[] memory whitelist = new address[](2);
        whitelist[0] = address(0x1);
        whitelist[1] = address(0x2);

        address owner = address(uint160(uint256(ph.load(address(protocol), bytes32(uint256(0))))));

        for (uint256 i = 0; i < whitelist.length; i++) {
            if (owner == whitelist[i]) {
                return;
            }
        }

        revert("Owner not in whitelist");
    }
}
