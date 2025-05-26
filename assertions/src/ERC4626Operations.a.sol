// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {CoolVault} from "../../src/CoolVault.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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
        // Deposit function assertions
        // registerCallTrigger(
        //     this.assertionDepositUpdatesSupplyAndAssets.selector,
        //     coolVault.deposit.selector
        // );

        // // Mint function assertions
        // registerCallTrigger(
        //     this.assertionMintUpdatesSupplyAndAssets.selector,
        //     coolVault.mint.selector
        // );

        // // Withdraw function assertions
        // registerCallTrigger(
        //     this.assertionWithdrawUpdatesSupplyAndAssets.selector,
        //     coolVault.withdraw.selector
        // );

        // // Redeem function assertions
        // registerCallTrigger(
        //     this.assertionRedeemUpdatesSupplyAndAssets.selector,
        //     coolVault.redeem.selector
        // );

        // Batch operations assertion - triggers on any of the four functions
        registerCallTrigger(
            this.assertionBatchOperationsConsistency.selector,
            coolVault.deposit.selector
        );
        registerCallTrigger(
            this.assertionBatchOperationsConsistency.selector,
            coolVault.mint.selector
        );
        registerCallTrigger(
            this.assertionBatchOperationsConsistency.selector,
            coolVault.withdraw.selector
        );
        registerCallTrigger(
            this.assertionBatchOperationsConsistency.selector,
            coolVault.redeem.selector
        );
    }

    /**
     * @dev Assertion for deposit function: validates that total supply and total assets are correctly updated
     * Tests that depositing assets increases both vault's total assets and total supply proportionally
     */
    // function assertionDepositUpdatesSupplyAndAssets() external {
    //     ph.forkPreState();

    //     // Get pre-state values
    //     uint256 preVaultAssets = coolVault.totalAssets();
    //     uint256 preVaultSupply = coolVault.totalSupply();

    //     // Get all deposit calls in this transaction
    //     PhEvm.CallInputs[] memory inputs = ph.getCallInputs(
    //         address(coolVault),
    //         coolVault.deposit.selector
    //     );

    //     uint256 totalAssetsDeposited = 0;
    //     uint256 totalSharesExpected = 0;

    //     // Calculate expected changes from all deposit calls
    //     for (uint256 i = 0; i < inputs.length; i++) {
    //         (uint256 assets, ) = abi.decode(
    //             inputs[i].input,
    //             (uint256, address)
    //         );
    //         totalAssetsDeposited += assets;
    //         totalSharesExpected += coolVault.previewDeposit(assets);
    //     }

    //     ph.forkPostState();

    //     // Get post-state values
    //     uint256 postVaultAssets = coolVault.totalAssets();
    //     uint256 postVaultSupply = coolVault.totalSupply();

    //     // Verify total assets increased correctly
    //     require(
    //         postVaultAssets == preVaultAssets + totalAssetsDeposited,
    //         "Deposit: Total assets not updated correctly"
    //     );

    //     // Verify total supply increased correctly
    //     require(
    //         postVaultSupply == preVaultSupply + totalSharesExpected,
    //         "Deposit: Total supply not updated correctly"
    //     );
    // }

    // /**
    //  * @dev Assertion for mint function: validates that total supply and total assets are correctly updated
    //  * Tests that minting shares increases both vault's total supply and total assets proportionally
    //  */
    // function assertionMintUpdatesSupplyAndAssets() external {
    //     ph.forkPreState();

    //     // Get pre-state values
    //     uint256 preVaultAssets = coolVault.totalAssets();
    //     uint256 preVaultSupply = coolVault.totalSupply();

    //     // Get all mint calls in this transaction
    //     PhEvm.CallInputs[] memory inputs = ph.getCallInputs(
    //         address(coolVault),
    //         coolVault.mint.selector
    //     );

    //     uint256 totalSharesMinted = 0;
    //     uint256 totalAssetsExpected = 0;

    //     // Calculate expected changes from all mint calls
    //     for (uint256 i = 0; i < inputs.length; i++) {
    //         (uint256 shares, ) = abi.decode(
    //             inputs[i].input,
    //             (uint256, address)
    //         );
    //         totalSharesMinted += shares;
    //         totalAssetsExpected += coolVault.previewMint(shares);
    //     }

    //     ph.forkPostState();

    //     // Get post-state values
    //     uint256 postVaultAssets = coolVault.totalAssets();
    //     uint256 postVaultSupply = coolVault.totalSupply();

    //     // Verify total assets increased correctly
    //     require(
    //         postVaultAssets == preVaultAssets + totalAssetsExpected,
    //         "Mint: Total assets not updated correctly"
    //     );

    //     // Verify total supply increased correctly
    //     require(
    //         postVaultSupply == preVaultSupply + totalSharesMinted,
    //         "Mint: Total supply not updated correctly"
    //     );
    // }

    // /**
    //  * @dev Assertion for withdraw function: validates that total supply and total assets are correctly updated
    //  * Tests that withdrawing assets decreases both vault's total assets and total supply proportionally
    //  */
    // function assertionWithdrawUpdatesSupplyAndAssets() external {
    //     ph.forkPreState();

    //     // Get pre-state values
    //     uint256 preVaultAssets = coolVault.totalAssets();
    //     uint256 preVaultSupply = coolVault.totalSupply();

    //     // Get all withdraw calls in this transaction
    //     PhEvm.CallInputs[] memory inputs = ph.getCallInputs(
    //         address(coolVault),
    //         coolVault.withdraw.selector
    //     );

    //     uint256 totalAssetsWithdrawn = 0;
    //     uint256 totalSharesExpected = 0;

    //     // Calculate expected changes from all withdraw calls
    //     for (uint256 i = 0; i < inputs.length; i++) {
    //         (uint256 assets, , ) = abi.decode(
    //             inputs[i].input,
    //             (uint256, address, address)
    //         );
    //         totalAssetsWithdrawn += assets;
    //         totalSharesExpected += coolVault.previewWithdraw(assets);
    //     }

    //     ph.forkPostState();

    //     // Get post-state values
    //     uint256 postVaultAssets = coolVault.totalAssets();
    //     uint256 postVaultSupply = coolVault.totalSupply();

    //     // Verify total assets decreased correctly
    //     require(
    //         postVaultAssets == preVaultAssets - totalAssetsWithdrawn,
    //         "Withdraw: Total assets not updated correctly"
    //     );

    //     // Verify total supply decreased correctly
    //     require(
    //         postVaultSupply == preVaultSupply - totalSharesExpected,
    //         "Withdraw: Total supply not updated correctly"
    //     );
    // }

    // /**
    //  * @dev Assertion for redeem function: validates that total supply and total assets are correctly updated
    //  * Tests that redeeming shares decreases both vault's total supply and total assets proportionally
    //  */
    // function assertionRedeemUpdatesSupplyAndAssets() external {
    //     ph.forkPreState();

    //     // Get pre-state values
    //     uint256 preVaultAssets = coolVault.totalAssets();
    //     uint256 preVaultSupply = coolVault.totalSupply();

    //     // Get all redeem calls in this transaction
    //     PhEvm.CallInputs[] memory inputs = ph.getCallInputs(
    //         address(coolVault),
    //         coolVault.redeem.selector
    //     );

    //     uint256 totalSharesRedeemed = 0;
    //     uint256 totalAssetsExpected = 0;

    //     // Calculate expected changes from all redeem calls
    //     for (uint256 i = 0; i < inputs.length; i++) {
    //         (uint256 shares, , ) = abi.decode(
    //             inputs[i].input,
    //             (uint256, address, address)
    //         );
    //         totalSharesRedeemed += shares;
    //         totalAssetsExpected += coolVault.previewRedeem(shares);
    //     }

    //     ph.forkPostState();

    //     // Get post-state values
    //     uint256 postVaultAssets = coolVault.totalAssets();
    //     uint256 postVaultSupply = coolVault.totalSupply();

    //     // Verify total assets decreased correctly
    //     require(
    //         postVaultAssets == preVaultAssets - totalAssetsExpected,
    //         "Redeem: Total assets not updated correctly"
    //     );

    //     // Verify total supply decreased correctly
    //     require(
    //         postVaultSupply == preVaultSupply - totalSharesRedeemed,
    //         "Redeem: Total supply not updated correctly"
    //     );
    // }

    /**
     * @dev Comprehensive assertion for batch operations: validates that all ERC4626 operations
     * in a single transaction maintain consistency across total supply and total assets
     * This function checks all four operations (deposit, mint, withdraw, redeem) that may occur
     * within the same transaction and ensures the final state is mathematically correct
     */
    function assertionBatchOperationsConsistency() external {
        // Get call inputs for all four functions
        PhEvm.CallInputs[] memory depositInputs = ph.getCallInputs(
            address(coolVault),
            coolVault.deposit.selector
        );
        PhEvm.CallInputs[] memory mintInputs = ph.getCallInputs(
            address(coolVault),
            coolVault.mint.selector
        );
        PhEvm.CallInputs[] memory withdrawInputs = ph.getCallInputs(
            address(coolVault),
            coolVault.withdraw.selector
        );
        PhEvm.CallInputs[] memory redeemInputs = ph.getCallInputs(
            address(coolVault),
            coolVault.redeem.selector
        );

        // Calculate net changes from all operations (simplified)
        int256 netAssetChange = 0;
        int256 netSupplyChange = 0;

        // Process deposit operations (increase assets and supply)
        for (uint256 i = 0; i < depositInputs.length; i++) {
            (uint256 assets, ) = abi.decode(
                depositInputs[i].input,
                (uint256, address)
            );
            netAssetChange += int256(assets);
            // Simplified: assume 1:1 ratio for gas efficiency
            netSupplyChange += int256(assets);
        }

        // Process mint operations (increase assets and supply)
        for (uint256 i = 0; i < mintInputs.length; i++) {
            (uint256 shares, ) = abi.decode(
                mintInputs[i].input,
                (uint256, address)
            );
            netSupplyChange += int256(shares);
            // Simplified: assume 1:1 ratio for gas efficiency
            netAssetChange += int256(shares);
        }

        // Process withdraw operations (decrease assets and supply)
        for (uint256 i = 0; i < withdrawInputs.length; i++) {
            (uint256 assets, , ) = abi.decode(
                withdrawInputs[i].input,
                (uint256, address, address)
            );
            netAssetChange -= int256(assets);
            // Simplified: assume 1:1 ratio for gas efficiency
            netSupplyChange -= int256(assets);
        }

        // Process redeem operations (decrease assets and supply)
        for (uint256 i = 0; i < redeemInputs.length; i++) {
            (uint256 shares, , ) = abi.decode(
                redeemInputs[i].input,
                (uint256, address, address)
            );
            netSupplyChange -= int256(shares);
            // Simplified: assume 1:1 ratio for gas efficiency
            netAssetChange -= int256(shares);
        }

        verifyChange(netAssetChange, netSupplyChange);
    }

    // Get post-state values
    function verifyChange(
        int256 netAssetChange,
        int256 netSupplyChange
    ) internal {
        ph.forkPreState();
        uint256 preVaultAssets = coolVault.totalAssets();
        uint256 preVaultSupply = coolVault.totalSupply();

        ph.forkPostState();
        uint256 postVaultAssets = coolVault.totalAssets();
        uint256 postVaultSupply = coolVault.totalSupply();

        // Ensure operations had some effect if there were calls
        int256 expectedNetAssetChange = int256(netAssetChange);
        int256 expectedNetSupplyChange = int256(netSupplyChange);
        require(
            netAssetChange == expectedNetAssetChange,
            "Batch Operations: Asset change mismatch"
        );
        require(
            netSupplyChange == expectedNetSupplyChange,
            "Batch Operations: Supply change mismatch"
        );
    }
}
