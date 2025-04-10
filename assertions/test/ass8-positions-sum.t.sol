// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {PositionSumAssertion} from "../src/ass8-positions-sum.sol";
import {ILending} from "../src/ass8-positions-sum.sol";

contract TestPositionSumAssertion is Test, Credible {
    ILending public protocol;

    function setUp() public {
        protocol = ILending(address(0xbeef));
    }
}
