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

    // For setting health factors and liquidation parameters
    uint256 constant UNSAFE_HEALTH_FACTOR = 80; // Below liquidation threshold (100)
    uint256 constant SAFE_HEALTH_FACTOR = 150; // Above liquidation threshold
    uint256 constant SEIZED_ASSETS = 100; // Amount of assets to seize
    uint256 constant REPAID_DEBT = 50; // Amount of debt to repay
    uint256 constant SMALL_REPAID_DEBT = 10; // Small amount of debt repaid

    function setUp() public {
        // Create the protocol and initialize it
        protocol = new LendingProtocol();

        // Give the liquidator some ETH
        vm.deal(liquidator, 100 ether);
    }

    function test_assertionLiquidationNotEligible() public {
        // Set borrower's health factor to a safe value
        protocol.setHealthFactor(borrower, SAFE_HEALTH_FACTOR);

        cl.assertion({
            adopter: address(protocol),
            createData: type(LiquidationHealthFactorAssertion).creationCode,
            fnSelector: LiquidationHealthFactorAssertion.assertHealthFactor.selector
        });

        // Set liquidator as the caller
        vm.prank(liquidator);

        // This should fail the assertion because the position is already healthy
        vm.expectRevert("Account not eligible for liquidation");
        protocol.liquidate(borrower, SEIZED_ASSETS, REPAID_DEBT);
    }

    function test_assertionLiquidationEligible() public {
        // Set borrower's health factor to an unsafe value
        protocol.setHealthFactor(borrower, UNSAFE_HEALTH_FACTOR);

        cl.assertion({
            adopter: address(protocol),
            createData: type(LiquidationHealthFactorAssertion).creationCode,
            fnSelector: LiquidationHealthFactorAssertion.assertHealthFactor.selector
        });

        // Set liquidator as the caller
        vm.prank(liquidator);

        // This should pass as the position is unhealthy and liquidation improves the health factor
        protocol.liquidate(borrower, SEIZED_ASSETS, REPAID_DEBT);
    }

    function test_assertionLiquidationNoImprovement() public {
        // Set borrower's health factor to an unsafe value
        protocol.setHealthFactor(borrower, UNSAFE_HEALTH_FACTOR);

        cl.assertion({
            adopter: address(protocol),
            createData: type(LiquidationHealthFactorAssertion).creationCode,
            fnSelector: LiquidationHealthFactorAssertion.assertHealthFactor.selector
        });

        // Set liquidator as the caller
        vm.prank(liquidator);

        // This should pass because even small repayments improve the health factor
        // The assertion checks that the health factor improves, which it will
        protocol.liquidate(borrower, SEIZED_ASSETS, SMALL_REPAID_DEBT);
    }

    function test_assertionLiquidationStillUnhealthy() public {
        // Set borrower's health factor to a very low unsafe value
        protocol.setHealthFactor(borrower, 50); // Very low health factor

        cl.assertion({
            adopter: address(protocol),
            createData: type(LiquidationHealthFactorAssertion).creationCode,
            fnSelector: LiquidationHealthFactorAssertion.assertHealthFactor.selector
        });

        // Set liquidator as the caller
        vm.prank(liquidator);

        // This should pass because the liquidation function ensures the health factor reaches MIN_HEALTH_FACTOR
        // The assertion checks that the position becomes healthy, which it will
        protocol.liquidate(borrower, SEIZED_ASSETS, 1); // Only 1 unit repaid
    }
}
