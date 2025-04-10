// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {LiquidationHealthFactor} from "../src/ass16-liquidation-health-factor.sol";
import {ILendingProtocol} from "../src/ass16-liquidation-health-factor.sol";

contract TestLiquidationHealthFactor is Test, Credible {
    ILendingProtocol public protocol;

    function setUp() public {
        protocol = ILendingProtocol(address(0xbeef));
    }
}
