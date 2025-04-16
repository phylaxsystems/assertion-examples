// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {PriceWithinTicksAssertion} from "../src/ass15-price-within-ticks.a.sol";
import {UniswapV3Pool} from "../../src/ass15-price-within-ticks.sol";

contract TestPriceWithinTicks is CredibleTest, Test {
    // Contract state variables
    UniswapV3Pool public protocol;

    // Initial test values
    int24 public initialTick = 100;
    int24 public tickSpacing = 10;

    // Valid ticks for testing
    int24 public validTick = 200;

    // Invalid ticks for testing
    int24 public invalidTickNotAligned = 205;
    int24 public invalidTickTooLarge = 888000;

    address public user = address(0x1234);

    function setUp() public {
        // Create a new protocol instance with initial values
        protocol = new UniswapV3Pool(initialTick, tickSpacing);

        // Give the user some ETH
        vm.deal(user, 100 ether);
    }

    function test_assertionValidTick() public {
        address protocolAddress = address(protocol);
        string memory label = "Price is within ticks";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(PriceWithinTicksAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);

        // This should pass because the new tick is valid: aligned with tickSpacing and within bounds
        cl.validate(label, protocolAddress, 0, abi.encodePacked(protocol.setTick.selector, abi.encode(validTick)));
    }

    function test_assertionTickNotAligned() public {
        address protocolAddress = address(protocol);
        string memory label = "Tick not aligned with spacing";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(PriceWithinTicksAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);

        // This should revert because the new tick is not aligned with tickSpacing
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label, protocolAddress, 0, abi.encodePacked(protocol.setTick.selector, abi.encode(invalidTickNotAligned))
        );
    }

    function test_assertionTickOutOfBounds() public {
        address protocolAddress = address(protocol);
        string memory label = "Tick outside bounds";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(PriceWithinTicksAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);

        // This should revert because the new tick is outside the allowed global bounds
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label, protocolAddress, 0, abi.encodePacked(protocol.setTick.selector, abi.encode(invalidTickTooLarge))
        );
    }

    function test_assertionTickSpacingChange() public {
        address protocolAddress = address(protocol);
        string memory label = "Tick spacing change";

        // Associate the assertion with the protocol
        cl.addAssertion(label, protocolAddress, type(PriceWithinTicksAssertion).creationCode, abi.encode(protocol));

        // Set user as the caller
        vm.prank(user);

        // This should pass because we're just changing the tick spacing, not the tick itself
        cl.validate(
            label, protocolAddress, 0, abi.encodePacked(protocol.setTickSpacing.selector, abi.encode(int24(20)))
        );
    }
}
