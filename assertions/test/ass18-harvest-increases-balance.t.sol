// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {HarvestIncreasesBalance} from "../src/ass18-harvest-increases-balance.sol";
import {IYieldSource} from "../src/ass18-harvest-increases-balance.sol";

contract TestHarvestIncreasesBalance is Test, Credible {
    IYieldSource public protocol;

    function setUp() public {
        protocol = IYieldSource(address(0xbeef));
    }
}
