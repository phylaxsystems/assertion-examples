// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {EmergencyStateAssertion} from "../src/ass17-panic-state-verificatoin.a.sol";
import {IEmergencyPausable} from "../src/ass17-panic-state-verificatoin.a.sol";

contract TestPanicStateVerification is CredibleTest, Test {
    IEmergencyPausable public protocol;

    function setUp() public {
        protocol = IEmergencyPausable(address(0xbeef));
    }
}
