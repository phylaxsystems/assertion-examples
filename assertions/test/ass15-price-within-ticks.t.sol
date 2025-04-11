// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {PriceWithinTicksAssertion} from "../src/ass15-price-within-ticks.a.sol";
import {IUniswapV3Pool} from "../src/ass15-price-within-ticks.a.sol";

contract TestPriceWithinTicks is CredibleTest, Test {
    IUniswapV3Pool public protocol;

    function setUp() public {
        protocol = IUniswapV3Pool(address(0xbeef));
    }
}
