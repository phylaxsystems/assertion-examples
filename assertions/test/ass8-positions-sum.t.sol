// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {PositionSumAssertion} from "../src/ass8-positions-sum.a.sol";
import {ILending} from "../src/ass8-positions-sum.a.sol";

contract TestPositionSumAssertion is CredibleTest, Test {
    ILending public protocol;

    function setUp() public {
        protocol = ILending(address(0xbeef));
    }
}
