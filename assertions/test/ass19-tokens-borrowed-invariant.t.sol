// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {TokensBorrowedInvariant} from "../src/ass19-tokens-borrowed-invariant.a.sol";
import {Morpho} from "../../src/ass19-tokens-borrowed-invariant.sol";

contract TestTokensBorrowedInvariant is CredibleTest, Test {
    Morpho public protocol;
    address public user = address(0x1234);
    string constant ASSERTION_LABEL = "TokensBorrowedInvariant";

    // Initial values for the protocol
    uint256 public initialSupply = 1000 ether;
    uint256 public initialBorrowed = 500 ether;

    function setUp() public {
        // Initialize the protocol with supply > borrowed
        protocol = new Morpho(initialSupply, initialBorrowed);
        vm.deal(user, 100 ether);
    }

    function test_assertionInvariantViolation() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(TokensBorrowedInvariant).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);

        // This should revert because setting borrowed > supply violates the invariant
        uint256 newBorrowed = initialSupply + 1; // Borrowed amount exceeds supply
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(Morpho.setTotalBorrowedAsset.selector, abi.encode(newBorrowed))
        );
    }

    function test_assertionInvariantMaintained() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(TokensBorrowedInvariant).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);

        // This should pass because borrowed remains <= supply
        uint256 newBorrowed = initialSupply; // Borrowed equals supply (edge case, but still valid)
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(Morpho.setTotalBorrowedAsset.selector, abi.encode(newBorrowed))
        );
    }

    function test_assertionBorrowViolation() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(TokensBorrowedInvariant).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);

        // This should revert because borrowing too much violates the invariant
        uint256 borrowAmount = initialSupply - initialBorrowed + 1; // Would make borrowed > supply
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(Morpho.borrow.selector, abi.encode(borrowAmount))
        );
    }

    function test_assertionWithdrawViolation() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(TokensBorrowedInvariant).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);

        // This should revert because withdrawing too much violates the invariant
        uint256 withdrawAmount = initialSupply - initialBorrowed + 1; // Would make supply < borrowed
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(Morpho.withdraw.selector, abi.encode(withdrawAmount))
        );
    }

    function test_assertionSupply() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(TokensBorrowedInvariant).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);

        // This should pass because supplying more assets maintains the invariant
        uint256 supplyAmount = 100 ether;
        cl.validate(
            ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(Morpho.supply.selector, abi.encode(supplyAmount))
        );
    }

    function test_assertionRepay() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(TokensBorrowedInvariant).creationCode, abi.encode(protocol)
        );

        // Set user as the caller
        vm.prank(user);

        // This should pass because repaying borrowed assets maintains the invariant
        uint256 repayAmount = 100 ether;
        cl.validate(
            ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(Morpho.repay.selector, abi.encode(repayAmount))
        );
    }
}
