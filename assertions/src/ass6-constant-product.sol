// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

// Aerodrome style pool interface
interface IAmm {
    function getReserves() external view returns (uint256, uint256);
}

contract ConstantProductAssertion is Assertion {
    IAmm public amm = IAmm(address(0xbeef));

    function triggers() external view override {
        // Register triggers for both reserve slots for each assertion
        // This ensures we catch any modifications to either reserve

        // Main constant product assertion
        registerStorageChangeTrigger(this.assertionConstantProduct.selector, bytes32(uint256(0)));
        registerStorageChangeTrigger(this.assertionConstantProduct.selector, bytes32(uint256(1)));

        // Reserve0 specific assertion
        registerStorageChangeTrigger(this.assertionReserve0Changes.selector, bytes32(uint256(0)));

        // Reserve1 specific assertion
        registerStorageChangeTrigger(this.assertionReserve1Changes.selector, bytes32(uint256(1)));
    }

    // Assert that the constant product (k = x * y) invariant is maintained
    // This is done through a multi-layered approach:
    // 1. Verify the initial state (kPre)
    // 2. Monitor all intermediate states during the transaction
    // 3. Verify the final state matches the initial state (kPost == kPre)
    function assertionConstantProduct() external {
        // Get pre-state reserves and calculate initial k
        ph.forkPreState();
        (uint256 reserve0Pre, uint256 reserve1Pre) = amm.getReserves();
        uint256 kPre = reserve0Pre * reserve1Pre;

        // Get post-state reserves and calculate final k
        ph.forkPostState();
        (uint256 reserve0Post, uint256 reserve1Post) = amm.getReserves();
        uint256 kPost = reserve0Post * reserve1Post;

        // Verify the final state maintains the constant product
        require(kPre == kPost, "Constant product invariant violated");
    }

    // Assert that reserve0 changes maintain the constant product invariant
    // Note: This is a simplified version that assumes reserves are always updated simultaneously.
    // Different AMM implementations might have edge cases where reserves are updated independently
    // or at different times in the transaction. For those cases, a more sophisticated assertion
    // might be needed that tracks the chronological order of changes.
    function assertionReserve0Changes() external {
        // Get pre-state reserves and calculate initial k
        ph.forkPreState();
        (uint256 reserve0Pre, uint256 reserve1Pre) = amm.getReserves();
        uint256 kPre = reserve0Pre * reserve1Pre;

        // Get all state changes for reserve0 slot
        uint256[] memory reserve0Changes = getStateChangesUint(address(amm), bytes32(uint256(0)));

        // Verify each change maintains the constant product with the initial reserve1
        for (uint256 i = 0; i < reserve0Changes.length; i++) {
            require(reserve0Changes[i] * reserve1Pre == kPre, "Reserve0 modification violates constant product");
        }
    }

    // Assert that reserve1 changes maintain the constant product invariant
    // Note: This is a simplified version that assumes reserves are always updated simultaneously.
    // Different AMM implementations might have edge cases where reserves are updated independently
    // or at different times in the transaction. For those cases, a more sophisticated assertion
    // might be needed that tracks the chronological order of changes.
    function assertionReserve1Changes() external {
        // Get pre-state reserves and calculate initial k
        ph.forkPreState();
        (uint256 reserve0Pre, uint256 reserve1Pre) = amm.getReserves();
        uint256 kPre = reserve0Pre * reserve1Pre;

        // Get all state changes for reserve1 slot
        uint256[] memory reserve1Changes = getStateChangesUint(address(amm), bytes32(uint256(1)));

        // Verify each change maintains the constant product with the initial reserve0
        for (uint256 i = 0; i < reserve1Changes.length; i++) {
            require(reserve0Pre * reserve1Changes[i] == kPre, "Reserve1 modification violates constant product");
        }
    }
}
