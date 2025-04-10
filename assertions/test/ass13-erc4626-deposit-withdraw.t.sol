// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {ERC4626DepositWithdraw} from "../src/ass13-erc4626-deposit-withdraw.sol";
import {IERC4626} from "../src/ass13-erc4626-deposit-withdraw.sol";

contract TestERC4626DepositWithdraw is Test, Credible {
    IERC4626 public protocol;

    function setUp() public {
        protocol = IERC4626(address(0xbeef));
    }
}
