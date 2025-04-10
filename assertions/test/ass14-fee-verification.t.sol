// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {FeeVerification} from "../src/ass14-fee-verification.sol";
import {IUniswapV3Pool} from "../src/ass14-fee-verification.sol";

contract TestFeeVerification is Test, Credible {
    IUniswapV3Pool public protocol;

    function setUp() public {
        protocol = IUniswapV3Pool(address(0xbeef));
    }
}
