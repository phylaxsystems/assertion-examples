// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {ConstantProductAssertion} from "../src/ass6-constant-product.sol";
import {IAmm} from "../src/ass6-constant-product.sol";

contract TestConstantProductAssertion is Test, Credible {
    IAmm public protocol;

    function setUp() public {
        protocol = IAmm(address(0xbeef));
    }
}
