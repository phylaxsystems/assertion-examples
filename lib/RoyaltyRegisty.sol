// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

// This contract is not implemented well on purpose
// Contract is used for example purposes
// Source: https://scsfg.io/hackers/abi-hash-collisions/
contract RoyaltyRegistry {
    uint256 constant regularPayout = 0.1 ether;
    uint256 constant premiumPayout = 1 ether;
    mapping (bytes32 => bool) allowedPayouts;

    function claimRewards(address[] calldata privileged, address[] calldata regular) external {
        bytes32 payoutKey = keccak256(abi.encodePacked(privileged, regular));
        require(allowedPayouts[payoutKey], "Unauthorized claim");
        allowedPayouts[payoutKey] = false;
        _payout(privileged, premiumPayout);
        _payout(regular, regularPayout);
    }

    function _payout(address[] calldata users, uint256 reward) internal {
        for(uint i = 0; i < users.length;) {
            (bool success, ) = users[i].call{value: reward}("");
            if (!success) {
                // more code handling pull payment
            }
            unchecked {
                ++i;
            }
        }
    }
}