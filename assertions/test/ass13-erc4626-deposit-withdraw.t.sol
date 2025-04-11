// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {ERC4626DepositWithdrawAssertion} from "../src/ass13-erc4626-deposit-withdraw.a.sol";
import {IERC4626} from "../src/ass13-erc4626-deposit-withdraw.a.sol";

contract TestERC4626DepositWithdraw is CredibleTest, Test {
    IERC4626 public protocol;

    function setUp() public {
        protocol = IERC4626(address(0xbeef));
    }
}
