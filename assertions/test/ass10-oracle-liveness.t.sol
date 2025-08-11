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
        cl.assertion({
            adopter: address(dex),
            createData: type(OracleLivenessAssertion).creationCode,
            fnSelector: OracleLivenessAssertion.assertionOracleLiveness.selector
        });

        // Set user as the caller
        vm.prank(user);
        // This should pass because the oracle data is fresh
        dex.swap(tokenA, tokenB, swapAmount);
    }

    function test_assertionOracleStale() public {
        // Fast forward time to make oracle data stale
        vm.warp(block.timestamp + MAX_UPDATE_WINDOW + 1);

        cl.assertion({
            adopter: address(dex),
            createData: type(OracleLivenessAssertion).creationCode,
            fnSelector: OracleLivenessAssertion.assertionOracleLiveness.selector
        });

        // Set user as the caller
        vm.prank(user);
        // This should revert because the oracle data is stale
        vm.expectRevert("Oracle not updated within the allowed time window");
        dex.swap(tokenA, tokenB, swapAmount);
    }

    function test_assertionDemonstratesBug() public {
        // First, let's see what happens when oracle is fresh
        vm.prank(user);
        dex.swap(tokenA, tokenB, swapAmount);

        // Now make oracle stale and try to swap again
        vm.warp(block.timestamp + MAX_UPDATE_WINDOW + 1);

        cl.assertion({
            adopter: address(dex),
            createData: type(OracleLivenessAssertion).creationCode,
            fnSelector: OracleLivenessAssertion.assertionOracleLiveness.selector
        });

        vm.prank(user);
        // This should revert because the assertion catches the stale oracle
        vm.expectRevert("Oracle not updated within the allowed time window");
        dex.swap(tokenA, tokenB, swapAmount);
    }
}
