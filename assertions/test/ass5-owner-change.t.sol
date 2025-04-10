// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {OwnerChange} from "../src/ass5-owner-change.sol";
import {IOwnable} from "../src/ass5-owner-change.sol";

contract TestOwnerChange is Test, Credible {
    IOwnable public protocol;

    function setUp() public {
        protocol = IOwnable(address(0xbeef));
    }
}
