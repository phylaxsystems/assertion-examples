// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {TwapDeviation} from "../src/ass11-twap-deviation.sol";
import {IPair} from "../src/ass11-twap-deviation.sol";

contract TestTwapDeviation is Test, Credible {
    IPair public protocol;

    function setUp() public {
        protocol = IPair(address(0xbeef));
    }
}
