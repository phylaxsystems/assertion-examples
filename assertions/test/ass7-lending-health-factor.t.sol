// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {LendingHealthFactorAssertion} from "../src/ass7-lending-health-factor.a.sol";
import {IMorpho} from "../src/ass7-lending-health-factor.a.sol";

contract TestLendingHealthFactorAssertion is CredibleTest, Test {
    IMorpho public protocol;

    function setUp() public {
        protocol = IMorpho(address(0xbeef));
    }
}
