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
        cl.assertion({
            adopter: address(protocol),
            createData: type(ReadLogsAssertion).creationCode,
            fnSelector: ReadLogsAssertion.assertionReadLogs.selector
        });
        vm.prank(address(0x1));
        protocol.transfer(address(0x2), 100);
    }
}
