// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Lending} from "../../src/ass8-positions-sum.sol";
import {PositionSumAssertion} from "../src/ass8-positions-sum.a.sol";

contract TestPositionSumAssertion is CredibleTest, Test {
    // Contract state variables
    Lending public protocol;
    address public user1 = address(0xdead);
    address public user2 = address(0xbeef);
    uint256 public depositAmount1 = 100 ether;
    uint256 public depositAmount2 = 50 ether;
    string constant ASSERTION_LABEL = "PositionSumAssertion";

    function setUp() public {
        protocol = new Lending();
        // Give users some ETH
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
    }

    function test_assertionValidDeposit() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(ASSERTION_LABEL, protocolAddress, type(PositionSumAssertion).creationCode, abi.encode(protocol));

        // Make a valid deposit
        vm.prank(user1);
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.deposit.selector, abi.encode(user1, depositAmount1))
        );
    }

    function test_assertionInvalidDeposit() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(ASSERTION_LABEL, protocolAddress, type(PositionSumAssertion).creationCode, abi.encode(protocol));

        // Make a deposit of 42 ether, which will trigger the special case
        // where total supply increases by 43 ether instead
        vm.prank(user1);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.deposit.selector, abi.encode(user1, 42 ether))
        );
    }

    function test_assertionMultipleDeposits() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(ASSERTION_LABEL, protocolAddress, type(PositionSumAssertion).creationCode, abi.encode(protocol));

        // Create a batch depositor that will make multiple deposits
        BatchDeposits batchDepositor = new BatchDeposits(address(protocol));

        // Execute the batch deposits
        vm.prank(user1);
        cl.validate(
            ASSERTION_LABEL,
            address(batchDepositor),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }
}

contract BatchDeposits {
    Lending public lending;

    constructor(address lending_) {
        lending = Lending(lending_);
    }

    fallback() external {
        // Make multiple deposits in a single transaction
        lending.deposit(address(0xdead), 100 ether); // Deposit for user1
        lending.deposit(address(0xbeef), 50 ether); // Deposit for user2
        lending.deposit(address(0xdead), 100 ether); // Deposit for user1
        lending.deposit(address(0xdead), 100 ether); // Deposit for user1
        lending.deposit(address(0xdead), 100 ether); // Deposit for user1
        lending.deposit(address(0xdead), 100 ether); // Deposit for user1
        lending.deposit(address(0xdead), 100 ether); // Deposit for user1
        lending.deposit(address(0xdead), 100 ether); // Deposit for user1
        lending.deposit(address(0xdead), 100 ether); // Deposit for user1
        lending.deposit(address(0xdead), 100 ether); // Deposit for user1
    }
}
