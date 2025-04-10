// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../../lib/credible-std/src/Assertion.sol";

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
    // revert if the assertion fails
    function assertionOwnerChange() external {
        ph.forkPreState();
        address prevOwner = lendingPoolAddressesProvider.owner();
        ph.forkPostState();
        address newOwner = lendingPoolAddressesProvider.owner();
        require(prevOwner == newOwner, "Owner change assertion failed");
    }

    // Check if the emergency admin has changed
    // revert if the assertion fails
    function assertionEmergencyAdminChange() external {
        ph.forkPreState();
        address prevEmergencyAdmin = lendingPoolAddressesProvider.getEmergencyAdmin();
        ph.forkPostState();
        address newEmergencyAdmin = lendingPoolAddressesProvider.getEmergencyAdmin();
        require(prevEmergencyAdmin == newEmergencyAdmin, "Emergency admin change assertion failed");
    }

    // Check if the pool admin has changed
    // revert if the assertion fails
    function assertionPoolAdminChange() external {
        ph.forkPreState();
        address prevPoolAdmin = lendingPoolAddressesProvider.getPoolAdmin();
        ph.forkPostState();
        address newPoolAdmin = lendingPoolAddressesProvider.getPoolAdmin();
        require(prevPoolAdmin == newPoolAdmin, "Pool admin change assertion failed");
    }

    // Check if the price oracle has changed
    // revert if the assertion fails
    function assertionPriceOracleChange() external {
        ph.forkPreState();
        address prevPriceOracle = lendingPoolAddressesProvider.getPriceOracle();
        ph.forkPostState();
        address newPriceOracle = lendingPoolAddressesProvider.getPriceOracle();
        require(prevPriceOracle == newPriceOracle, "Price oracle change assertion failed");
    }

    // Check if the lending pool configurator has changed
    // revert if the assertion fails
    function assertionLendingPoolConfiguratorChange() external {
        ph.forkPreState();
        address prevLendingPoolConfigurator = lendingPoolAddressesProvider.getLendingPoolConfigurator();
        ph.forkPostState();
        address newLendingPoolConfigurator = lendingPoolAddressesProvider.getLendingPoolConfigurator();
        require(prevLendingPoolConfigurator == newLendingPoolConfigurator, "Lending pool configurator change assertion failed");
    }
}
