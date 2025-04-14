// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Pool} from "../../src/ass11-twap-deviation.sol";
import {TwapDeviationAssertion} from "../src/ass11-twap-deviation.a.sol";

contract TestTwapDeviation is CredibleTest, Test {
    // Contract state variables
    Pool public protocol;
    address public user = address(0x1234);

    // Test constants
    uint256 public initialPrice = 1000e18; // $1000
    uint256 public smallDeviation = 1040e18; // 4% increase
    uint256 public largeDeviation = 1060e18; // 6% increase

    function setUp() public {
        protocol = new Pool(initialPrice);
        vm.deal(user, 100 ether);
    }

    function test_assertionSmallDeviation() public {
        address protocolAddress = address(protocol);
        string memory label = "Small price deviation";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(TwapDeviationAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);
        // This should pass because the price deviation is within 5%
        cl.validate(
            label,
            protocolAddress,
            0,
            abi.encodePacked(protocol.setPriceWithoutTwapUpdate.selector, abi.encode(smallDeviation))
        );
    }

    function test_assertionLargeDeviation() public {
        address protocolAddress = address(protocol);
        string memory label = "Large price deviation";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(TwapDeviationAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);
        // This should revert because the price deviation exceeds 5%
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label,
            protocolAddress,
            0,
            abi.encodePacked(protocol.setPriceWithoutTwapUpdate.selector, abi.encode(largeDeviation))
        );
    }

    function test_assertionMultiplePriceUpdates() public {
        address protocolAddress = address(protocol);
        string memory label = "Multiple price updates";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(TwapDeviationAssertion).creationCode, abi.encode(protocol));

        // Create a batch updater that will make multiple price updates
        BatchPriceUpdates batchUpdater = new BatchPriceUpdates(address(protocol));

        // Execute the batch updates
        vm.prank(user);
        cl.validate(
            label,
            address(batchUpdater),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }

    function test_assertionMultiplePriceUpdatesWithInvalid() public {
        address protocolAddress = address(protocol);
        string memory label = "Multiple price updates with invalid";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(TwapDeviationAssertion).creationCode, abi.encode(protocol));

        // Create a batch updater that will make multiple price updates
        InvalidBatchPriceUpdates batchUpdater = new InvalidBatchPriceUpdates(address(protocol));

        // Execute the batch updates
        vm.prank(user);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label,
            address(batchUpdater),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }
}

contract BatchPriceUpdates {
    Pool public pool;

    constructor(address pool_) {
        pool = Pool(pool_);
    }

    fallback() external {
        // Make multiple price updates in a single transaction
        // Each update is within 5% of the initial price
        pool.setPriceWithoutTwapUpdate(1020e18); // +2%
        pool.setPriceWithoutTwapUpdate(1030e18); // +3%
        pool.setPriceWithoutTwapUpdate(1040e18); // +4%
        pool.setPriceWithoutTwapUpdate(1030e18); // +3%
        pool.setPriceWithoutTwapUpdate(1020e18); // +2%
        pool.setPriceWithoutTwapUpdate(1010e18); // +1%
        pool.setPriceWithoutTwapUpdate(1000e18); // 0%
        pool.setPriceWithoutTwapUpdate(990e18); // -1%
        pool.setPriceWithoutTwapUpdate(980e18); // -2%
        pool.setPriceWithoutTwapUpdate(970e18); // -3%
    }
}

contract InvalidBatchPriceUpdates {
    Pool public pool;

    constructor(address pool_) {
        pool = Pool(pool_);
    }

    fallback() external {
        // Make multiple price updates in a single transaction
        // One update exceeds the 5% deviation limit
        pool.setPriceWithoutTwapUpdate(1020e18); // +2%
        pool.setPriceWithoutTwapUpdate(1030e18); // +3%
        pool.setPriceWithoutTwapUpdate(1040e18); // +4%
        pool.setPriceWithoutTwapUpdate(1060e18); // +6% - This exceeds the 5% limit
        pool.setPriceWithoutTwapUpdate(1030e18); // +3%
        pool.setPriceWithoutTwapUpdate(1020e18); // +2%
        pool.setPriceWithoutTwapUpdate(1010e18); // +1%
        pool.setPriceWithoutTwapUpdate(1000e18); // 0%
        pool.setPriceWithoutTwapUpdate(990e18); // -1%
        pool.setPriceWithoutTwapUpdate(980e18); // -2%
    }
}
