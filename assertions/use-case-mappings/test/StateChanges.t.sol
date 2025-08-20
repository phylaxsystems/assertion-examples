// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";

import {MonotonicallyIncreasingValue, StateChangesAssertion} from "../src/StateChanges.sol";

contract StateChangesTest is CredibleTest, Test {
    MonotonicallyIncreasingValue public protocol;

    function setUp() public {
        protocol = new MonotonicallyIncreasingValue();
    }

    function test_assertionStateChanges() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(StateChangesAssertion).creationCode,
            fnSelector: StateChangesAssertion.assertionStateChanges.selector
        });

        vm.prank(address(0x1));
        protocol.setValue(1);
    }
}
