// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {ERC4626Vault} from "../../src/ass12-erc4626-assets-shares.sol";
import {ERC4626AssetsSharesAssertion} from "../src/ass12-erc4626-assets-shares.a.sol";

contract TestERC4626AssetsShares is CredibleTest, Test {
    ERC4626Vault public protocol;
    address public user = address(0x1234);

    function setUp() public {
        protocol = new ERC4626Vault();
        vm.deal(user, 100 ether);

        // Set up a valid initial state with 100 assets and 100 shares
        protocol.setTotalAssets(100 ether);
        protocol.setTotalSupply(100 ether);
    }

    function test_assertionAssetsSharesViolated() public {
        address protocolAddress = address(protocol);
        string memory label = "Shares exceed convertible assets";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(ERC4626AssetsSharesAssertion).creationCode, abi.encode(protocol));

        vm.prank(user);
        // Try to increase shares to 200, which should fail
        // because convertToShares(100) = 100, so 200 > 100
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label, protocolAddress, 0, abi.encodePacked(protocol.setTotalSupply.selector, abi.encode(200 ether))
        );
    }

    function test_assertionAssetsSharesValid() public {
        address protocolAddress = address(protocol);
        string memory label = "Shares properly backed by assets";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(ERC4626AssetsSharesAssertion).creationCode, abi.encode(protocol));

        vm.prank(user);
        // Try to decrease shares to 50, which should pass
        // because convertToShares(100) = 100, so 50 <= 100
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.setTotalSupply.selector, abi.encode(50 ether)));
    }
}
