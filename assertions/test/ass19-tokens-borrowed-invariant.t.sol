// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {TokensBorrowedInvariant} from "../src/ass19-tokens-borrowed-invariant.a.sol";
import {Morpho} from "../../src/ass19-tokens-borrowed-invariant.sol";

contract TestTokensBorrowedInvariant is CredibleTest, Test {
    Morpho public protocol;
    address public user = address(0x1234);

    // Initial values for the protocol
    uint256 public initialSupply = 1000 ether;
    uint256 public initialBorrowed = 500 ether;

    function setUp() public {
        // Initialize the protocol with supply > borrowed
        protocol = new Morpho(initialSupply, initialBorrowed);
        vm.deal(user, 100 ether);
    }

    function test_assertionInvariantViolation() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(TokensBorrowedInvariant).creationCode,
            fnSelector: TokensBorrowedInvariant.assertBorrowedInvariant.selector
        });

        // Set user as the caller
        vm.prank(user);

        // This should revert because setting borrowed > supply violates the invariant
        uint256 newBorrowed = initialSupply + 1; // Borrowed amount exceeds supply
        vm.expectRevert("INVARIANT VIOLATION: Total supply of assets is less than total borrowed assets");
        protocol.setTotalBorrowedAsset(newBorrowed);
    }

    function test_assertionInvariantMaintained() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(TokensBorrowedInvariant).creationCode,
            fnSelector: TokensBorrowedInvariant.assertBorrowedInvariant.selector
        });

        // Set user as the caller
        vm.prank(user);

        // This should pass because borrowed remains <= supply
        uint256 newBorrowed = initialSupply; // Borrowed equals supply (edge case, but still valid)
        protocol.setTotalBorrowedAsset(newBorrowed);
    }

    function test_assertionBorrowViolation() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(TokensBorrowedInvariant).creationCode,
            fnSelector: TokensBorrowedInvariant.assertBorrowedInvariant.selector
        });

        // Set user as the caller
        vm.prank(user);

        // This should revert because borrowing too much violates the invariant
        uint256 borrowAmount = initialSupply - initialBorrowed + 1; // Would make borrowed > supply
        vm.expectRevert("INVARIANT VIOLATION: Total supply of assets is less than total borrowed assets");
        protocol.borrow(borrowAmount);
    }

    function test_assertionWithdrawViolation() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(TokensBorrowedInvariant).creationCode,
            fnSelector: TokensBorrowedInvariant.assertBorrowedInvariant.selector
        });

        // Set user as the caller
        vm.prank(user);

        // This should revert because withdrawing too much violates the invariant
        uint256 withdrawAmount = initialSupply - initialBorrowed + 1; // Would make supply < borrowed
        vm.expectRevert("INVARIANT VIOLATION: Total supply of assets is less than total borrowed assets");
        protocol.withdraw(withdrawAmount);
    }

    function test_assertionSupply() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(TokensBorrowedInvariant).creationCode,
            fnSelector: TokensBorrowedInvariant.assertBorrowedInvariant.selector
        });

        // Set user as the caller
        vm.prank(user);

        // This should pass because supplying more assets maintains the invariant
        uint256 supplyAmount = 100 ether;
        protocol.supply(supplyAmount);
    }

    function test_assertionRepay() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(TokensBorrowedInvariant).creationCode,
            fnSelector: TokensBorrowedInvariant.assertBorrowedInvariant.selector
        });

        // Set user as the caller
        vm.prank(user);

        // This should pass because repaying borrowed assets maintains the invariant
        uint256 repayAmount = 100 ether;
        protocol.repay(repayAmount);
    }
}
