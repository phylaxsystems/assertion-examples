// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {EtherDrainAssertion} from "../src/ass21-ether-drain.a.sol";
import {EtherDrain} from "../../src/ass21-ether-drain.sol";

contract TestEtherDrain is CredibleTest, Test {
    // Contract state variables
    EtherDrain public protocol;
    address payable public treasury = payable(address(0xdead));
    address payable public owner = payable(address(0xbeef));
    address payable public user = payable(address(0x1234));
    address payable public whitelistedAddress = payable(address(0xacab));

    // Max drain percentage for tests
    uint256 public constant MAX_DRAIN_PERCENTAGE = 10; // 10%

    function setUp() public {
        protocol = new EtherDrain(treasury, owner);

        // Fund the protocol contract with some ETH
        vm.deal(address(protocol), 100 ether);

        // Fund the user with some ETH
        vm.deal(user, 10 ether);
    }

    function test_assertionSmallEtherDrain() public {
        address protocolAddress = address(protocol);
        string memory label = "Small ether drain";

        // Create whitelist array with the owner address
        address[] memory whitelist = new address[](1);
        whitelist[0] = owner;

        // Associate the assertion with the protocol
        cl.addAssertion(
            label,
            protocolAddress,
            type(EtherDrainAssertion).creationCode,
            abi.encode(protocol, MAX_DRAIN_PERCENTAGE, whitelist)
        );

        vm.prank(user);
        // This should pass because we're draining less than the max percentage (10 ETH = 10%)
        cl.validate(
            label, protocolAddress, 0, abi.encodePacked(protocol.withdrawToTreasury.selector, abi.encode(9 ether))
        );
    }

    function test_assertionLargeEtherDrainToWhitelisted() public {
        address protocolAddress = address(protocol);
        string memory label = "Large ether drain to whitelisted";

        // Create whitelist array with the whitelisted address
        address[] memory whitelist = new address[](1);
        whitelist[0] = whitelistedAddress;

        // Associate the assertion with the protocol
        cl.addAssertion(
            label,
            protocolAddress,
            type(EtherDrainAssertion).creationCode,
            abi.encode(protocol, MAX_DRAIN_PERCENTAGE, whitelist)
        );

        vm.prank(user);
        // This should pass because we're sending to a whitelisted address, even though it's more than 10%
        cl.validate(
            label,
            protocolAddress,
            0,
            abi.encodePacked(protocol.withdrawToAddress.selector, abi.encode(whitelistedAddress, 20 ether))
        );
    }

    function test_assertionLargeEtherDrainToNonWhitelisted() public {
        address protocolAddress = address(protocol);
        string memory label = "Large ether drain to non-whitelisted";

        // Create whitelist array with a different address
        address[] memory whitelist = new address[](1);
        whitelist[0] = whitelistedAddress;

        // Associate the assertion with the protocol
        cl.addAssertion(
            label,
            protocolAddress,
            type(EtherDrainAssertion).creationCode,
            abi.encode(protocol, MAX_DRAIN_PERCENTAGE, whitelist)
        );

        vm.prank(user);
        // This should revert because we're sending more than 10% to a non-whitelisted address
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label,
            protocolAddress,
            0,
            abi.encodePacked(protocol.withdrawToAddress.selector, abi.encode(treasury, 20 ether))
        );
    }

    function test_assertionFullDrainToWhitelisted() public {
        address protocolAddress = address(protocol);
        string memory label = "Full drain to whitelisted";

        // Create whitelist array with the whitelisted address
        address[] memory whitelist = new address[](1);
        whitelist[0] = whitelistedAddress;

        // Associate the assertion with the protocol
        cl.addAssertion(
            label,
            protocolAddress,
            type(EtherDrainAssertion).creationCode,
            abi.encode(protocol, MAX_DRAIN_PERCENTAGE, whitelist)
        );

        vm.prank(user);
        // This should pass because we're draining to a whitelisted address
        cl.validate(
            label,
            protocolAddress,
            0,
            abi.encodePacked(protocol.drainToAddress.selector, abi.encode(whitelistedAddress))
        );
    }

    function test_assertionFullDrainToNonWhitelisted() public {
        address protocolAddress = address(protocol);
        string memory label = "Full drain to non-whitelisted";

        // Create empty whitelist array
        address[] memory whitelist = new address[](0);

        // Associate the assertion with the protocol
        cl.addAssertion(
            label,
            protocolAddress,
            type(EtherDrainAssertion).creationCode,
            abi.encode(protocol, MAX_DRAIN_PERCENTAGE, whitelist)
        );

        vm.prank(user);
        // This should revert because we're draining everything to a non-whitelisted address
        vm.expectRevert("Assertions Reverted");
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.drainToOwner.selector));
    }
}
