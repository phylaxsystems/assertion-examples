// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {TokensBorrowedInvariant} from "../src/ass19-tokens-borrowed-invariant.a.sol";
import {IMorpho} from "../src/ass19-tokens-borrowed-invariant.a.sol";

contract TestTokensBorrowedInvariant is CredibleTest, Test {
    IMorpho public protocol;

    function setUp() public {
        protocol = IMorpho(address(0xbeef));
    }
}
