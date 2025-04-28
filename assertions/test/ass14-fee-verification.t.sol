// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Pool} from "../../src/ass14-fee-verification.sol";
import {AmmFeeVerificationAssertion, IPool} from "../src/ass14-fee-verification.a.sol";

contract TestFeeVerification is CredibleTest, Test {
    // Contract state variables
    Pool public protocol;
    address public user = address(0x1234);
    string constant ASSERTION_LABEL = "AmmFeeVerificationAssertion";

    // Fee constants
    uint256 private constant STABLE_POOL_FEE_1 = 1; // 0.1%
    uint256 private constant STABLE_POOL_FEE_2 = 15; // 0.15%
    uint256 private constant NON_STABLE_POOL_FEE_1 = 25; // 0.25%
    uint256 private constant NON_STABLE_POOL_FEE_2 = 30; // 0.30%
    uint256 private constant INVALID_FEE = 50; // 0.50% - not allowed

    function setUp() public {
        // Start with a stable pool and the first allowed fee
        protocol = new Pool(STABLE_POOL_FEE_1, true);
        vm.deal(user, 100 ether);
    }

    function test_validFeeChangeStable() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(AmmFeeVerificationAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(user);
        // This should pass because we're setting a valid fee for stable pools
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(protocol.setFee.selector, abi.encode(STABLE_POOL_FEE_2))
        );
    }

    function test_invalidFeeChangeStable() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(AmmFeeVerificationAssertion).creationCode, abi.encode(protocol)
        );

        vm.prank(user);
        // This should revert because we're setting an invalid fee for stable pools
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL, protocolAddress, 0, abi.encodePacked(protocol.setFee.selector, abi.encode(INVALID_FEE))
        );
    }

    function test_validFeeChangeNonStable() public {
        // Create a non-stable pool
        Pool nonStableProtocol = new Pool(NON_STABLE_POOL_FEE_1, false);
        address protocolAddress = address(nonStableProtocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL,
            protocolAddress,
            type(AmmFeeVerificationAssertion).creationCode,
            abi.encode(nonStableProtocol)
        );

        vm.prank(user);
        // This should pass because we're setting a valid fee for non-stable pools
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(nonStableProtocol.setFee.selector, abi.encode(NON_STABLE_POOL_FEE_2))
        );
    }

    function test_invalidFeeChangeNonStable() public {
        // Create a non-stable pool
        Pool nonStableProtocol = new Pool(NON_STABLE_POOL_FEE_1, false);
        address protocolAddress = address(nonStableProtocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL,
            protocolAddress,
            type(AmmFeeVerificationAssertion).creationCode,
            abi.encode(nonStableProtocol)
        );

        vm.prank(user);
        // This should revert because we're setting an invalid fee for non-stable pools
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            protocolAddress,
            0,
            abi.encodePacked(nonStableProtocol.setFee.selector, abi.encode(STABLE_POOL_FEE_1))
        );
    }

    function test_batchFeeChanges() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(AmmFeeVerificationAssertion).creationCode, abi.encode(protocol)
        );

        // Create a batch fee changer that will make multiple fee changes
        BatchFeeChanges batchChanger = new BatchFeeChanges(address(protocol));

        // Execute the batch fee changes
        vm.prank(user);
        cl.validate(
            ASSERTION_LABEL,
            address(batchChanger),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }

    function test_batchFeeChangesWithInvalid() public {
        address protocolAddress = address(protocol);

        // Associate the assertion with the protocol
        cl.addAssertion(
            ASSERTION_LABEL, protocolAddress, type(AmmFeeVerificationAssertion).creationCode, abi.encode(protocol)
        );

        // Create a batch fee changer that will include an invalid fee change
        BatchFeeChangesWithInvalid batchChanger = new BatchFeeChangesWithInvalid(address(protocol));

        // Execute the batch fee changes, expecting a revert due to the invalid fee
        vm.prank(user);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            ASSERTION_LABEL,
            address(batchChanger),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }
}

// Contract to perform multiple valid fee changes for stable pools in a batch
contract BatchFeeChanges {
    Pool public pool;

    uint256 private constant STABLE_POOL_FEE_1 = 1; // 0.1%
    uint256 private constant STABLE_POOL_FEE_2 = 15; // 0.15%

    constructor(address pool_) {
        pool = Pool(pool_);
    }

    fallback() external {
        // Make multiple fee changes in a single transaction
        // Alternate between allowed fee values for stable pools
        pool.setFee(STABLE_POOL_FEE_1);
        pool.setFee(STABLE_POOL_FEE_2);
        pool.setFee(STABLE_POOL_FEE_1);
        pool.setFee(STABLE_POOL_FEE_2);
        pool.setFee(STABLE_POOL_FEE_1);
        pool.setFee(STABLE_POOL_FEE_2);
        pool.setFee(STABLE_POOL_FEE_1);
        pool.setFee(STABLE_POOL_FEE_2);
        pool.setFee(STABLE_POOL_FEE_1);
        pool.setFee(STABLE_POOL_FEE_2);
    }
}

// Contract to perform multiple fee changes including an invalid one
contract BatchFeeChangesWithInvalid {
    Pool public pool;

    uint256 private constant STABLE_POOL_FEE_1 = 1; // 0.1%
    uint256 private constant STABLE_POOL_FEE_2 = 15; // 0.15%
    uint256 private constant INVALID_FEE = 50; // 0.50% - not allowed

    constructor(address pool_) {
        pool = Pool(pool_);
    }

    fallback() external {
        // Make multiple fee changes in a single transaction
        // Start with valid fees but include an invalid one
        pool.setFee(STABLE_POOL_FEE_1);
        pool.setFee(STABLE_POOL_FEE_2);
        pool.setFee(STABLE_POOL_FEE_1);
        pool.setFee(INVALID_FEE); // This will cause the assertion to revert
        pool.setFee(STABLE_POOL_FEE_1);
    }
}
