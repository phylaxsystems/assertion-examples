// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract ERC4626AssetsSharesAssertion is Assertion {
    function triggers() external view override {
        // Register trigger specifically for changes to the total supply storage slot
        registerStorageChangeTrigger(
            this.assertionAssetsShares.selector,
            bytes32(uint256(1)) // Total supply storage slot
        );
    }

    // Assert that the total assets are sufficient to back all shares
    function assertionAssetsShares() external view {
        // Get the assertion adopter address
        IERC4626 adopter = IERC4626(ph.getAssertionAdopter());

        uint256 totalAssets = adopter.totalAssets();
        uint256 totalSupply = adopter.totalSupply();

        // Calculate how many assets are needed to back all shares
        uint256 requiredAssets = adopter.convertToAssets(totalSupply);

        // The total assets should be at least what's needed to back all shares
        require(totalAssets >= requiredAssets, "Not enough assets to back all shares");
    }
}

interface IERC4626 {
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function convertToShares(uint256 assets) external view returns (uint256);
    function convertToAssets(uint256 shares) external view returns (uint256);
}
