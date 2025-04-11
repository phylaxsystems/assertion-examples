// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Implementation} from "../../src/ass1-implementation-change.sol";
import {ImplementationChangeAssertion} from "../src/ass1-implementation-change.a.sol";

contract TestImplementationChange is CredibleTest, Test {
    // Contract state variables
    Implementation public protocol;
    address public initialImpl = address(0xdead);
    address public newImpl = address(0xbeef);
    address public user = address(0x1234);

    function setUp() public {
        protocol = new Implementation(initialImpl);
        vm.deal(user, 100 ether);
    }

    function test_assertionImplementationChanged() public {
        address protocolAddress = address(protocol);
        string memory label = "Implementation has changed";

        // Associate the assertion with the protocol
        // cl will manage the correct assertion execution under the hood when the protocol is being called
        cl.addAssertion(label, protocolAddress, type(ImplementationChangeAssertion).creationCode, abi.encode(protocol));

        vm.prank(user);
        // This should revert because implementation is changing
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label, protocolAddress, 0, abi.encodePacked(protocol.setImplementation.selector, abi.encode(newImpl))
        );
    }

    function test_assertionImplementationNotChanged() public {
        address protocolAddress = address(protocol);
        string memory label = "Implementation has not changed";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(ImplementationChangeAssertion).creationCode, abi.encode(protocol));

        vm.prank(user);
        // This should pass because we're setting the same implementation
        cl.validate(
            label, protocolAddress, 0, abi.encodePacked(protocol.setImplementation.selector, abi.encode(initialImpl))
        );
    }
}
