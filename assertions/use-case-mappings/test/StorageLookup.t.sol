// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Protocol, StorageLookupAssertion} from "../src/StorageLookup.sol";
import {Test} from "forge-std/Test.sol";

contract StorageLookupTest is CredibleTest, Test {
    Protocol public protocol;

    function setUp() public {
        protocol = new Protocol();
    }

    function test_assertionStorageLookup() public {
        protocol.setOwner(address(0x1));
        cl.addAssertion(
            "StorageLookupAssertion", address(protocol), type(StorageLookupAssertion).creationCode, abi.encode(protocol)
        );
        vm.prank(address(0x1));
        cl.validate(
            "StorageLookupAssertion",
            address(protocol),
            0,
            abi.encodeWithSelector(Protocol.setOwner.selector, address(0x2))
        );
    }
}
