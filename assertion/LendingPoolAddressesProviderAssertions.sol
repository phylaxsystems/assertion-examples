// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LendingPoolAddressesProvider} from "../lib/LendingPoolAddressProvider.sol";
import {Assertion} from "../lib/credible-std/Assertion.sol";

// Radiant Lending Pool on Arbitrum that got hacked and drained
contract LendingPoolAddressesProviderAssertions is Assertion, LendingPoolAddressesProvider {
    LendingPoolAddressesProvider public lendingPoolAddressesProvider =
        LendingPoolAddressesProvider(0x091d52CacE1edc5527C99cDCFA6937C1635330E4); //arbitrum

    function fnSelectors() external pure override returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](5);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionOwnerChange.selector);
        triggers[1] = Trigger(TriggerType.STORAGE, this.assertionEmergencyAdminChange.selector);
        triggers[2] = Trigger(TriggerType.STORAGE, this.assertionPoolAdminChange.selector);
        triggers[3] = Trigger(TriggerType.STORAGE, this.assertionPriceOracleChange.selector);
        triggers[4] = Trigger(TriggerType.STORAGE, this.assertionLendingPoolConfiguratorChange.selector);
        return triggers;
    }

    // This function is used to check if the owner has changed.
    function assertionOwnerChange() external returns (bool) {
        ph.forkPreState();
        address prevOwner = lendingPoolAddressesProvider.owner();
        ph.forkPostState();
        address newOwner = lendingPoolAddressesProvider.owner();
        return prevOwner == newOwner;
    }

    // This function is used to check if the emergency admin has changed.
    function assertionEmergencyAdminChange() external returns (bool) {
        ph.forkPreState();
        address prevEmergencyAdmin = lendingPoolAddressesProvider.getEmergencyAdmin();
        ph.forkPostState();
        address newEmergencyAdmin = lendingPoolAddressesProvider.getEmergencyAdmin();
        return prevEmergencyAdmin == newEmergencyAdmin;
    }

    // This function is used to check if the pool admin has changed.
    function assertionPoolAdminChange() external returns (bool) {
        ph.forkPreState();
        address prevPoolAdmin = lendingPoolAddressesProvider.getPoolAdmin();
        ph.forkPostState();
        address newPoolAdmin = lendingPoolAddressesProvider.getPoolAdmin();
        return prevPoolAdmin == newPoolAdmin;
    }

    // This function is used to check if the price oracle has changed.
    function assertionPriceOracleChange() external returns (bool) {
        ph.forkPreState();
        address prevPriceOracle = lendingPoolAddressesProvider.getPriceOracle();
        ph.forkPostState();
        address newPriceOracle = lendingPoolAddressesProvider.getPriceOracle();
        return prevPriceOracle == newPriceOracle;
    }

    // This function is used to check if the lending pool configurator has changed.
    function assertionLendingPoolConfiguratorChange() external returns (bool) {
        ph.forkPreState();
        address prevLendingPoolConfigurator = lendingPoolAddressesProvider.getLendingPoolConfigurator();
        ph.forkPostState();
        address newLendingPoolConfigurator = lendingPoolAddressesProvider.getLendingPoolConfigurator();
        return prevLendingPoolConfigurator == newLendingPoolConfigurator;
    }
}
