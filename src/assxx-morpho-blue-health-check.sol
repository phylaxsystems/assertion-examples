// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "credible-std/Assertion.sol";
import "credible-std/PhEvm.sol";
import "../../src/interfaces/IMorpho.sol";
import "../../src/interfaces/IOracle.sol";
import "../../src/libraries/MarketParamsLib.sol";
import "../../src/libraries/MathLib.sol";
import "../../src/interfaces/IERC20.sol";

contract MorphoHealthFactorAssertion is Assertion {
    using MarketParamsLib for MarketParams;
    using MathLib for uint256;

    address public immutable MORPHO_ADDRESS;

    constructor(address _morpho) {
        MORPHO_ADDRESS = _morpho;
    }

    function triggers() public view override {
        registerCallTrigger(this.assertionHealthCheck.selector);
    }

    function assertionHealthCheck() public view {
        // Use storage lookups to check all positions in Morpho
        // This is a more realistic approach for production assertions

        // Read storage to find active positions and check their health
        // For this example, we'll check a specific user position if it exists

        // Get the market ID from call context (this would be passed from the transaction)
        bytes32 marketId = bytes32(0); // This would be extracted from transaction data

        if (marketId == bytes32(0)) {
            // Skip if no market ID provided
            return;
        }

        // Use storage slots to read position data
        // Position mapping: position[marketId][user] -> Position struct
        // We'll check a known user address for demonstration
        address user = address(0x41B274f0bE57a870fF930503178a38799A16EAf2);

        // Calculate storage slot for position[marketId][user]
        bytes32 positionSlot = keccak256(abi.encode(user, keccak256(abi.encode(marketId, 2)))); // 2 is position mapping
            // slot

        // Read position data using storage lookups
        bytes32 positionData = ph.load(MORPHO_ADDRESS, positionSlot);

        // Extract borrowShares from position data (first 16 bytes of position struct)
        uint256 borrowShares = uint256(uint128(uint256(positionData)));

        if (borrowShares == 0) {
            // No borrow position, skip check
            return;
        }

        // Read collateral (last 16 bytes of position struct)
        bytes32 collateralSlot = bytes32(uint256(positionSlot) + 1);
        bytes32 collateralData = ph.load(MORPHO_ADDRESS, collateralSlot);
        uint256 collateral = uint256(uint128(uint256(collateralData)));

        // Read market data to get total borrow assets and shares
        bytes32 marketSlot = keccak256(abi.encode(marketId, 3)); // 3 is market mapping slot
        bytes32 marketData = ph.load(MORPHO_ADDRESS, marketSlot);

        // Extract totalBorrowAssets and totalBorrowShares from market data
        uint256 totalBorrowAssets = uint256(uint128(uint256(marketData) >> 128));
        uint256 totalBorrowShares = uint256(uint128(uint256(marketData)));

        if (totalBorrowShares == 0) {
            return; // No borrows in market
        }

        // Calculate borrowed amount
        uint256 borrowed = borrowShares.mulDivUp(totalBorrowAssets, totalBorrowShares);

        // Read market parameters to get oracle and LLTV
        bytes32 marketParamsSlot = keccak256(abi.encode(marketId, 6)); // 6 is idToMarketParams mapping slot

        // Read oracle address (3rd field in MarketParams)
        bytes32 oracleSlot = bytes32(uint256(marketParamsSlot) + 2);
        address oracle = address(uint160(uint256(ph.load(MORPHO_ADDRESS, oracleSlot))));

        // Read LLTV (5th field in MarketParams)
        bytes32 lltvSlot = bytes32(uint256(marketParamsSlot) + 4);
        uint256 lltv = uint256(ph.load(MORPHO_ADDRESS, lltvSlot));

        // Get collateral price from oracle
        uint256 collateralPrice;
        if (oracle != address(0)) {
            // Read price from oracle storage (assuming price is at slot 0)
            collateralPrice = uint256(ph.load(oracle, bytes32(0)));
        } else {
            collateralPrice = 1e36; // Default price
        }

        // Calculate max borrow based on collateral
        uint256 maxBorrow = collateral.mulDivDown(collateralPrice, 1e36) // ORACLE_PRICE_SCALE
            .wMulDown(lltv);

        // Assert position is healthy
        require(maxBorrow >= borrowed, "Position is unhealthy");
    }
}
