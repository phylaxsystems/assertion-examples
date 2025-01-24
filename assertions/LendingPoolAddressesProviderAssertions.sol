// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../lib/credible-std/Assertion.sol";

interface ILendingPoolAddressesProvider {
    function owner() external view returns (address);

    function getEmergencyAdmin() external view returns (address);

    function getPoolAdmin() external view returns (address);

    function getPriceOracle() external view returns (address);

    function getLendingPoolConfigurator() external view returns (address);
}

// Radiant Lending Pool on Arbitrum that got hacked and drained
contract LendingPoolAddressesProviderAssertions is Assertion {
    ILendingPoolAddressesProvider public lendingPoolAddressesProvider =
        ILendingPoolAddressesProvider(0x091d52CacE1edc5527C99cDCFA6937C1635330E4); //arbitrum

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](5);
        assertions[0] = this.assertionOwnerChange.selector;
        assertions[1] = this.assertionEmergencyAdminChange.selector;
        assertions[2] = this.assertionPoolAdminChange.selector;
        assertions[3] = this.assertionPriceOracleChange.selector;
        assertions[4] = this.assertionLendingPoolConfiguratorChange.selector;
    }

    // Check if the owner has changed
    // return true indicates a valid state -> owner is the same
    // return false indicates an invalid state -> owner is different
    function assertionOwnerChange() external returns (bool) {
        ph.forkPreState();
        address prevOwner = lendingPoolAddressesProvider.owner();
        ph.forkPostState();
        address newOwner = lendingPoolAddressesProvider.owner();
        return prevOwner == newOwner;
    }

    // Check if the emergency admin has changed
    // return true indicates a valid state -> emergency admin is the same
    // return false indicates an invalid state -> emergency admin is different
    function assertionEmergencyAdminChange() external returns (bool) {
        ph.forkPreState();
        address prevEmergencyAdmin = lendingPoolAddressesProvider.getEmergencyAdmin();
        ph.forkPostState();
        address newEmergencyAdmin = lendingPoolAddressesProvider.getEmergencyAdmin();
        return prevEmergencyAdmin == newEmergencyAdmin;
    }

    // Check if the pool admin has changed
    // return true indicates a valid state -> pool admin is the same
    // return false indicates an invalid state -> pool admin is different
    function assertionPoolAdminChange() external returns (bool) {
        ph.forkPreState();
        address prevPoolAdmin = lendingPoolAddressesProvider.getPoolAdmin();
        ph.forkPostState();
        address newPoolAdmin = lendingPoolAddressesProvider.getPoolAdmin();
        return prevPoolAdmin == newPoolAdmin;
    }

    // Check if the price oracle has changed
    // return true indicates a valid state -> price oracle is the same
    // return false indicates an invalid state -> price oracle is different
    function assertionPriceOracleChange() external returns (bool) {
        ph.forkPreState();
        address prevPriceOracle = lendingPoolAddressesProvider.getPriceOracle();
        ph.forkPostState();
        address newPriceOracle = lendingPoolAddressesProvider.getPriceOracle();
        return prevPriceOracle == newPriceOracle;
    }

    // Check if the lending pool configurator has changed
    // return true indicates a valid state -> lending pool configurator is the same
    // return false indicates an invalid state -> lending pool configurator is different
    function assertionLendingPoolConfiguratorChange() external returns (bool) {
        ph.forkPreState();
        address prevLendingPoolConfigurator = lendingPoolAddressesProvider.getLendingPoolConfigurator();
        ph.forkPostState();
        address newLendingPoolConfigurator = lendingPoolAddressesProvider.getLendingPoolConfigurator();
        return prevLendingPoolConfigurator == newLendingPoolConfigurator;
    }
}
