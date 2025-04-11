// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {LiquidationHealthFactorAssertion} from "../src/ass16-liquidation-health-factor.a.sol";
import {ILendingProtocol} from "../src/ass16-liquidation-health-factor.a.sol";

contract TestLiquidationHealthFactor is CredibleTest, Test {
    ILendingProtocol public protocol;

    function setUp() public {
        protocol = ILendingProtocol(address(0xbeef));
    }
}
