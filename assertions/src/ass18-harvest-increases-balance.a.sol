// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

// Inspired by https://github.com/beefyfinance/beefy-contracts/blob/master/forge/test/vault/ChainVaultsTest.t.sol#L77-L110
contract BeefyHarvestAssertion is Assertion {
    function triggers() external view override {
        // Register trigger for harvest function calls
        registerCallTrigger(this.assertionHarvestIncreasesBalance.selector, IBeefyVault.harvest.selector);
    }

    // Assert that the balance of the vault doesn't decrease after a harvest
    // and that the price per share doesn't decrease
    function assertionHarvestIncreasesBalance() external {
        // Get the assertion adopter address
        IBeefyVault adopter = IBeefyVault(ph.getAssertionAdopter());

        // Check pre-harvest state
        ph.forkPreTx();
        uint256 preBalance = adopter.balance();
        uint256 prePricePerShare = adopter.getPricePerFullShare();

        // Check post-harvest state
        ph.forkPostTx();
        uint256 postBalance = adopter.balance();
        uint256 postPricePerShare = adopter.getPricePerFullShare();

        // Balance should not decrease after harvest (can stay the same if harvested recently)
        require(postBalance >= preBalance, "Harvest decreased balance");

        // Price per share should increase or stay the same
        require(postPricePerShare >= prePricePerShare, "Price per share decreased after harvest");

        // Get all state changes to the balance slot
        uint256[] memory balanceChanges = getStateChangesUint(
            address(adopter),
            bytes32(uint256(0)) // First storage slot for balance
        );

        // Verify that all intermediate balance changes are valid
        // Each balance change should be >= the previous balance in the sequence
        uint256 lastBalance = preBalance;
        for (uint256 i = 0; i < balanceChanges.length; i++) {
            require(balanceChanges[i] >= lastBalance, "Invalid balance decrease detected during harvest");
            lastBalance = balanceChanges[i];
        }
    }
}

interface IBeefyVault {
    function balance() external view returns (uint256);
    function getPricePerFullShare() external view returns (uint256);
    function harvest(bool badHarvest) external;
}
