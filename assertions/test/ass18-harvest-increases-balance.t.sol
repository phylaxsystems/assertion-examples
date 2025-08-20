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
        cl.assertion({
            adopter: address(protocol),
            createData: type(BeefyHarvestAssertion).creationCode,
            fnSelector: BeefyHarvestAssertion.assertionHarvestIncreasesBalance.selector
        });

        // Set user as the caller
        vm.prank(user);
        // This should pass because a normal harvest increases the balance
        protocol.harvest(false);
    }

    function test_assertionHarvestBalanceDecreases() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(BeefyHarvestAssertion).creationCode,
            fnSelector: BeefyHarvestAssertion.assertionHarvestIncreasesBalance.selector
        });

        // Set user as the caller
        vm.prank(user);
        // This should revert because we're calling harvest(true) which decreases the balance
        vm.expectRevert("Harvest decreased balance");
        protocol.harvest(true);
    }

    function test_assertionBatchHarvests() public {
        // Create a batch harvester that will make multiple harvests
        BatchHarvests batchHarvester = new BatchHarvests(address(protocol));

        cl.assertion({
            adopter: address(protocol),
            createData: type(BeefyHarvestAssertion).creationCode,
            fnSelector: BeefyHarvestAssertion.assertionHarvestIncreasesBalance.selector
        });

        // Execute the batch harvests
        vm.prank(user);
        batchHarvester.batchHarvest();
    }

    function test_assertionBatchHarvestsWithBadHarvest() public {
        // Create a batch harvester that will include a bad harvest
        BatchHarvestsWithBadHarvest batchHarvester = new BatchHarvestsWithBadHarvest(address(protocol));

        cl.assertion({
            adopter: address(protocol),
            createData: type(BeefyHarvestAssertion).creationCode,
            fnSelector: BeefyHarvestAssertion.assertionHarvestIncreasesBalance.selector
        });

        // Execute the batch harvests with bad harvest
        vm.prank(user);
        vm.expectRevert("Invalid balance decrease detected during harvest");
        batchHarvester.batchHarvest();
    }
}

contract BatchHarvests {
    BeefyVault public vault;

    constructor(address vault_) {
        vault = BeefyVault(vault_);
    }

    function batchHarvest() external {
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

    function batchHarvest() external {
        // Make multiple harvests including a bad one
        vault.harvest(false); // First harvest (good)
        vault.harvest(false); // Second harvest (good)
        vault.harvest(true); // Third harvest (bad) - should trigger assertion
        vault.harvest(false); // Fourth harvest (good)
        vault.harvest(false); // Fifth harvest (good)
    }
}
