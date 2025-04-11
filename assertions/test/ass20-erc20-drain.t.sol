// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {ERC20DrainAssertion} from "../src/ass20-erc20-drain.a.sol";
import {IERC20} from "../src/ass20-erc20-drain.a.sol";
import {IProtocol} from "../src/ass20-erc20-drain.a.sol";

contract TestERC20Drain is CredibleTest, Test {
    IERC20 public protocol;

    function setUp() public {
        protocol = IERC20(address(0xbeef));
    }
}
