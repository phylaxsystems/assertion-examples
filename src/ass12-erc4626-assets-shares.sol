// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC4626Vault {
    uint256 private _totalAssets;
    uint256 private _totalSupply;

    function totalAssets() external view returns (uint256) {
        return _totalAssets;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // This function tells us how many shares the given assets would convert to
    // based on the current ratio of shares to assets
    function convertToShares(uint256 assets) external view returns (uint256) {
        if (_totalSupply == 0) return assets; // First deposit is 1:1
        return (assets * _totalSupply) / _totalAssets;
    }

    // This function tells us how many assets the given shares would convert to
    // based on the current ratio of assets to shares
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
