// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Farcaster} from "../../src/ass22-farcaster-message-validity.sol";
import {FarcasterProtocolAssertion} from "../src/ass22-farcaster-message-validity.a.sol";

contract TestFarcasterMessageValidity is CredibleTest, Test {
    // Contract state variables
    Farcaster public protocol;
    address public user = address(0x1234);
    string public testUsername = "testUser";
    string public existingUsername = "existingUser";
    address public existingUserAddress = address(0xbeef);
    string constant ASSERTION_LABEL = "FarcasterProtocolAssertion";

    // Message variables
    Farcaster.Message validMessage;
    Farcaster.Message invalidMessage;
    Farcaster.Message messageForRateLimit;

    function setUp() public {
        // Deploy the protocol
        protocol = new Farcaster();

        // Register an existing user for testing
        protocol.register(existingUsername, existingUserAddress);

        // Give the test user some ETH
        vm.deal(user, 100 ether);

        // Initialize test messages
        validMessage = Farcaster.Message({
            id: 1,
            author: user,
            content: "This is a valid test message",
            timestamp: block.timestamp,
            signature: "0xvalidsignature"
        });

        invalidMessage = Farcaster.Message({
            id: 2,
            author: address(0), // Invalid author (zero address)
            content: "invalid content", // Invalid content marker
            timestamp: 0, // Invalid timestamp
            signature: "invalidSignature" // Invalid signature marker
        });

        messageForRateLimit = Farcaster.Message({
            id: 3,
            author: user,
            content: "This message tests rate limiting",
            timestamp: block.timestamp,
            signature: "0xanothersignature"
        });
    }

    function test_assertionMessageValidity() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(FarcasterProtocolAssertion).creationCode, abi.encode(protocol)
        );

        // Add time to avoid rate limit issues
        vm.warp(block.timestamp + 2 minutes);

        vm.prank(user);
        // This should revert because the message is invalid
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.postMessage.selector, abi.encode(invalidMessage))
        );
    }

    function test_assertionValidMessage() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(FarcasterProtocolAssertion).creationCode, abi.encode(protocol)
        );

        // Set the timestamp to a future time to avoid rate limit violations
        // The assertion checks that current timestamp is >= lastPostTime + POST_COOLDOWN
        vm.warp(block.timestamp + 2 minutes);

        vm.prank(user);
        // This should pass because the message is valid
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.postMessage.selector, abi.encode(validMessage))
        );
    }

    function test_assertionUsernameUniqueness() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(FarcasterProtocolAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(user);
        // This should revert because the username is already registered
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.register.selector, abi.encode(existingUsername, user))
        );
    }

    function test_assertionNewUsername() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(FarcasterProtocolAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(user);
        // This should pass because it's a new username
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.register.selector, abi.encode(testUsername, user))
        );
    }

    function test_assertionRateLimit() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(FarcasterProtocolAssertion).creationCode, abi.encode(protocol)
        );

        // Add time to avoid initial rate limit issues
        vm.warp(block.timestamp + 2 minutes);

        // First, post a message to set the last post timestamp
        vm.prank(user);
        protocol.postMessage(validMessage);

        // Jump forward, but not enough to pass the cooldown
        skip(30 seconds); // Cooldown is 1 minute in the assertion

        vm.prank(user);
        // This should revert because we're posting too quickly
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.postMessage.selector, abi.encode(messageForRateLimit))
        );
    }

    function test_assertionRateLimitPassing() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(FarcasterProtocolAssertion).creationCode, abi.encode(protocol)
        );

        // Add time to avoid initial rate limit issues
        vm.warp(block.timestamp + 2 minutes);

        // First, post a message to set the last post timestamp
        vm.prank(user);
        protocol.postMessage(validMessage);

        // Jump forward enough to pass the cooldown
        skip(90 seconds); // Cooldown is 1 minute in the assertion

        vm.prank(user);
        // This should pass because we've waited long enough
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.postMessage.selector, abi.encode(messageForRateLimit))
        );
    }
}
