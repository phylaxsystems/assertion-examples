// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {ERC4626Vault} from "../../src/ass12-erc4626-assets-shares.sol";
import {ERC4626AssetsSharesAssertion} from "../src/ass12-erc4626-assets-shares.a.sol";

contract TestERC4626AssetsShares is CredibleTest, Test {
    ERC4626Vault public protocol;
    address public asset = address(0xdead);
    address public user = address(0x1234);
    string constant ASSERTION_LABEL = "ERC4626AssetsSharesAssertion";

    function setUp() public {
        protocol = new ERC4626Vault(asset);
        vm.deal(user, 100 ether);

        // Set up a valid initial state with 100 assets and 100 shares
        protocol.setTotalAssets(100 ether);
        protocol.setTotalSupply(100 ether);
    }

    function test_assertionAssetsSharesValid() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(ERC4626AssetsSharesAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(user);
        // Try to decrease shares to 50, which should pass
        // because convertToShares(100) = 100, so 50 <= 100
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.setTotalSupply.selector, abi.encode(50 ether))
        );
    }

    function test_assertionFailsWithSpecialCase42() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(ERC4626AssetsSharesAssertion).creationCode, abi.encode(protocol)
        );

        // The contract has a special case where if totalSupply is exactly 42 ether,
        // the convertToAssets function returns double the required assets.
        // This will cause the assertion to fail even though we have enough assets (100 ether)
        vm.prank(user);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.setTotalSupply.selector, abi.encode(42 ether))
        );
    }
}
