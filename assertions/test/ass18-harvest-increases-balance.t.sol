// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {BeefyVault} from "../../src/ass18-harvest-increases-balance.sol";
import {BeefyHarvestAssertion} from "../src/ass18-harvest-increases-balance.a.sol";

contract TestHarvestIncreasesBalance is CredibleTest, Test {
    // Contract state variables
    BeefyVault public protocol;
    address public user = address(0x1234);
    uint256 public initialBalance = 100 ether;
    uint256 public initialPricePerShare = 1 ether;
    string constant ASSERTION_LABEL = "BeefyHarvestAssertion";

    function setUp() public {
        protocol = new BeefyVault(initialBalance, initialPricePerShare);
        vm.deal(user, 100 ether);
    }

    /* 
     * IMPORTANT NOTE ON TESTING THE ASSERTION:
     * The BeefyHarvestAssertion is designed to trigger on calls to the 'harvest()' function.
     * In the assertion file, this is set up via:
     *   registerCallTrigger(this.assertionHarvestIncreasesBalance.selector, vault.harvest.selector)
     * 
     * This means the assertion will only run when the exact function signature 'harvest()' is called.
     * If we were to use a different function like 'simulateBadHarvest()', the assertion wouldn't trigger.
     * 
     * To properly test the assertion's ability to detect decreasing balances, we've modified the protocol's
     * harvest function to accept a boolean parameter (harvest(bool badHarvest)) that determines if it will
     * perform a normal or bad harvest. We also kept a parameterless harvest() function for compatibility
     * with the interface that forwards to harvest(false).
     */

    function test_assertionHarvestIncreasesBalance() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(BeefyHarvestAssertion).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);
        // This should pass because a normal harvest increases the balance
        cl.validate(ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(protocol.harvest.selector, abi.encode(false)));
    }

    function test_assertionHarvestBalanceDecreases() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(BeefyHarvestAssertion).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);
        // This should revert because we're calling harvest(true) which decreases the balance
        vm.expectRevert("Assertions Reverted");
        cl.validate(ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(protocol.harvest.selector, abi.encode(true)));
    }

    function test_assertionBatchHarvests() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(BeefyHarvestAssertion).creationCode, abi.encode(protocol)
        );

        // Create a batch harvester that will make multiple harvests
        BatchHarvests batchHarvester = new BatchHarvests(address(protocol));

        // Execute the batch harvests
        vm.prank(user);
        cl.validate(
            ASSERTION_LABEL,
            address(batchHarvester),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }

    function test_assertionBatchHarvestsWithBadHarvest() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(BeefyHarvestAssertion).creationCode, abi.encode(protocol)
        );

        // Create a batch harvester that will include a bad harvest
        BatchHarvestsWithBadHarvest batchHarvester = new BatchHarvestsWithBadHarvest(address(protocol));

        // Execute the batch harvests with bad harvest
        vm.prank(user);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            address(batchHarvester),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }
}

contract BatchHarvests {
    BeefyVault public vault;

    constructor(address vault_) {
        vault = BeefyVault(vault_);
    }

    fallback() external {
        // Make multiple harvests in a single transaction
        vault.harvest(false); // First harvest
        vault.harvest(false); // Second harvest
        vault.harvest(false); // Third harvest
        vault.harvest(false); // Fourth harvest
        vault.harvest(false); // Fifth harvest
    }
}

contract BatchHarvestsWithBadHarvest {
    BeefyVault public vault;

    constructor(address vault_) {
        vault = BeefyVault(vault_);
    }

    fallback() external {
        // Make multiple harvests including a bad one
        vault.harvest(false); // First harvest (good)
        vault.harvest(false); // Second harvest (good)
        vault.harvest(true); // Third harvest (bad) - should trigger assertion
        vault.harvest(false); // Fourth harvest (good)
        vault.harvest(false); // Fifth harvest (good)
    }
}
