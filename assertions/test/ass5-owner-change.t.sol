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
        cl.assertion({
            adopter: address(protocol),
            createData: type(OwnerChangeAssertion).creationCode,
            fnSelector: OwnerChangeAssertion.assertionOwnerChange.selector
        });

        // Set user as the caller
        vm.prank(user);
        // This should revert because owner is changing
        vm.expectRevert("Owner changed");
        protocol.setOwner(newOwner);
    }

    function test_assertionOwnerNotChanged() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(OwnerChangeAssertion).creationCode,
            fnSelector: OwnerChangeAssertion.assertionOwnerChange.selector
        });

        // Set user as the caller
        vm.prank(user);
        // This reverts because no assertion was triggered
        vm.expectRevert("Expected 1 assertion to be executed, but 0 were executed.");
        protocol.setOwner(initialOwner);
    }

    function test_assertionAdminChanged() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(OwnerChangeAssertion).creationCode,
            fnSelector: OwnerChangeAssertion.assertionAdminChange.selector
        });

        // Set user as the caller
        vm.prank(user);
        // This should revert because admin is changing
        vm.expectRevert("Admin changed");
        protocol.setAdmin(newAdmin);
    }

    function test_assertionAdminNotChanged() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(OwnerChangeAssertion).creationCode,
            fnSelector: OwnerChangeAssertion.assertionAdminChange.selector
        });

        // Set user as the caller
        vm.prank(user);
        // This reverts because no assertion was triggered
        vm.expectRevert("Expected 1 assertion to be executed, but 0 were executed.");
        protocol.setAdmin(initialAdmin);
    }
}
