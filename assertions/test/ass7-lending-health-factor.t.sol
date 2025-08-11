// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {LendingHealthFactor} from "../../src/ass7-lending-health-factor.sol";
import {LendingHealthFactorAssertion} from "../src/ass7-lending-health-factor.a.sol";

contract TestLendingHealthFactorAssertion is CredibleTest, Test {
    LendingHealthFactor public protocol;
    address public user = address(0x1234);

    function setUp() public {
        protocol = new LendingHealthFactor();
        vm.deal(user, 100 ether);
    }

    function test_assertionHealthyPosition() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(LendingHealthFactorAssertion).creationCode,
            fnSelector: LendingHealthFactorAssertion.assertionSupply.selector
        });

        vm.prank(user);
        // This should pass because the position remains healthy
        protocol.supply(1, 100);
    }

    function test_assertionUnhealthyPosition() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(LendingHealthFactorAssertion).creationCode,
            fnSelector: LendingHealthFactorAssertion.assertionBorrow.selector
        });

        // First make the position unhealthy
        protocol.setHealthStatus(false);

        vm.prank(user);
        // This should revert because the position is unhealthy
        vm.expectRevert("Borrow operation resulted in unhealthy position");
        protocol.borrow(1, 100);
    }
}
