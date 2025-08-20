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
        cl.assertion({
            adopter: address(protocol),
            createData: type(EtherDrainAssertion).creationCode,
            fnSelector: EtherDrainAssertion.assertionEtherDrain.selector
        });

        vm.prank(user);
        // This should pass because we're draining less than the max percentage (10 ETH = 10%)
        protocol.withdrawToTreasury(9 ether);
    }

    function test_assertionLargeEtherDrainToWhitelisted() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(EtherDrainAssertion).creationCode,
            fnSelector: EtherDrainAssertion.assertionEtherDrain.selector
        });

        vm.prank(user);
        // This should revert because we're sending more than 10% (simplified assertion)
        vm.expectRevert("Large ETH drain detected - exceeds allowed percentage");
        protocol.withdrawToAddress(whitelistedAddress, 20 ether);
    }

    function test_assertionLargeEtherDrainToNonWhitelisted() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(EtherDrainAssertion).creationCode,
            fnSelector: EtherDrainAssertion.assertionEtherDrain.selector
        });

        vm.prank(user);
        // This should revert because we're sending more than 10% to a non-whitelisted address
        vm.expectRevert("Large ETH drain detected - exceeds allowed percentage");
        protocol.withdrawToAddress(treasury, 20 ether);
    }

    function test_assertionFullDrainToWhitelisted() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(EtherDrainAssertion).creationCode,
            fnSelector: EtherDrainAssertion.assertionEtherDrain.selector
        });

        vm.prank(user);
        // This should revert because we're draining everything (more than 10%)
        vm.expectRevert("Large ETH drain detected - exceeds allowed percentage");
        protocol.drainToAddress(whitelistedAddress);
    }

    function test_assertionFullDrainToNonWhitelisted() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(EtherDrainAssertion).creationCode,
            fnSelector: EtherDrainAssertion.assertionEtherDrain.selector
        });

        vm.prank(user);
        // This should revert because we're draining everything to a non-whitelisted address
        vm.expectRevert("Large ETH drain detected - exceeds allowed percentage");
        protocol.drainToOwner();
    }
}
