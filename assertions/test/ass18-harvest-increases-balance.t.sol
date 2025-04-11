// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {BeefyHarvestAssertion} from "../src/ass18-harvest-increases-balance.a.sol";
import {IBeefyVault} from "../src/ass18-harvest-increases-balance.a.sol";

contract TestHarvestIncreasesBalance is CredibleTest, Test {
    IBeefyVault public protocol;

    function setUp() public {
        protocol = IBeefyVault(address(0xbeef));
    }
}
