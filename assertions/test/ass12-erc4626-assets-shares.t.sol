// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {ERC4626AssetsSharesAssertion} from "../src/ass12-erc4626-assets-shares.a.sol";
import {IERC4626} from "../src/ass12-erc4626-assets-shares.a.sol";

contract TestERC4626AssetsShares is CredibleTest, Test {
    IERC4626 public protocol;

    function setUp() public {
        protocol = IERC4626(address(0xbeef));
    }
}
