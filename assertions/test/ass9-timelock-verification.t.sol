// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {TimelockVerification} from "../../src/ass9-timelock-verification.sol";
import {TimelockVerificationAssertion} from "../src/ass9-timelock-verification.a.sol";

contract TestTimelockVerification is CredibleTest, Test {
    TimelockVerification public protocol;
    address public user = address(0xbeef);
    string constant ASSERTION_LABEL = "TimelockVerificationAssertion";

    function setUp() public {
        protocol = new TimelockVerification();
        vm.deal(user, 100 ether);
    }

    function test_assertionTimelockInvalidDelay() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(TimelockVerificationAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(user);
        // This should revert because delay is too short
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(protocol.setTimelock.selector, abi.encode(12 hours))
        );
    }

    function test_assertionTimelockValidDelay() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(TimelockVerificationAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(user);
        // This should pass because delay is within bounds
        cl.validate(
            ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(protocol.setTimelock.selector, abi.encode(1 days))
        );
    }

    function test_assertionTimelockAlreadyActive() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(TimelockVerificationAssertion).creationCode, abi.encode(protocol)
        );

        // First activate the timelock
        vm.prank(user);
        protocol.activateTimelock();

        // This should pass because timelock was already active and we don't care about the delay
        vm.prank(user);
        cl.validate(
            ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(protocol.setTimelock.selector, abi.encode(2 days))
        );
    }
}
