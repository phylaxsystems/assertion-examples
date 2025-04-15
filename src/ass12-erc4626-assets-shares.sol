// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Simple Vault
 * @notice A simple vault for testing assets and shares assertions
 * @dev Uses a simple ratio calculation for assets to shares conversion
 */
contract ERC4626Vault {
    // Storage variables
    uint256 private _totalAssets;
    uint256 private _totalSupply;
    address private _asset;

    constructor(address asset_) {
        _asset = asset_;
    }

    function totalAssets() external view returns (uint256) {
        return _totalAssets;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function asset() external view returns (address) {
        return _asset;
    }

    // Convert assets to shares based on current ratio
    function convertToShares(uint256 assets) external view returns (uint256) {
        if (_totalSupply == 0) return assets; // First deposit is 1:1
        return (assets * _totalSupply) / _totalAssets;
    }

    // Convert shares to assets based on current ratio
    function convertToAssets(uint256 shares) external view returns (uint256) {
        if (_totalSupply == 0) return shares; // First deposit is 1:1
        return (shares * _totalAssets) / _totalSupply;
    }

    // Functions to manipulate state for testing
    function setTotalAssets(uint256 _totalAssets_) external {
        _totalAssets = _totalAssets_;
    }

    function setTotalSupply(uint256 _totalSupply_) external {
        _totalSupply = _totalSupply_;
    }
}
