// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {AmmFeeVerificationAssertion} from "../src/ass14-fee-verification.a.sol";
import {IPool} from "../src/ass14-fee-verification.a.sol";

contract TestFeeVerification is CredibleTest, Test {
    IPool public protocol;

    function setUp() public {
        protocol = IPool(address(0xbeef));
    }
}
