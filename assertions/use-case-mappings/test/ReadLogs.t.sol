// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Protocol, ReadLogsAssertion} from "../src/ReadLogs.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";

contract ReadLogsTest is CredibleTest, Test {
    Protocol public protocol;

    function setUp() public {
        protocol = new Protocol();
    }

    function test_assertionReadLogs() public {
        protocol.mint(address(0x1), 100);
        cl.addAssertion(
            "ReadLogsAssertion", address(protocol), type(ReadLogsAssertion).creationCode, abi.encode(protocol)
        );
        vm.prank(address(0x1));
        cl.validate(
            "ReadLogsAssertion",
            address(protocol),
            0,
            abi.encodeWithSelector(Protocol.transfer.selector, address(0x2), 100)
        );
    }
}
