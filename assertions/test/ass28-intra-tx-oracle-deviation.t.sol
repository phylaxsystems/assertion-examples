// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {IntraTxOracleDeviationAssertion} from "../src/ass28-intra-tx-oracle-deviation.a.sol";
import {Oracle} from "../../src/ass28-intra-tx-oracle-deviation.sol";

contract TestIntraTxOracleDeviation is CredibleTest, Test {
    // Contract state variables
    Oracle public protocol;
    uint256 public initialPrice = 1000; // Initial price of 1000
    uint256 public acceptablePrice = 1100; // 10% increase, which is acceptable
    uint256 public unacceptablePrice = 1200; // 20% increase, which exceeds threshold
    address public user = address(0x1234);
    string constant ASSERTION_LABEL = "IntraTxOracleDeviationAssertion";

    function setUp() public {
        protocol = new Oracle(initialPrice);
        vm.deal(user, 100 ether);
    }

    function test_assertionAcceptableDeviation() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(IntraTxOracleDeviationAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(user);
        // This should pass because the price is within acceptable deviation (10%)
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.updatePrice.selector, abi.encode(acceptablePrice))
        );
    }

    function test_assertionUnacceptableDeviation() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(IntraTxOracleDeviationAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(user);
        // This should revert because the price exceeds acceptable deviation (20% > 10%)
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.updatePrice.selector, abi.encode(unacceptablePrice))
        );
    }

    function test_assertionBatchAcceptablePriceUpdates() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(IntraTxOracleDeviationAssertion).creationCode, abi.encode(protocol)
        );

        // Create a batch updater with all acceptable price updates
        BatchPriceUpdatesAcceptable batchUpdater = new BatchPriceUpdatesAcceptable(address(protocol));

        // Execute the batch updates
        vm.prank(user);
        cl.validate(
            ASSERTION_LABEL,
            address(batchUpdater),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }

    function test_assertionBatchUnacceptablePriceUpdates() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(IntraTxOracleDeviationAssertion).creationCode, abi.encode(protocol)
        );

        // Create a batch updater with an unacceptable price update
        BatchPriceUpdatesUnacceptable batchUpdater = new BatchPriceUpdatesUnacceptable(address(protocol));

        // Execute the batch updates, expect revert due to assertion
        vm.prank(user);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            address(batchUpdater),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }
}

contract BatchPriceUpdatesAcceptable {
    Oracle public oracle;

    constructor(address oracle_) {
        oracle = Oracle(oracle_);
    }

    fallback() external {
        // All price updates are within 10% deviation from initial price
        oracle.updatePrice(1050); // +5%
        oracle.updatePrice(1000); // back to initial
        oracle.updatePrice(950); // -5%
        oracle.updatePrice(1025); // +2.5%
        oracle.updatePrice(1075); // +7.5%
        oracle.updatePrice(1100); // +10% (at the limit)
        oracle.updatePrice(900); // -10% (at the limit)
        oracle.updatePrice(1000); // back to initial
    }
}

contract BatchPriceUpdatesUnacceptable {
    Oracle public oracle;

    constructor(address oracle_) {
        oracle = Oracle(oracle_);
    }

    fallback() external {
        // Start with acceptable updates
        oracle.updatePrice(1050); // +5%
        oracle.updatePrice(1075); // +7.5%
        // Then add unacceptable update
        oracle.updatePrice(1200); // +20% (exceeds 10% threshold)
        // These won't be reached because the assertion will revert
        oracle.updatePrice(1000);
    }
}
