// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {TimelockVerification} from "../../src/ass9-timelock-verification.sol";
import {TimelockVerificationAssertion} from "../src/ass9-timelock-verification.a.sol";

contract TestTimelockVerification is CredibleTest, Test {
    TimelockVerification public protocol;
    address public user = address(0xbeef);

    function setUp() public {
        protocol = new TimelockVerification();
        vm.deal(user, 100 ether);
    }

    function test_assertionTimelockInvalidDelay() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(TimelockVerificationAssertion).creationCode,
            fnSelector: TimelockVerificationAssertion.assertionTimelock.selector
        });

        vm.prank(user);
        // This should revert because delay is too short
        vm.expectRevert("Timelock parameters invalid");
        protocol.setTimelock(12 hours);
    }

    function test_assertionTimelockValidDelay() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(TimelockVerificationAssertion).creationCode,
            fnSelector: TimelockVerificationAssertion.assertionTimelock.selector
        });

        vm.prank(user);
        // This should pass because delay is within bounds
        protocol.setTimelock(1 days);
    }

    function test_assertionTimelockAlreadyActive() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(TimelockVerificationAssertion).creationCode,
            fnSelector: TimelockVerificationAssertion.assertionTimelock.selector
        });

        // First activate the timelock
        vm.prank(user);
        protocol.activateTimelock();

        // This should pass because timelock was already active and we don't care about the delay
        vm.prank(user);
        protocol.setTimelock(2 days);
    }
}
