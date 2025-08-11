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
        cl.assertion({
            adopter: address(protocol),
            createData: type(ImplementationChangeAssertion).creationCode,
            fnSelector: ImplementationChangeAssertion.implementationChange.selector
        });

        vm.prank(user);
        // This should revert because implementation is changing
        vm.expectRevert("Implementation changed");
        protocol.setImplementation(newImpl);
    }

    function test_assertionImplementationNotChanged() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(ImplementationChangeAssertion).creationCode,
            fnSelector: ImplementationChangeAssertion.implementationChange.selector
        });

        vm.prank(user);
        // The storage slot is not changed so the assertin is not triggered
        vm.expectRevert("Expected 1 assertion to be executed, but 0 were executed.");
        protocol.setImplementation(initialImpl);
    }
}
