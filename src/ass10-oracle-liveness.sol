// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Oracle Contract
 * @notice This contract simulates an oracle with a lastUpdated timestamp
 * @dev Contains functionality to get/set the last update time
 */
contract Oracle {
    // Time when the oracle was last updated
    uint256 private _lastUpdated;

    /**
     * @notice Constructor that sets the initial lastUpdated timestamp
     * @param initialTimestamp The initial lastUpdated timestamp
     */
    constructor(uint256 initialTimestamp) {
        _lastUpdated = initialTimestamp;
    }

    /**
     * @notice Returns the last updated timestamp
     * @return The timestamp when the oracle was last updated
     */
    function lastUpdated() external view returns (uint256) {
        return _lastUpdated;
    }

    /**
     * @notice Updates the lastUpdated timestamp to the current block timestamp
     */
    function update() external {
        _lastUpdated = block.timestamp;
    }

    /**
     * @notice Updates the lastUpdated timestamp to a specific value (for testing)
     * @param timestamp The timestamp to set as lastUpdated
     */
    function setLastUpdated(uint256 timestamp) external {
        _lastUpdated = timestamp;
    }
}

/**
 * @title DEX Contract
 * @notice This contract simulates a DEX with swap functionality that depends on oracle data
 */
contract Dex {
    Oracle private _oracle;

    /**
     * @notice Constructor that sets the oracle address
     * @param oracle The oracle contract address
     */
    constructor(address oracle) {
        _oracle = Oracle(oracle);
    }

    /**
     * @notice Simulates a swap operation that depends on fresh oracle data
     * @param tokenIn The address of the input token
     * @param tokenOut The address of the output token
     * @param amountIn The amount of input tokens to swap
     * @return The amount of output tokens received
     */
    function swap(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256) {
        // In a real implementation, this would check oracle data and calculate amounts
        return amountIn; // Simplified return for testing
    }
}
