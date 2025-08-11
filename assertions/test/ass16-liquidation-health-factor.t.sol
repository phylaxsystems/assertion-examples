// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {LiquidationHealthFactorAssertion} from "../src/ass16-liquidation-health-factor.a.sol";
import {LendingProtocol} from "../../src/ass16-liquidation-health-factor.sol";

contract TestLiquidationHealthFactor is CredibleTest, Test {
    // Contract state variables
    LendingProtocol public protocol;
    address public borrower = address(0x1234);
    address public liquidator = address(0x5678);
    uint256 public marketId = 1;

    // For setting health factors and liquidation parameters
    uint256 constant UNSAFE_HEALTH_FACTOR = 0.9e18; // Below liquidation threshold
    uint256 constant SAFE_HEALTH_FACTOR = 1.5e18; // Above liquidation threshold
    uint256 constant SEIZED_ASSETS = 100e18; // Amount of assets to seize
    uint256 constant REPAID_SHARES = 500e18; // Amount of debt to repay - must be >= MIN_REPAID_FOR_IMPROVEMENT
    uint256 constant SMALL_REPAID_SHARES = 50e18; // Amount that's too small to improve health factor

    // Market params for the test
    LendingProtocol.MarketParams marketParams;

    function setUp() public {
        // Create the protocol and initialize it
        protocol = new LendingProtocol();

        // Set up market params
        LendingProtocol.Id memory id = LendingProtocol.Id({marketId: marketId});
        marketParams = LendingProtocol.MarketParams({id: id});

        // Give the liquidator some ETH
        vm.deal(liquidator, 100 ether);
    }

    function test_assertionLiquidationNotEligible() public {
        // Set borrower's health factor to a safe value
        protocol.setHealthFactor(marketParams, borrower, SAFE_HEALTH_FACTOR);

        cl.assertion({
            adopter: address(protocol),
            createData: type(LiquidationHealthFactorAssertion).creationCode,
            fnSelector: LiquidationHealthFactorAssertion.assertHealthFactor.selector
        });

        // Set liquidator as the caller
        vm.prank(liquidator);

        // This should fail the assertion because the position is already healthy
        vm.expectRevert("Account not eligible for liquidation");
        protocol.liquidate(marketParams, borrower, SEIZED_ASSETS, REPAID_SHARES, bytes(""));
    }

    function test_assertionLiquidationEligible() public {
        // Set borrower's health factor to an unsafe value
        protocol.setHealthFactor(marketParams, borrower, UNSAFE_HEALTH_FACTOR);

        cl.assertion({
            adopter: address(protocol),
            createData: type(LiquidationHealthFactorAssertion).creationCode,
            fnSelector: LiquidationHealthFactorAssertion.assertHealthFactor.selector
        });

        // Set liquidator as the caller
        vm.prank(liquidator);

        // This should pass as the position is unhealthy and liquidation improves the health factor
        protocol.liquidate(marketParams, borrower, SEIZED_ASSETS, REPAID_SHARES, bytes(""));
    }

    function test_assertionLiquidationNoImprovement() public {
        // Set borrower's health factor to an unsafe value
        protocol.setHealthFactor(marketParams, borrower, UNSAFE_HEALTH_FACTOR);

        cl.assertion({
            adopter: address(protocol),
            createData: type(LiquidationHealthFactorAssertion).creationCode,
            fnSelector: LiquidationHealthFactorAssertion.assertHealthFactor.selector
        });

        // Set liquidator as the caller
        vm.prank(liquidator);

        // This should revert as the health factor won't improve enough
        vm.expectRevert("Health factor did not improve after liquidation");
        protocol.liquidate(marketParams, borrower, SEIZED_ASSETS, SMALL_REPAID_SHARES, bytes(""));
    }
}
