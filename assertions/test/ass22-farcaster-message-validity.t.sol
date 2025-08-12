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
        cl.assertion({
            adopter: address(protocol),
            createData: type(FarcasterProtocolAssertion).creationCode,
            fnSelector: FarcasterProtocolAssertion.assertMessageValidity.selector
        });

        // Add time to avoid rate limit issues
        vm.warp(block.timestamp + 2 minutes);

        vm.prank(user);
        // This should revert because the message is invalid
        vm.expectRevert("Invalid author: zero address");
        protocol.postMessage(invalidMessage);
    }

    function test_assertionValidMessage() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(FarcasterProtocolAssertion).creationCode,
            fnSelector: FarcasterProtocolAssertion.assertMessageValidity.selector
        });

        // Set the timestamp to a future time to avoid rate limit violations
        // The assertion checks that current timestamp is >= lastPostTime + POST_COOLDOWN
        vm.warp(block.timestamp + 2 minutes);

        vm.prank(user);
        // This should pass because the message is valid
        protocol.postMessage(validMessage);
    }

    // TODO: This is panicking the application due to the slicing error
    function test_assertionUsernameUniqueness() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(FarcasterProtocolAssertion).creationCode,
            fnSelector: FarcasterProtocolAssertion.assertUniqueUsername.selector
        });

        vm.prank(user);
        // This should revert because the username is already registered
        vm.expectRevert("Security violation: username already registered");
        protocol.register(existingUsername, user);
    }

    function test_assertionNewUsername() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(FarcasterProtocolAssertion).creationCode,
            fnSelector: FarcasterProtocolAssertion.assertUniqueUsername.selector
        });

        vm.prank(user);
        // This should pass because it's a new username
        protocol.register(testUsername, user);
    }

    // TODO: This is panicking the application due to the slicing error
    function test_assertionRateLimit() public {
        // Add time to avoid initial rate limit issues
        vm.warp(block.timestamp + 2 minutes);

        // First, post a message to set the last post timestamp
        vm.prank(user);
        protocol.postMessage(validMessage);
        cl.assertion({
            adopter: address(protocol),
            createData: type(FarcasterProtocolAssertion).creationCode,
            fnSelector: FarcasterProtocolAssertion.assertRateLimit.selector
        });

        // Jump forward, but not enough to pass the cooldown
        skip(30 seconds); // Cooldown is 1 minute in the assertion

        vm.prank(user);
        // This should revert because we're posting too quickly
        vm.expectRevert("Rate limit violation: posting too frequently");
        protocol.postMessage(messageForRateLimit);
    }

    function test_assertionRateLimitPassing() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(FarcasterProtocolAssertion).creationCode,
            fnSelector: FarcasterProtocolAssertion.assertRateLimit.selector
        });

        // Add time to avoid initial rate limit issues
        vm.warp(block.timestamp + 2 minutes);

        // First, post a message to set the last post timestamp
        vm.prank(user);
        protocol.postMessage(validMessage);

        // Jump forward enough to pass the cooldown
        skip(90 seconds); // Cooldown is 1 minute in the assertion

        vm.prank(user);
        // This should pass because we've waited long enough
        protocol.postMessage(messageForRateLimit);
    }
}
