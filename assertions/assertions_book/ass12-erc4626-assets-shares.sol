// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

interface IERC4626 {
    function totalAssets() external view returns (uint256);

    function totalShares() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);
}

contract ERC4626AssetsSharesAssertion is Assertion {
    IERC4626 public erc4626 = IERC4626(address(0xbeef));

    function triggers() external view override {
        registerCallTrigger(this.assertionAssetsShares.selector);
    }

    // Make sure that the total shares are not more than the total assets
    // revert if total shares is greater than total assets
    function assertionAssetsShares() external {
        ph.forkPostState();
        uint256 totalAssets = erc4626.totalAssets();
        uint256 totalShares = erc4626.totalShares();
        uint256 totalAssetsInShares = erc4626.convertToShares(totalAssets);
        require(totalShares == 0 || totalAssetsInShares >= totalShares, "Total shares is greater than total assets"); // edge case: total shares is 0
    }
}
