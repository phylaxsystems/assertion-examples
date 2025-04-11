// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {TimelockVerificationAssertion} from "../src/ass9-timelock-verification.a.sol";
import {IGovernance} from "../src/ass9-timelock-verification.a.sol";

contract TestTimelockVerification is CredibleTest, Test {
    IGovernance public protocol;

    function setUp() public {
        protocol = IGovernance(address(0xbeef));
    }
}
