// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/Assertion.sol";

interface IOracle {
    function lastUpdated() external view returns (uint256);

    function price() external view returns (uint256);
}

// Checks that the oracle is live
contract OracleLivenessAssertion is Assertion {
    IOracle public oracle = IOracle(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](2);
        assertions[0] = this.assertionOracleLiveness.selector;
        assertions[1] = this.assertionOraclePrice.selector;
    }

    // Make sure that the oracle has been updated within the last 10 minutes
    // return true indicates a valid state
    // return false indicates an invalid state
    function assertionOracleLiveness() external returns (bool) {
        ph.forkPreState();
        uint256 preTimestamp = oracle.lastUpdated();
        ph.forkPostState();
        uint256 postTimestamp = oracle.lastUpdated();
        return postTimestamp - preTimestamp <= 10 minutes; // Could be whatever time frame your protocol requires
    }

    // Make sure that price doesn't deviate more than 10%
    // return true indicates a valid state
    // return false indicates an invalid state
    function assertionOraclePrice() external returns (bool) {
        ph.forkPreState();
        uint256 prePrice = oracle.price();
        ph.forkPostState();
        uint256 postPrice = oracle.price();
        uint256 deviation = (((postPrice > prePrice) ? postPrice - prePrice : prePrice - postPrice) * 100) / prePrice;
        return deviation <= 10; // Could be whatever deviation your protocol requires
    }
}
