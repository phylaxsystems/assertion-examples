// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

interface IERC4626 {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
}

contract ERC4626AssetsSharesAssertion is Assertion {
    IERC4626 public vault = IERC4626(address(0xbeef));

    function triggers() external view override {
        // Register trigger specifically for changes to the total supply storage slot
        // This is more gas efficient than triggering on all storage changes
        registerStorageChangeTrigger(
            this.assertionAssetsShares.selector,
            bytes32(uint256(1)) // Total supply storage slot
        );
    }

    // Assert that the total shares are not more than the total assets
    function assertionAssetsShares() external {
        // First check: Simple pre/post state comparison
        ph.forkPreState();
        uint256 preTotalAssets = vault.totalAssets();
        uint256 preTotalShares = vault.totalSupply();
        uint256 preTotalAssetsInShares = vault.convertToShares(preTotalAssets);

        ph.forkPostState();
        uint256 postTotalAssets = vault.totalAssets();
        uint256 postTotalShares = vault.totalSupply();
        uint256 postTotalAssetsInShares = vault.convertToShares(postTotalAssets);

        // Basic invariant check
        require(postTotalAssetsInShares >= postTotalShares, "Total shares exceeds total assets in shares");

        // Second check: Monitor changes to total supply to catch manipulation attempts
        uint256[] memory shareChanges = getStateChangesUint(
            address(vault),
            bytes32(uint256(1)) // Total supply storage slot
        );

        // For each share change, verify against the current total assets
        for (uint256 i = 0; i < shareChanges.length; i++) {
            uint256 assetsInShares = vault.convertToShares(postTotalAssets);
            require(assetsInShares >= shareChanges[i], "Intermediate state violates shares/assets invariant");
        }
    }
}
