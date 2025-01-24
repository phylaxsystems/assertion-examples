// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

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
    function assertionOracleLiveness() external {
        ph.forkPreState();
        uint256 preTimestamp = oracle.lastUpdated();
        ph.forkPostState();
        uint256 postTimestamp = oracle.lastUpdated();
        require(postTimestamp - preTimestamp <= 10 minutes, "Oracle not updated within the last 10 minutes");
    }

    // Make sure that price doesn't deviate more than 10%
    function assertionOraclePrice() external {
        ph.forkPreState();
        uint256 prePrice = oracle.price();
        ph.forkPostState();
        uint256 postPrice = oracle.price();
        uint256 deviation = (((postPrice > prePrice) ? postPrice - prePrice : prePrice - postPrice) * 100) / prePrice;
        require(deviation <= 10, "Price deviation is too large");
    }
}
