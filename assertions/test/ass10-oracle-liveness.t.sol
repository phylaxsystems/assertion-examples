// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Oracle, Dex} from "../../src/ass10-oracle-liveness.sol";
import {OracleLivenessAssertion} from "../src/ass10-oracle-liveness.a.sol";

contract TestOracleLiveness is CredibleTest, Test {
    // Contract state variables
    Oracle public oracle;
    Dex public dex;

    // Constants for testing
    uint256 public constant MAX_UPDATE_WINDOW = 10 minutes;
    address public tokenA = address(0xaaa);
    address public tokenB = address(0xbbb);
    uint256 public swapAmount = 1e18;
    address public user = address(0x1234);

    function setUp() public {
        // Initialize with oracle data that is fresh
        oracle = new Oracle(block.timestamp);
        dex = new Dex(address(oracle));
        // Give the user some ETH
        vm.deal(user, 100 ether);
    }

    function test_assertionOracleFresh() public {
        address dexAddress = address(dex);
        string memory label = "Oracle is fresh";

        // Associate the assertion with the DEX
        cl.addAssertion(label, dexAddress, type(OracleLivenessAssertion).creationCode, abi.encode(oracle, dex));

        // Set user as the caller
        vm.prank(user);
        // This should pass because the oracle data is fresh
        cl.validate(label, dexAddress, 0, abi.encodePacked(dex.swap.selector, abi.encode(tokenA, tokenB, swapAmount)));
    }

    function test_assertionOracleStale() public {
        address dexAddress = address(dex);
        string memory label = "Oracle is stale";

        // Fast forward time to make oracle data stale
        vm.warp(block.timestamp + MAX_UPDATE_WINDOW + 1);

        // Associate the assertion with the DEX
        cl.addAssertion(label, dexAddress, type(OracleLivenessAssertion).creationCode, abi.encode(oracle, dex));

        // Set user as the caller
        vm.prank(user);
        // This should revert because the oracle data is stale
        vm.expectRevert("Assertions Reverted");
        cl.validate(label, dexAddress, 0, abi.encodePacked(dex.swap.selector, abi.encode(tokenA, tokenB, swapAmount)));
    }
}
