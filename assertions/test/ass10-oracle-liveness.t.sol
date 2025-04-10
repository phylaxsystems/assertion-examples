// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {OracleLiveness} from "../src/ass10-oracle-liveness.sol";
import {IOracle} from "../src/ass10-oracle-liveness.sol";

contract TestOracleLiveness is Test, Credible {
    IOracle public protocol;

    function setUp() public {
        protocol = IOracle(address(0xbeef));
    }
}
