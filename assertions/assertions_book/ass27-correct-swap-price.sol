// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";
import {PhEvm} from "../../lib/credible-std/src/PhEvm.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

interface IMorpho {
    struct MarketParams {
        Id id;
    }

    struct Id {
        uint256 marketId;
    }

    function swap(MarketParams memory marketParams, uint256 amountIn, uint256 minAmountOut, bytes memory data)
        external
        returns (uint256 amountOut);

    function getAmountOut(MarketParams memory marketParams, uint256 amountIn) external view returns (uint256);

    function getTokens(MarketParams memory marketParams) external view returns (address tokenIn, address tokenOut);
}

contract MorphoSwapPriceAssertion is Assertion {
    IMorpho public morpho = IMorpho(address(0xbeef));

    function triggers() external view override {
        registerCallTrigger(this.assertSwapPrice.selector);
    }

    function assertSwapPrice() external {
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(morpho), morpho.swap.selector);
        if (callInputs.length == 0) {
            return;
        }

        for (uint256 i = 0; i < callInputs.length; i++) {
            bytes memory data = callInputs[i].input;
            address swapper = callInputs[i].caller;

            // Decode swap parameters
            (IMorpho.MarketParams memory marketParams, uint256 amountIn, uint256 minAmountOut,) =
                abi.decode(stripSelector(data), (IMorpho.MarketParams, uint256, uint256, bytes));

            // Get tokens involved in swap
            (address tokenIn, address tokenOut) = morpho.getTokens(marketParams);

            // Record pre-swap balances
            uint256 preBalanceIn = IERC20(tokenIn).balanceOf(swapper);
            uint256 preBalanceOut = IERC20(tokenOut).balanceOf(swapper);
            uint256 quotedAmountOut = morpho.getAmountOut(marketParams, amountIn);

            // Check post-swap state
            ph.forkPostState();
            uint256 postBalanceIn = IERC20(tokenIn).balanceOf(swapper);
            uint256 postBalanceOut = IERC20(tokenOut).balanceOf(swapper);

            require(postBalanceOut >= quotedAmountOut, "Swap price is lower than quoted");

            // Verify token in decreased correctly
            require(preBalanceIn - postBalanceIn == amountIn, "Incorrect amount in");
        }
    }

    function stripSelector(bytes memory input) internal pure returns (bytes memory) {
        bytes memory paramData = new bytes(32);
        for (uint256 i = 4; i < input.length; i++) {
            paramData[i - 4] = input[i];
        }
        return paramData;
    }
}
