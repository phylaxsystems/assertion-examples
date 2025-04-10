// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {LendingHealthFactorAssertion} from "../src/ass7-lending-health-factor.sol";
import {IMorpho} from "../src/ass7-lending-health-factor.sol";

contract TestLendingHealthFactorAssertion is Test, Credible {
    IMorpho public protocol;

    function setUp() public {
        protocol = IMorpho(address(0xbeef));
    }
}
