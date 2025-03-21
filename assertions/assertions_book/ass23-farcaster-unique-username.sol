// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";
import {PhEvm} from "../../lib/credible-std/src/PhEvm.sol";

interface IFarcaster {
    function register(string calldata username, address owner) external;
    function isRegistered(string calldata username) external view returns (bool);
    function getUsernameOwner(string calldata username) external view returns (address);
}

contract FarcasterUsernameAssertion is Assertion {
    IFarcaster public farcaster = IFarcaster(address(0xbeef));

    function triggers() external view override {
        registerCallTrigger(this.assertUniqueUsername.selector);
    }

    function assertUniqueUsername() external {
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(farcaster), farcaster.register.selector);
        if (callInputs.length == 0) {
            return;
        }

        for (uint256 i = 0; i < callInputs.length; i++) {
            bytes memory data = callInputs[i].input;

            // Decode registration parameters
            (string memory username, address owner) = abi.decode(stripSelector(data), (string, address));

            // Check pre-registration state
            ph.forkPreState();
            require(!farcaster.isRegistered(username), "Username already registered");

            // Check post-registration state
            ph.forkPostState();
            require(farcaster.isRegistered(username), "Registration failed");

            require(farcaster.getUsernameOwner(username) == owner, "Owner mismatch");
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
