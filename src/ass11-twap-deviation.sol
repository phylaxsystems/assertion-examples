// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Pool Contract
 * @notice This contract simulates a liquidity pool with price and TWAP functionality
 * @dev Contains storage and functions for current price and time-weighted average price
 */
contract Pool {
    // Storage slot 0: current price
    uint256 private _price;

    // Storage for TWAP calculation
    uint256 private _twapPrice;
    uint256 private _lastUpdated;
    uint256 private _cumulativePrice;

    /**
     * @notice Constructor that sets the initial price and TWAP
     * @param initialPrice The initial price
     */
    constructor(uint256 initialPrice) {
        _price = initialPrice;
        _twapPrice = initialPrice;
        _lastUpdated = block.timestamp;
        _cumulativePrice = initialPrice;
    }

    /**
     * @notice Returns the current price
     * @return The current price
     */
    function price() external view returns (uint256) {
        return _price;
    }

    /**
     * @notice Returns the time-weighted average price
     * @return The TWAP price
     */
    function twap() external view returns (uint256) {
        return _twapPrice;
    }

    /**
     * @notice Updates the price and recalculates TWAP
     * @param newPrice The new price to set
     */
    function setPrice(uint256 newPrice) external {
        // Update the cumulative price calculation
        uint256 timeElapsed = block.timestamp - _lastUpdated;
        _cumulativePrice += _price * timeElapsed;

        // Set the new price
        _price = newPrice;

        // Update TWAP calculation
        _lastUpdated = block.timestamp;
        _twapPrice = _cumulativePrice / _lastUpdated; // Simplified TWAP calculation
    }

    /**
     * @notice Sets the price without updating TWAP (for testing)
     * @param newPrice The new price to set
     */
    function setPriceWithoutTwapUpdate(uint256 newPrice) external {
        _price = newPrice;
    }

    /**
     * @notice Directly sets the TWAP value (for testing)
     * @param newTwap The new TWAP value
     */
    function setTwap(uint256 newTwap) external {
        _twapPrice = newTwap;
    }
}
