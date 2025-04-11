// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {EtherDrainAssertion} from "../src/ass21-ether-drain.a.sol";
import {IExampleContract} from "../src/ass21-ether-drain.a.sol";

contract TestEtherDrain is CredibleTest, Test {
    IExampleContract public protocol;

    function setUp() public {
        protocol = IExampleContract(address(0xbeef));
    }
}
