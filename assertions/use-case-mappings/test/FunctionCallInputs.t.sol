// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {Protocol, FunctionCallInputsAssertion} from "../src/FunctionCallInputs.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";

contract FunctionCallInputsTest is CredibleTest, Test {
    Protocol public protocol;

    function setUp() public {
        // Deploy the contract
        protocol = new Protocol();
    }

    function test_assertionFunctionCallInputs() public {
        protocol.mint(address(0x1), 100);
        cl.addAssertion(
            "FunctionCallInputsAssertion",
            address(protocol),
            type(FunctionCallInputsAssertion).creationCode,
            abi.encode(protocol)
        );
        vm.prank(address(0x1));
        cl.validate(
            "FunctionCallInputsAssertion",
            address(protocol),
            0,
            abi.encodeWithSelector(Protocol.transfer.selector, address(0x2), 100)
        );
    }
}
