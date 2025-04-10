// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {ERC4626AssetsShares} from "../src/ass12-erc4626-assets-shares.sol";
import {IERC4626} from "../src/ass12-erc4626-assets-shares.sol";

contract TestERC4626AssetsShares is Test, Credible {
    IERC4626 public protocol;

    function setUp() public {
        protocol = IERC4626(address(0xbeef));
    }
}
