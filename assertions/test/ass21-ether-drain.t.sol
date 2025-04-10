// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "credible-std/lib/forge-std/src/Test.sol";
import {Credible} from "credible-std/Credible.sol";
import {EtherDrain} from "../src/ass21-ether-drain.sol";
import {IProtocol} from "../src/ass21-ether-drain.sol";

contract TestEtherDrain is Test, Credible {
    IProtocol public protocol;

    function setUp() public {
        protocol = IProtocol(address(0xbeef));
    }
}
