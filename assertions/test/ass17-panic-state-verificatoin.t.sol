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
        address protocolAddress = address(protocol);
        string memory label = "Panicked state verification";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(EmergencyStateAssertion).creationCode, abi.encode(protocol));

        // Set the protocol to paused state
        protocol.setPaused(true);

        // Withdraw funds - should pass since balance is decreasing
        vm.prank(user);
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.withdraw.selector, abi.encode(500 ether)));
    }

    function test_assertionPanickedBalanceIncreases() public {
        address protocolAddress = address(protocol);
        string memory label = "Panicked state verification";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(EmergencyStateAssertion).creationCode, abi.encode(protocol));

        // Set the protocol to paused state
        protocol.setPaused(true);

        // Deposit funds - should revert since balance is increasing during pause
        vm.prank(user);
        vm.expectRevert("Assertions Reverted");
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.deposit.selector, abi.encode(100 ether)));
    }

    function test_assertionNotPanickedBalanceIncreases() public {
        address protocolAddress = address(protocol);
        string memory label = "Not panicked state verification";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(EmergencyStateAssertion).creationCode, abi.encode(protocol));

        // Make sure protocol is not paused
        protocol.setPaused(false);

        // Deposit funds - should pass since protocol is not paused
        vm.prank(user);
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.deposit.selector, abi.encode(100 ether)));
    }
}
