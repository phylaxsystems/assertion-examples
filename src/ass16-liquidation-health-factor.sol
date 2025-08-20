// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Simple Lending Protocol
 * @notice A simplified lending protocol for testing liquidation health factor assertions
 * @dev Tracks simple health factors per user without complex scaling
 */
contract LendingProtocol {
    // Simple mapping of user health factors (no scaling, just whole numbers)
    mapping(address => uint256) private _healthFactors;

    // Simple health factor constants
    uint256 constant LIQUIDATION_THRESHOLD = 100; // Below this = liquidatable
    uint256 constant MIN_HEALTH_FACTOR = 120; // Minimum safe health factor after liquidation

    /**
     * @notice Set a user's health factor for testing
     * @param user The user address
     * @param healthFactor The health factor value to set
     */
    function setHealthFactor(address user, uint256 healthFactor) external {
        _healthFactors[user] = healthFactor;
    }

    /**
     * @notice Performs a liquidation on a user's position
     * @param borrower The borrower address being liquidated
     * @param seizedAssets Amount of assets seized from the borrower
     * @param repaidDebt Amount of debt repaid
     * @return Amount of assets actually seized and debt actually repaid
     */
    function liquidate(address borrower, uint256 seizedAssets, uint256 repaidDebt)
        external
        returns (uint256, uint256)
    {
        // Get current health factor
        uint256 currentFactor = _healthFactors[borrower];

        // Simple health factor improvement: each unit of debt repaid improves health by 1
        uint256 improvement = repaidDebt;

        // Calculate new health factor
        uint256 newFactor = currentFactor + improvement;

        // Ensure the new health factor is at least above the minimum safe threshold
        if (newFactor < MIN_HEALTH_FACTOR) {
            newFactor = MIN_HEALTH_FACTOR;
        }

        // Update the health factor
        _healthFactors[borrower] = newFactor;

        return (seizedAssets, repaidDebt);
    }

    /**
     * @notice Checks if a user's position is healthy
     * @param user The user address
     * @return Whether the position is healthy (true) or not (false)
     */
    function isHealthy(address user) external view returns (bool) {
        return healthFactor(user) > LIQUIDATION_THRESHOLD;
    }

    /**
     * @notice Returns a user's health factor
     * @param user The user address
     * @return The current health factor
     */
    function healthFactor(address user) public view returns (uint256) {
        return _healthFactors[user];
    }
}
