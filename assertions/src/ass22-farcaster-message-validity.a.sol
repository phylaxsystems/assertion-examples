// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract FarcasterProtocolAssertion is Assertion {
    // Constants
    uint256 constant MAX_CONTENT_LENGTH = 320; // Farcaster's max message length
    uint256 constant POST_COOLDOWN = 1 minutes;

    function triggers() external view override {
        // Register trigger for message validity on postMessage calls
        registerCallTrigger(this.assertMessageValidity.selector, IFarcaster.postMessage.selector);

        // Register trigger for username uniqueness on register calls
        registerCallTrigger(this.assertUniqueUsername.selector, IFarcaster.register.selector);

        // Register trigger for rate limits on postMessage calls
        registerCallTrigger(this.assertRateLimit.selector, IFarcaster.postMessage.selector);
    }

    function assertMessageValidity() external {
        // Get the assertion adopter address
        IFarcaster adopter = IFarcaster(ph.getAssertionAdopter());

        // Get all calls to postMessage function
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.postMessage.selector);

        for (uint256 i = 0; i < callInputs.length; i++) {
            // Decode the message parameters from the call data
            IFarcaster.Message memory message = abi.decode(callInputs[i].input, (IFarcaster.Message));

            // Examine state after the message is posted to ensure all validations pass
            ph.forkPostTx();

            // Check basic message validity requirements
            require(message.author != address(0), "Invalid author: zero address");
            require(message.content.length > 0, "Invalid message: empty content");
            require(message.content.length <= MAX_CONTENT_LENGTH, "Invalid message: content exceeds max length");
            require(message.timestamp > 0, "Invalid message: missing timestamp");
            require(message.signature.length > 0, "Invalid message: missing signature");

            // Verify cryptographic signature is valid for the message
            require(adopter.verifySignature(message), "Security violation: invalid signature");

            // Check protocol-specific validation rules
            require(adopter.isValidMessage(message), "Message failed protocol validation");
        }
    }

    function assertUniqueUsername() external {
        // Get the assertion adopter address
        IFarcaster adopter = IFarcaster(ph.getAssertionAdopter());

        // Get all calls to register function
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.register.selector);

        for (uint256 i = 0; i < callInputs.length; i++) {
            // Decode registration parameters
            (string memory username, address owner) = abi.decode(callInputs[i].input, (string, address));

            // Check pre-registration state to ensure username isn't already taken
            ph.forkPreCall(callInputs[i].id);
            require(!adopter.isRegistered(username), "Security violation: username already registered");

            // Check post-registration state to ensure registration succeeded and owner is correct
            ph.forkPostCall(callInputs[i].id);
            require(adopter.isRegistered(username), "Registration failed to complete");
            require(
                adopter.getUsernameOwner(username) == owner, "Security violation: owner mismatch after registration"
            );
        }
    }

    function assertRateLimit() external {
        // Get the assertion adopter address
        IFarcaster adopter = IFarcaster(ph.getAssertionAdopter());

        // Get all calls to postMessage function
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.postMessage.selector);

        for (uint256 i = 0; i < callInputs.length; i++) {
            // Decode the message to get author
            IFarcaster.Message memory message = abi.decode(callInputs[i].input, (IFarcaster.Message));

            address user = message.author;

            // Check state before posting to validate rate limits
            ph.forkPreCall(callInputs[i].id);

            // Ensure cooldown between posts is respected
            uint256 lastPostTime = adopter.getLastPostTimestamp(user);
            require(block.timestamp >= lastPostTime + POST_COOLDOWN, "Rate limit violation: posting too frequently");
        }
    }
}

interface IFarcaster {
    // Message struct and functions
    struct Message {
        uint256 id;
        address author;
        bytes content;
        uint256 timestamp;
        bytes signature;
    }

    function isValidMessage(Message memory message) external view returns (bool);
    function verifySignature(Message memory message) external view returns (bool);
    function postMessage(Message memory message) external;

    // Username functions
    function register(string calldata username, address owner) external;
    function isRegistered(string calldata username) external view returns (bool);
    function getUsernameOwner(string calldata username) external view returns (address);

    // Rate limit functions
    function getLastPostTimestamp(address user) external view returns (uint256);
}
