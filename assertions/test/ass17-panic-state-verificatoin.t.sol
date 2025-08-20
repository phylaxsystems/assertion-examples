// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {EmergencyStateAssertion} from "../src/ass17-panic-state-verificatoin.a.sol";
import {EmergencyPausable} from "../../src/ass17-panic-state-verificatoin.sol";

contract TestPanicStateVerification is CredibleTest, Test {
    // Contract state variables
    EmergencyPausable public protocol;
    address public user = address(0x1234);
    uint256 public initialBalance = 1000 ether;

    function setUp() public {
        // Initialize the protocol with an initial balance
        protocol = new EmergencyPausable(initialBalance);
        vm.deal(user, 100 ether);
    }

    function test_assertionPanickedBalanceDecreases() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(EmergencyStateAssertion).creationCode,
            fnSelector: EmergencyStateAssertion.assertionPanickedCanOnlyDecreaseBalance.selector
        });

        // Set the protocol to paused state
        protocol.setPaused(true);

        // Withdraw funds - should pass since balance is decreasing
        vm.prank(user);
        protocol.withdraw(500 ether);
    }

    function test_assertionPanickedBalanceIncreases() public {
        // Set the protocol to paused state
        protocol.setPaused(true);

        cl.assertion({
            adopter: address(protocol),
            createData: type(EmergencyStateAssertion).creationCode,
            fnSelector: EmergencyStateAssertion.assertionPanickedCanOnlyDecreaseBalance.selector
        });

        // Deposit funds - should revert since balance is increasing during pause
        vm.prank(user);
        vm.expectRevert("Balance can only decrease when panicked");
        protocol.deposit(100 ether);
    }

    function test_assertionNotPanickedBalanceIncreases() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(EmergencyStateAssertion).creationCode,
            fnSelector: EmergencyStateAssertion.assertionPanickedCanOnlyDecreaseBalance.selector
        });

        // Make sure protocol is not paused
        protocol.setPaused(false);

        // Deposit funds - should pass since protocol is not paused
        vm.prank(user);
        protocol.deposit(100 ether);
    }
}
