// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {FarcasterProtocolAssertion} from "../src/ass22-farcaster-message-validity.a.sol";
import {IFarcaster} from "../src/ass22-farcaster-message-validity.a.sol";

contract TestFarcasterMessageValidity is CredibleTest, Test {
    IFarcaster public protocol;

    function setUp() public {
        protocol = IFarcaster(address(0xbeef));
    }
}
