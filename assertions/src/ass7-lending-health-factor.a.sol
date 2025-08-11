// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract LendingHealthFactorAssertion is Assertion {
    function triggers() external view override {
        // Register triggers for each function that should maintain healthy positions
        registerCallTrigger(this.assertionSupply.selector, IMorpho.supply.selector);
        registerCallTrigger(this.assertionBorrow.selector, IMorpho.borrow.selector);
        registerCallTrigger(this.assertionWithdraw.selector, IMorpho.withdraw.selector);
        registerCallTrigger(this.assertionRepay.selector, IMorpho.repay.selector);
    }

    // Check that supply operation maintains healthy positions
    function assertionSupply() external {
        // Get the assertion adopter address
        IMorpho adopter = IMorpho(ph.getAssertionAdopter());

        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.supply.selector);
        for (uint256 i = 0; i < callInputs.length; i++) {
            (uint256 marketId,) = abi.decode(callInputs[i].input, (uint256, uint256));
            address user = callInputs[i].caller;

            IMorpho.MarketParams memory marketParams = adopter.idToMarketParams(marketId);

            require(adopter._isHealthy(marketParams, marketId, user), "Supply operation resulted in unhealthy position");
        }
    }

    // Check that borrow operation maintains healthy positions
    function assertionBorrow() external {
        // Get the assertion adopter address
        IMorpho adopter = IMorpho(ph.getAssertionAdopter());

        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.borrow.selector);
        for (uint256 i = 0; i < callInputs.length; i++) {
            (uint256 marketId,) = abi.decode(callInputs[i].input, (uint256, uint256));
            address user = callInputs[i].caller;

            IMorpho.MarketParams memory marketParams = adopter.idToMarketParams(marketId);

            require(adopter._isHealthy(marketParams, marketId, user), "Borrow operation resulted in unhealthy position");
        }
    }

    // Check that withdraw operation maintains healthy positions
    function assertionWithdraw() external {
        // Get the assertion adopter address
        IMorpho adopter = IMorpho(ph.getAssertionAdopter());

        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.withdraw.selector);
        for (uint256 i = 0; i < callInputs.length; i++) {
            (uint256 marketId,) = abi.decode(callInputs[i].input, (uint256, uint256));
            address user = callInputs[i].caller;

            IMorpho.MarketParams memory marketParams = adopter.idToMarketParams(marketId);

            require(
                adopter._isHealthy(marketParams, marketId, user), "Withdraw operation resulted in unhealthy position"
            );
        }
    }

    // Check that repay operation maintains healthy positions
    function assertionRepay() external {
        // Get the assertion adopter address
        IMorpho adopter = IMorpho(ph.getAssertionAdopter());

        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.repay.selector);
        for (uint256 i = 0; i < callInputs.length; i++) {
            (uint256 marketId,) = abi.decode(callInputs[i].input, (uint256, uint256));
            address user = callInputs[i].caller;

            IMorpho.MarketParams memory marketParams = adopter.idToMarketParams(marketId);

            require(adopter._isHealthy(marketParams, marketId, user), "Repay operation resulted in unhealthy position");
        }
    }
}

// We use Morpho as an example, but this could be any lending protocol
interface IMorpho {
    struct MarketParams {
        uint256 marketId;
    }

    struct Position {
        uint256 supplyShares;
        uint128 borrowShares;
        uint128 collateral;
    }

    function idToMarketParams(uint256) external view returns (MarketParams memory);
    function position(uint256, address) external view returns (Position memory);
    function _isHealthy(MarketParams memory marketParams, uint256 marketId, address borrower)
        external
        view
        returns (bool);

    // Functions used in triggers
    function supply(uint256 marketId, uint256 amount) external;
    function borrow(uint256 marketId, uint256 amount) external;
    function withdraw(uint256 marketId, uint256 amount) external;
    function repay(uint256 marketId, uint256 amount) external;
}
