// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {TokenVault, MockERC20} from "../../src/ass20-erc20-drain.sol";
import {ERC20DrainAssertion} from "../src/ass20-erc20-drain.a.sol";

contract TestERC20Drain is CredibleTest, Test {
    // Contract state variables
    TokenVault public protocol;
    MockERC20 public token;
    address public user = address(0x1234);
    string constant ASSERTION_LABEL = "ERC20DrainAssertion";

    // Constants for token supplies and transfers
    uint256 public constant INITIAL_SUPPLY = 1000000 ether;
    uint256 public constant PROTOCOL_BALANCE = 100000 ether;
    uint256 public constant SMALL_WITHDRAWAL = 5000 ether; // 5% of balance
    uint256 public constant LARGE_WITHDRAWAL = 15000 ether; // 15% of balance

    function setUp() public {
        // Create token and protocol
        token = new MockERC20("Test Token", "TEST", 18, INITIAL_SUPPLY);
        protocol = new TokenVault(address(token));

        // Setup user
        vm.deal(user, 100 ether);

        // Fund the protocol with tokens
        token.transfer(address(protocol), PROTOCOL_BALANCE);

        // Give user some tokens and approval to protocol
        token.transfer(user, PROTOCOL_BALANCE);
        vm.prank(user);
        token.approve(address(protocol), type(uint256).max);
    }

    function test_assertionDrainWithinLimit() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL,
            protocolAddress,
            type(ERC20DrainAssertion).creationCode,
            abi.encode(address(token), protocolAddress)
        );

        // Set user as the caller
        vm.prank(user);
        // This should pass because we're withdrawing less than 10% of balance
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.withdraw.selector, abi.encode(user, SMALL_WITHDRAWAL))
        );
    }

    function test_assertionDrainExceedsLimit() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL,
            protocolAddress,
            type(ERC20DrainAssertion).creationCode,
            abi.encode(address(token), protocolAddress)
        );

        // Set user as the caller
        vm.prank(user);
        // This should revert because we're withdrawing more than 10% of balance
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.withdraw.selector, abi.encode(user, LARGE_WITHDRAWAL))
        );
    }

    function test_assertionDepositDoesNotRevert() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL,
            protocolAddress,
            type(ERC20DrainAssertion).creationCode,
            abi.encode(address(token), protocolAddress)
        );

        // Set user as the caller
        vm.prank(user);
        // This should pass because we're depositing tokens, not withdrawing
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.deposit.selector, abi.encode(LARGE_WITHDRAWAL))
        );
    }
}
