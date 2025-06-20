// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title ERC4626OperationsAssertion
 * @notice This assertion contract validates the correctness of ERC4626 vault operations by checking:
 *
 * 1. Batch Operations Consistency:
 *    - Validates that all ERC4626 operations (deposit, mint, withdraw, redeem) maintain correct
 *      accounting of total assets and total supply
 *    - Ensures that the net changes in assets and shares match the expected changes
 *    - Handles multiple operations in a single transaction
 *
 * 2. Deposit Operation Validation:
 *    - Verifies that deposit operations correctly increase the vault's asset balance
 *    - Ensures depositors receive the correct number of shares based on previewDeposit
 *    - Validates that the vault's total assets increase by exactly the deposited amount
 *
 * 3. Base Invariants:
 *    - Ensures the vault always has at least as many assets as shares
 *    - Validates this invariant after any storage changes
 *
 * The contract uses the Credible Layer's fork mechanism to compare pre and post-state
 * changes, ensuring that all operations maintain the vault's accounting integrity.
 */
import {Assertion} from "credible-std/Assertion.sol";
import {CoolVault} from "../../src/ass2-erc4626-operations.sol";
import {IERC4626} from "openzeppelin-contracts/contracts/interfaces/IERC4626.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract ERC4626OperationsAssertion is Assertion {
    // The contract we're monitoring
    CoolVault coolVault;

    // Constructor takes the address of the contract to monitor
    constructor(address _coolVault) {
        coolVault = CoolVault(_coolVault);
    }

    // The triggers function tells the Credible Layer which assertion functions to run
    function triggers() external view override {
        // Batch operations assertion - triggers on any of the four functions
        registerCallTrigger(this.assertionBatchOperationsConsistency.selector, coolVault.deposit.selector);
        registerCallTrigger(this.assertionBatchOperationsConsistency.selector, coolVault.mint.selector);
        registerCallTrigger(this.assertionBatchOperationsConsistency.selector, coolVault.withdraw.selector);
        registerCallTrigger(this.assertionBatchOperationsConsistency.selector, coolVault.redeem.selector);

        // Deposit-specific assertions
        registerCallTrigger(this.assertionDepositIncreasesBalance.selector, coolVault.deposit.selector);
        registerCallTrigger(this.assertionDepositerSharesIncreases.selector, coolVault.deposit.selector);

        // Base invariant assertion - triggers on storage changes
        registerStorageChangeTrigger(this.assertionVaultAlwaysAccumulatesAssets.selector, bytes32(uint256(2)));
    }

    /**
     * @dev Comprehensive assertion for batch operations: validates that all ERC4626 operations
     * in a single transaction maintain consistency across total supply and total assets
     * This function checks all four operations (deposit, mint, withdraw, redeem) that may occur
     * within the same transaction and ensures the final state is mathematically correct
     */
    function assertionBatchOperationsConsistency() external {
        // Get call inputs for all four functions
        PhEvm.CallInputs[] memory depositInputs = ph.getCallInputs(address(coolVault), coolVault.deposit.selector);
        PhEvm.CallInputs[] memory mintInputs = ph.getCallInputs(address(coolVault), coolVault.mint.selector);
        PhEvm.CallInputs[] memory withdrawInputs = ph.getCallInputs(address(coolVault), coolVault.withdraw.selector);
        PhEvm.CallInputs[] memory redeemInputs = ph.getCallInputs(address(coolVault), coolVault.redeem.selector);

        // Calculate net changes from all operations
        uint256 totalAssetsAdded = 0;
        uint256 totalAssetsRemoved = 0;
        uint256 totalSharesAdded = 0;
        uint256 totalSharesRemoved = 0;

        // Process deposit operations (increase assets and supply)
        for (uint256 i = 0; i < depositInputs.length; i++) {
            (uint256 assets,) = abi.decode(depositInputs[i].input, (uint256, address));
            totalAssetsAdded += assets;
            totalSharesAdded += coolVault.previewDeposit(assets);
        }

        // Process mint operations (increase assets and supply)
        for (uint256 i = 0; i < mintInputs.length; i++) {
            (uint256 shares,) = abi.decode(mintInputs[i].input, (uint256, address));
            totalSharesAdded += shares;
            totalAssetsAdded += coolVault.previewMint(shares);
        }

        // Process withdraw operations (decrease assets and supply)
        for (uint256 i = 0; i < withdrawInputs.length; i++) {
            (uint256 assets,,) = abi.decode(withdrawInputs[i].input, (uint256, address, address));
            totalAssetsRemoved += assets;
            totalSharesRemoved += coolVault.previewWithdraw(assets);
        }

        // Process redeem operations (decrease assets and supply)
        for (uint256 i = 0; i < redeemInputs.length; i++) {
            (uint256 shares,,) = abi.decode(redeemInputs[i].input, (uint256, address, address));
            totalSharesRemoved += shares;
            totalAssetsRemoved += coolVault.previewRedeem(shares);
        }

        ph.forkPreState();
        uint256 preVaultAssets = coolVault.totalAssets();
        uint256 preVaultSupply = coolVault.totalSupply();

        ph.forkPostState();
        uint256 postVaultAssets = coolVault.totalAssets();
        uint256 postVaultSupply = coolVault.totalSupply();

        // Calculate expected changes
        uint256 expectedAssetsAdded = postVaultAssets > preVaultAssets ? postVaultAssets - preVaultAssets : 0;
        uint256 expectedAssetsRemoved = preVaultAssets > postVaultAssets ? preVaultAssets - postVaultAssets : 0;
        uint256 expectedSharesAdded = postVaultSupply > preVaultSupply ? postVaultSupply - preVaultSupply : 0;
        uint256 expectedSharesRemoved = preVaultSupply > postVaultSupply ? preVaultSupply - postVaultSupply : 0;

        // Ensure operations had some effect if there were calls
        require(totalAssetsAdded == expectedAssetsAdded, "Batch Operations: Assets added mismatch");
        require(totalAssetsRemoved == expectedAssetsRemoved, "Batch Operations: Assets removed mismatch");
        require(totalSharesAdded == expectedSharesAdded, "Batch Operations: Shares added mismatch");
        require(totalSharesRemoved == expectedSharesRemoved, "Batch Operations: Shares removed mismatch");
    }

    /**
     * @dev Assertion to verify that deposit operations correctly increase the vault's asset balance
     * This ensures that when users deposit assets, the vault's total assets increase by exactly the deposited amount
     */
    function assertionDepositIncreasesBalance() external {
        // create a snapshot of the blockchain state before the transaction
        ph.forkPreState();

        // get the balance of the vault before the transaction
        uint256 vaultAssetPreBalance = CoolVault(coolVault).totalAssets();

        PhEvm.CallInputs[] memory inputs = ph.getCallInputs(address(coolVault), coolVault.deposit.selector);

        uint256 totalBalanceDeposited = 0;
        for (uint256 i = 0; i < inputs.length; i++) {
            (uint256 assets,) = abi.decode(inputs[i].input, (uint256, address));
            totalBalanceDeposited += assets;
        }

        // get the snapshot of state after the transaction
        ph.forkPostState();

        uint256 vaultAssetPostBalance = CoolVault(coolVault).totalAssets();

        require(
            vaultAssetPostBalance == vaultAssetPreBalance + totalBalanceDeposited,
            "Deposit assertion failed: Vault assets did not increase by the correct amount"
        );
    }

    /**
     * @dev Assertion to verify that deposit operations correctly increase the depositor's share balance
     * This ensures that when users deposit assets, they receive the correct number of shares
     */
    function assertionDepositerSharesIncreases() external {
        PhEvm.CallInputs[] memory inputs = ph.getCallInputs(address(coolVault), coolVault.deposit.selector);

        for (uint256 i = 0; i < inputs.length; i++) {
            ph.forkPreState();
            (uint256 assets,) = abi.decode(inputs[i].input, (uint256, address));
            uint256 previewPreAssets = CoolVault(coolVault).previewDeposit(assets);
            address depositer = inputs[0].caller;
            uint256 preShares = CoolVault(coolVault).balanceOf(depositer);

            ph.forkPostState();

            uint256 postShares = CoolVault(coolVault).balanceOf(depositer);

            require(
                postShares == preShares + previewPreAssets,
                "Depositer shares assertion failed: Share balance did not increase correctly"
            );
        }
    }

    /**
     * @dev Base invariant assertion to verify that the vault always has at least as many assets as shares
     * This is a fundamental invariant of ERC4626 vaults - they should never have more shares than assets
     */
    function assertionVaultAlwaysAccumulatesAssets() external {
        ph.forkPostState();

        uint256 vaultAssetPostBalance = CoolVault(coolVault).totalAssets();
        uint256 vaultSharesPostBalance = CoolVault(coolVault).balanceOf(address(coolVault));

        require(
            vaultAssetPostBalance >= vaultSharesPostBalance, "Base invariant failed: Vault has more shares than assets"
        );
    }
}
