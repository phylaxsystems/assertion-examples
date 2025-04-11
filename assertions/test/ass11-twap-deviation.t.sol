// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Pool} from "../../src/ass11-twap-deviation.sol";
import {TwapDeviationAssertion} from "../src/ass11-twap-deviation.a.sol";

contract TestTwapDeviation is CredibleTest, Test {
    // Contract state variables
    Pool public pool;

    // Test constants
    uint256 public initialPrice = 1000e18; // $1000
    uint256 public smallDeviation = 1040e18; // 4% increase
    uint256 public largeDeviation = 1060e18; // 6% increase

    function setUp() public {
        pool = new Pool(initialPrice);
    }

    function test_assertionSmallDeviation() public {
        address poolAddress = address(pool);
        string memory label = "Small price deviation";

        // Associate the assertion with the pool
        cl.addAssertion(label, poolAddress, type(TwapDeviationAssertion).creationCode, abi.encode(pool));

        // This should pass because the price deviation is within 5%
        cl.validate(
            label, poolAddress, 0, abi.encodePacked(pool.setPriceWithoutTwapUpdate.selector, abi.encode(smallDeviation))
        );
    }

    function test_assertionLargeDeviation() public {
        address poolAddress = address(pool);
        string memory label = "Large price deviation";

        // Associate the assertion with the pool
        cl.addAssertion(label, poolAddress, type(TwapDeviationAssertion).creationCode, abi.encode(pool));

        // This should revert because the price deviation exceeds 5%
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label, poolAddress, 0, abi.encodePacked(pool.setPriceWithoutTwapUpdate.selector, abi.encode(largeDeviation))
        );
    }
}
