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
        cl.addAssertion(
            "StateChangesAssertion", address(protocol), type(StateChangesAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(address(0x1));
        cl.validate(
            "StateChangesAssertion",
            address(protocol),
            0,
            abi.encodeWithSelector(MonotonicallyIncreasingValue.setValue.selector, 1)
        );
    }
}
