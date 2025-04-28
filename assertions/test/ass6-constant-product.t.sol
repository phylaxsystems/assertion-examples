// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {ConstantProductAmm} from "../../src/ass6-constant-product.sol";
import {ConstantProductAssertion} from "../src/ass6-constant-product.a.sol";
import {IAmm} from "../src/ass6-constant-product.a.sol";

contract TestConstantProductAssertion is CredibleTest, Test {
    // Contract state variables
    ConstantProductAmm public protocol;
    address public user = address(0x1234);
    string constant ASSERTION_LABEL = "ConstantProductAssertion";

    // Initial reserves
    uint256 public initialReserve0 = 1000 ether;
    uint256 public initialReserve1 = 1000 ether;

    // New reserves for testing
    uint256 public newReserve0 = 2000 ether;
    uint256 public newReserve1 = 500 ether;

    // Valid new reserves that maintain the constant product
    uint256 public validReserve0 = 2000 ether;
    uint256 public validReserve1 = 500 ether;

    function setUp() public {
        // Initialize protocol with initial reserves
        protocol = new ConstantProductAmm(initialReserve0, initialReserve1);

        // Update valid reserves to maintain constant product (k = 1000 * 1000 = 1,000,000)
        // 2000 * 500 = 1,000,000

        // Give the user some ETH
        vm.deal(user, 100 ether);
    }

    function test_assertionConstantProductMaintained() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        // The assertion will trigger on changes to either reserve slot
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(ConstantProductAssertion).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);
        // This should pass because the new reserves maintain the constant product
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.setReserves.selector, abi.encode(validReserve0, validReserve1))
        );
    }

    function test_assertionConstantProductViolated() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        // The assertion simply checks pre/post state since we can't reliably track
        // intra-transaction violations with current tooling
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(ConstantProductAssertion).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);
        // This should revert because invalid reserves violate the constant product
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.setReserves.selector, abi.encode(newReserve0, newReserve1 + 1 ether))
        );
    }
}
