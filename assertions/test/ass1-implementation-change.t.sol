// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {ImplementationChange} from "../src/ass1-implementation-change.sol";
import {IImplementation} from "../src/ass1-implementation-change.sol";

contract TestImplementationChange is Test, Credible {
    IImplementation public protocol;

    function setUp() public {
        protocol = IImplementation(address(0xbeef));
    }
}
