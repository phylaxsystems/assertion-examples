// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {TimelockVerification} from "../src/ass9-timelock-verification.sol";
import {ITimelock} from "../src/ass9-timelock-verification.sol";

contract TestTimelockVerification is Test, Credible {
    ITimelock public protocol;

    function setUp() public {
        protocol = ITimelock(address(0xbeef));
    }
}
