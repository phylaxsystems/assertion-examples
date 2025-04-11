// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {IntraTxOracleDeviationAssertion} from "../src/ass28-intra-tx-oracle-deviation.a.sol";
import {IOracle} from "../src/ass28-intra-tx-oracle-deviation.a.sol";

contract TestIntraTxOracleDeviation is CredibleTest, Test {
    IOracle public protocol;

    function setUp() public {
        protocol = IOracle(address(0xbeef));
    }
}
