// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {PanicStateVerification} from "../src/ass17-panic-state-verificatoin.sol";
import {IPanicProtocol} from "../src/ass17-panic-state-verificatoin.sol";

contract TestPanicStateVerification is Test, Credible {
    IPanicProtocol public protocol;

    function setUp() public {
        protocol = IPanicProtocol(address(0xbeef));
    }
}
