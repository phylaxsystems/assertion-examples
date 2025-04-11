// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Ownership} from "../../src/ass5-owner-change.sol";
import {OwnerChangeAssertion} from "../src/ass5-owner-change.a.sol";

contract TestOwnerChange is CredibleTest, Test {
    // Contract state variables
    Ownership public protocol;
    address public initialOwner = address(0xdead);
    address public initialAdmin = address(0xbeef);
    address public newOwner = address(0xacab);
    address public newAdmin = address(0xcafe);
    address public user = address(0x1234);

    function setUp() public {
        protocol = new Ownership(initialOwner, initialAdmin);
        // Give the user some ETH
        vm.deal(user, 100 ether);
    }

    function test_assertionOwnerChanged() public {
        address protocolAddress = address(protocol);
        string memory label = "Owner has changed";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(OwnerChangeAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);
        // This should revert because owner is changing
        vm.expectRevert("Assertions Reverted");
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.setOwner.selector, abi.encode(newOwner)));
    }

    function test_assertionOwnerNotChanged() public {
        address protocolAddress = address(protocol);
        string memory label = "Owner has not changed";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(OwnerChangeAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);
        // This should pass because we're setting the same owner
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.setOwner.selector, abi.encode(initialOwner)));
    }

    function test_assertionAdminChanged() public {
        address protocolAddress = address(protocol);
        string memory label = "Admin has changed";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(OwnerChangeAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);
        // This should revert because admin is changing
        vm.expectRevert("Assertions Reverted");
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.setAdmin.selector, abi.encode(newAdmin)));
    }

    function test_assertionAdminNotChanged() public {
        address protocolAddress = address(protocol);
        string memory label = "Admin has not changed";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(OwnerChangeAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);
        // This should pass because we're setting the same admin
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.setAdmin.selector, abi.encode(initialAdmin)));
    }
}
