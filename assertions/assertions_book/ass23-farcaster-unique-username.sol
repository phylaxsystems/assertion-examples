// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/Assertion.sol";

interface IFarcaster {
    function register(string calldata username, address owner) external;
    function isRegistered(string calldata username) external view returns (bool);
    function getUsernameOwner(string calldata username) external view returns (address);
}

contract FarcasterUsernameAssertion is Assertion {
    IFarcaster public farcaster = IFarcaster(address(0xbeef));

    bytes4 constant REGISTER = bytes4(keccak256("register(string,address)"));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1);
        assertions[0] = this.assertUniqueUsername.selector;
    }

    function assertUniqueUsername() external {
        (,,, bytes memory data) = ph.getData();
        bytes4 selector = bytes4(data[:4]);

        if (selector != REGISTER) {
            return;
        }

        // Decode registration parameters
        (string memory username, address owner) = abi.decode(data[4:], (string, address));

        // Check pre-registration state
        ph.forkPreState();
        require(!farcaster.isRegistered(username), "Username already registered");

        // Check post-registration state
        ph.forkPostState();
        require(farcaster.isRegistered(username), "Registration failed");

        require(farcaster.getUsernameOwner(username) == owner, "Owner mismatch");
    }
}
