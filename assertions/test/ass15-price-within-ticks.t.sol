// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {PriceWithinTicks} from "../src/ass15-price-within-ticks.sol";
import {IUniswapV3Pool} from "../src/ass15-price-within-ticks.sol";

contract TestPriceWithinTicks is Test, Credible {
    IUniswapV3Pool public protocol;

    function setUp() public {
        protocol = IUniswapV3Pool(address(0xbeef));
    }
}
