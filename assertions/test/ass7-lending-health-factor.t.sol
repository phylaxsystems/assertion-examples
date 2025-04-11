// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {LendingHealthFactor} from "../../src/ass7-lending-health-factor.sol";
import {LendingHealthFactorAssertion} from "../src/ass7-lending-health-factor.a.sol";

contract TestLendingHealthFactorAssertion is CredibleTest, Test {
    LendingHealthFactor public protocol;
    address public user = address(0x1234);

    function setUp() public {
        protocol = new LendingHealthFactor();
        vm.deal(user, 100 ether);
    }

    function test_assertionHealthyPosition() public {
        address protocolAddress = address(protocol);
        string memory label = "Position remains healthy";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(LendingHealthFactorAssertion).creationCode, abi.encode(protocol));

        vm.prank(user);
        // This should pass because the position remains healthy
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.supply.selector, abi.encode(1, 100)));
    }

    function test_assertionUnhealthyPosition() public {
        address protocolAddress = address(protocol);
        string memory label = "Position becomes unhealthy";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(LendingHealthFactorAssertion).creationCode, abi.encode(protocol));

        // First make the position unhealthy
        protocol.setHealthStatus(false);

        vm.prank(user);
        // This should revert because the position is unhealthy
        vm.expectRevert("Assertions Reverted");
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.borrow.selector, abi.encode(1, 100)));
    }
}
