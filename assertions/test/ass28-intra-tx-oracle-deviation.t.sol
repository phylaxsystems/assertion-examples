// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {IntraTxOracleDeviation} from "../src/ass28-intra-tx-oracle-deviation.sol";
import {IOracleWithPrice} from "../src/ass28-intra-tx-oracle-deviation.sol";

contract TestIntraTxOracleDeviation is Test, Credible {
    IOracleWithPrice public protocol;

    function setUp() public {
        protocol = IOracleWithPrice(address(0xbeef));
    }
}
