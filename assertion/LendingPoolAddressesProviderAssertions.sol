// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {LendingPoolAddressesProvider} from "../lib/LendingPoolAddressProvider.sol";

interface Assertion {
    enum TriggerType {
        STORAGE,
        ETHER,
        BOTH
    }

    struct Trigger {
        TriggerType triggerType;
        bytes4 fnSelector;
    }
}

// Radiant Lending Pool on Arbitrum that got hacked and drained
contract LendingPoolAddressesProviderAssertions is Assertion, LendingPoolAddressesProvider {
    address public oldArbitrumOwner = 0x111CEEee040739fD91D29C34C33E6B3E112F2177; //arbitrum gnosis safe proxy
    address public newArbitrumOwner = 0x57ba8957ed2ff2e7AE38F4935451E81Ce1eEFbf5; //malicious contract
    LendingPoolAddressesProvider public lendingPoolAddressesProvider =
        LendingPoolAddressesProvider(0x091d52CacE1edc5527C99cDCFA6937C1635330E4); //arbitrum
    address public emergencyAdmin;
    address public prevOwner;
    address public poolAdmin;
    address public priceOracle;
    address public lendingPoolConfigurator;

    function fnSelectors() external pure returns (Trigger[] memory) {
        Trigger[] memory triggers = new Trigger[](1);
        triggers[0] = Trigger(TriggerType.STORAGE, this.assertionStorage.selector);
        return triggers;
    }

    // Currently I am assuming that we will have some setup functionlity that can be used
    // to define variables to be used in the assertions.
    // There needs to be a way to define the values prior to a state transition.
    function setUp() public {
        prevOwner = lendingPoolAddressesProvider.owner();
        emergencyAdmin = lendingPoolAddressesProvider.getEmergencyAdmin();
        poolAdmin = lendingPoolAddressesProvider.getPoolAdmin();
        priceOracle = lendingPoolAddressesProvider.getPriceOracle();
        lendingPoolConfigurator = lendingPoolAddressesProvider.getLendingPoolConfigurator();
    }

    function assertionStorage() external returns (bool) {
        return
            assertionOwnerChange() &&
            assertionEmergencyAdminChange() &&
            assertionPoolAdminChange() &&
            assertionPriceOracleChange() &&
            assertionLendingPoolConfiguratorChange();
    }

    function assertionEther() external returns (bool) {
        return true;
    }

    function assertionBoth() external returns (bool) {
        return true;
    }

    // This function is used to check if the owner has changed.
    function assertionOwnerChange() external returns (bool) {
        address newOwner = lendingPoolAddressesProvider.owner();
        return prevOwner == newOwner;
    }

    // This function is used to check if the emergency admin has changed.
    function assertionEmergencyAdminChange() external returns (bool) {
        address newEmergencyAdmin = lendingPoolAddressesProvider.getEmergencyAdmin();
        return emergencyAdmin == newEmergencyAdmin;
    }

    // This function is used to check if the pool admin has changed.
    function assertionPoolAdminChange() external returns (bool) {
        address newPoolAdmin = lendingPoolAddressesProvider.getPoolAdmin();
        return poolAdmin == newPoolAdmin;
    }

    // This function is used to check if the price oracle has changed.
    function assertionPriceOracleChange() external returns (bool) {
        address newPriceOracle = lendingPoolAddressesProvider.getPriceOracle();
        return priceOracle == newPriceOracle;
    }

    // This function is used to check if the lending pool configurator has changed.
    function assertionLendingPoolConfiguratorChange() external returns (bool) {
        address newLendingPoolConfigurator = lendingPoolAddressesProvider.getLendingPoolConfigurator();
        return lendingPoolConfigurator == newLendingPoolConfigurator;
    }
}
