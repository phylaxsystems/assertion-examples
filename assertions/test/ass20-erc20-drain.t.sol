// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {ERC20Drain} from "../src/ass20-erc20-drain.sol";
import {IERC20} from "../src/ass20-erc20-drain.sol";

contract TestERC20Drain is Test, Credible {
    IERC20 public protocol;

    function setUp() public {
        protocol = IERC20(address(0xbeef));
    }
}
