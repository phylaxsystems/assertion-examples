// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {TokensBorrowedInvariant} from "../src/ass19-tokens-borrowed-invariant.sol";
import {IMorpho} from "../src/ass19-tokens-borrowed-invariant.sol";

contract TestTokensBorrowedInvariant is Test, Credible {
    IMorpho public protocol;

    function setUp() public {
        protocol = IMorpho(address(0xbeef));
    }
}
