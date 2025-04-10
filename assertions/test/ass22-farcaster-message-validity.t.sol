// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {FarcasterMessageValidity} from "../src/ass22-farcaster-message-validity.sol";
import {IFarcasterMessage} from "../src/ass22-farcaster-message-validity.sol";

contract TestFarcasterMessageValidity is Test, Credible {
    IFarcasterMessage public protocol;

    function setUp() public {
        protocol = IFarcasterMessage(address(0xbeef));
    }
}
