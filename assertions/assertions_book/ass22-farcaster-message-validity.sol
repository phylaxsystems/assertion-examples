// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";
import {PhEvm} from "../../lib/credible-std/src/PhEvm.sol";

interface IFarcaster {
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
}

contract FarcasterMessageAssertion is Assertion {
    IFarcaster public farcaster = IFarcaster(address(0xbeef));

    bytes4 constant POST_MESSAGE = bytes4(keccak256("postMessage((uint256,address,bytes,uint256,bytes))"));
    uint256 constant MAX_CONTENT_LENGTH = 320; // Farcaster's max message length

    function triggers() external view override {
        registerCallTrigger(this.assertMessageValidity.selector);
    }

    function assertMessageValidity() external {
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(farcaster), farcaster.postMessage.selector);
        if (callInputs.length == 0) {
            return;
        }

        for (uint256 i = 0; i < callInputs.length; i++) {
            bytes memory data = callInputs[i].input;

            // Decode the message
            IFarcaster.Message memory message = abi.decode(stripSelector(data), (IFarcaster.Message));

            ph.forkPostState();

            // Check basic message validity
            require(message.author != address(0), "Invalid author");
            require(message.content.length > 0, "Empty content");
            require(message.content.length <= MAX_CONTENT_LENGTH, "Content too long");
            require(message.timestamp > 0, "Invalid timestamp");
            require(message.signature.length > 0, "Missing signature");

            // Verify message signature
            require(farcaster.verifySignature(message), "Invalid signature");

            // Check overall message validity
            require(farcaster.isValidMessage(message), "Message failed validation");
        }
    }

    function stripSelector(bytes memory input) internal pure returns (bytes memory) {
        bytes memory paramData = new bytes(32);
        for (uint256 i = 4; i < input.length; i++) {
            paramData[i - 4] = input[i];
        }
        return paramData;
    }
}
