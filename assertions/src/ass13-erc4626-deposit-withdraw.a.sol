// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract ERC4626DepositWithdrawAssertion is Assertion {
    // Used to store the last known good share value
    uint256 private lastKnownShareValue;

    // Tolerance for precision/rounding errors (0.01%)
    uint256 private constant PRECISION_TOLERANCE = 1e14; // 0.01% of 1e18

    function triggers() external view override {
        // Register triggers for deposit operations
        registerCallTrigger(this.assertionDepositAssets.selector, IERC4626.deposit.selector);
        registerCallTrigger(this.assertionDepositShares.selector, IERC4626.deposit.selector);

        // Register triggers for withdraw operations
        registerCallTrigger(this.assertionWithdrawAssets.selector, IERC4626.withdraw.selector);
        registerCallTrigger(this.assertionWithdrawShares.selector, IERC4626.withdraw.selector);

        // Register trigger for share value monotonicity
        // This can be triggered by various operations
        registerCallTrigger(this.assertionShareValueMonotonicity.selector, IERC4626.deposit.selector);
        registerCallTrigger(this.assertionShareValueMonotonicity.selector, IERC4626.withdraw.selector);
    }

    // Assert that deposits correctly update total assets
    function assertionDepositAssets() external {
        // Get the assertion adopter address
        IERC4626 adopter = IERC4626(ph.getAssertionAdopter());

        // Get all deposit calls to the ERC4626 vault
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.deposit.selector);

        // First, do a simple pre/post state check for the overall transaction
        ph.forkPreTx();
        uint256 preTotalAssets = adopter.totalAssets();

        // Get post-state values
        ph.forkPostTx();
        uint256 postTotalAssets = adopter.totalAssets();

        // Calculate total assets deposited across all calls
        uint256 totalAssetsDeposited = 0;
        for (uint256 i = 0; i < callInputs.length; i++) {
            (uint256 assets,) = abi.decode(callInputs[i].input, (uint256, address));
            totalAssetsDeposited += assets;
        }

        // Verify total assets increased by exactly the deposited amount
        require(
            postTotalAssets == preTotalAssets + totalAssetsDeposited,
            "Deposit assets assertion failed: incorrect total assets"
        );
    }

    // Assert that deposits maintain correct share accounting
    function assertionDepositShares() external {
        // Get the assertion adopter address
        IERC4626 adopter = IERC4626(ph.getAssertionAdopter());

        // Get all deposit calls to the ERC4626 vault
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.deposit.selector);

        // Get pre-state values for total assets and total supply
        ph.forkPreTx();
        uint256 preTotalAssets = adopter.totalAssets();
        uint256 preTotalSupply = adopter.totalSupply();

        // Get post-state values for total assets and total supply
        ph.forkPostTx();
        uint256 postTotalAssets = adopter.totalAssets();
        uint256 postTotalSupply = adopter.totalSupply();

        // Calculate total assets deposited and total shares minted across all calls
        uint256 totalAssetsDeposited = 0;
        uint256 totalSharesMinted = 0;

        for (uint256 i = 0; i < callInputs.length; i++) {
            (uint256 assets, address receiver) = abi.decode(callInputs[i].input, (uint256, address));
            totalAssetsDeposited += assets;

            // Get pre and post share balances for this receiver
            ph.forkPreTx();
            uint256 preShareBalance = adopter.balanceOf(receiver);
            ph.forkPostTx();
            uint256 postShareBalance = adopter.balanceOf(receiver);

            totalSharesMinted += (postShareBalance - preShareBalance);
        }

        // Verify that total assets increased by exactly the deposited amount
        require(
            postTotalAssets == preTotalAssets + totalAssetsDeposited,
            "Deposit shares assertion failed: total assets not updated correctly"
        );

        // Verify that total supply increased by exactly the minted shares
        require(
            postTotalSupply == preTotalSupply + totalSharesMinted,
            "Deposit shares assertion failed: total supply not updated correctly"
        );

        // Verify that the share-to-asset ratio remains consistent
        // This is the key check that will catch the vulnerability
        uint256 preAssetsPerShare = preTotalSupply > 0 ? (preTotalAssets * 1e18) / preTotalSupply : 0;
        uint256 postAssetsPerShare = postTotalSupply > 0 ? (postTotalAssets * 1e18) / postTotalSupply : 0;

        // Allow for minimal precision/rounding errors
        require(
            postAssetsPerShare >= preAssetsPerShare || preAssetsPerShare - postAssetsPerShare <= PRECISION_TOLERANCE,
            "Deposit shares assertion failed: share-to-asset ratio decreased unexpectedly"
        );
    }

    // Assert that withdrawals correctly update total assets
    function assertionWithdrawAssets() external {
        // Get the assertion adopter address
        IERC4626 adopter = IERC4626(ph.getAssertionAdopter());

        // Get all withdraw calls to the ERC4626 vault
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.withdraw.selector);

        // First, do a simple pre/post state check for the overall transaction
        ph.forkPreTx();
        uint256 preTotalAssets = adopter.totalAssets();

        // Get post-state values
        ph.forkPostTx();
        uint256 postTotalAssets = adopter.totalAssets();

        // Calculate total assets withdrawn across all calls
        uint256 totalAssetsWithdrawn = 0;
        for (uint256 i = 0; i < callInputs.length; i++) {
            (uint256 assets,,) = abi.decode(callInputs[i].input, (uint256, address, address));
            totalAssetsWithdrawn += assets;
        }

        // Verify total assets decreased by exactly the withdrawn amount
        require(
            postTotalAssets == preTotalAssets - totalAssetsWithdrawn,
            "Withdraw assets assertion failed: incorrect total assets"
        );
    }

    // Assert that withdrawals maintain correct share accounting
    function assertionWithdrawShares() external {
        // Get the assertion adopter address
        IERC4626 adopter = IERC4626(ph.getAssertionAdopter());

        // Get all withdraw calls to the ERC4626 vault
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(adopter), adopter.withdraw.selector);

        // Get pre-state values for total assets and total supply
        ph.forkPreTx();
        uint256 preTotalAssets = adopter.totalAssets();
        uint256 preTotalSupply = adopter.totalSupply();

        // Get post-state values for total assets and total supply
        ph.forkPostTx();
        uint256 postTotalAssets = adopter.totalAssets();
        uint256 postTotalSupply = adopter.totalSupply();

        // Calculate total assets withdrawn and total shares burned across all calls
        uint256 totalAssetsWithdrawn = 0;
        uint256 totalSharesBurned = 0;

        for (uint256 i = 0; i < callInputs.length; i++) {
            (uint256 assets,, address owner) = abi.decode(callInputs[i].input, (uint256, address, address));
            totalAssetsWithdrawn += assets;

            // Get pre and post share balances for this owner
            ph.forkPreTx();
            uint256 preShareBalance = adopter.balanceOf(owner);
            ph.forkPostTx();
            uint256 postShareBalance = adopter.balanceOf(owner);

            totalSharesBurned += (preShareBalance - postShareBalance);
        }

        // Verify that total assets decreased by exactly the withdrawn amount
        require(
            postTotalAssets == preTotalAssets - totalAssetsWithdrawn,
            "Withdraw shares assertion failed: total assets not updated correctly"
        );

        // Verify that total supply decreased by exactly the burned shares
        require(
            postTotalSupply == preTotalSupply - totalSharesBurned,
            "Withdraw shares assertion failed: total supply not updated correctly"
        );

        // Verify that the share-to-asset ratio remains consistent
        // This is the key check that will catch the vulnerability
        uint256 preAssetsPerShare = preTotalSupply > 0 ? (preTotalAssets * 1e18) / preTotalSupply : 0;
        uint256 postAssetsPerShare = postTotalSupply > 0 ? (postTotalAssets * 1e18) / postTotalSupply : 0;

        // Allow for minimal precision/rounding errors
        require(
            postAssetsPerShare >= preAssetsPerShare || preAssetsPerShare - postAssetsPerShare <= PRECISION_TOLERANCE,
            "Withdraw shares assertion failed: share-to-asset ratio decreased unexpectedly"
        );
    }

    // Assert that share value never decreases unexpectedly
    function assertionShareValueMonotonicity() external {
        // Get the assertion adopter address
        IERC4626 adopter = IERC4626(ph.getAssertionAdopter());

        // Create a snapshot of the state before any transactions
        ph.forkPreTx();
        uint256 assetsPerSharePre = _calculateAssetsPerShare(adopter);

        // Get state after transaction
        ph.forkPostTx();
        uint256 assetsPerSharePost = _calculateAssetsPerShare(adopter);

        // Allow for minimal precision/rounding errors with a small tolerance
        require(
            assetsPerSharePost >= assetsPerSharePre || assetsPerSharePre - assetsPerSharePost <= PRECISION_TOLERANCE,
            "Share value decreased unexpectedly"
        );

        // If share value increased, update the last known good value
        if (assetsPerSharePost > assetsPerSharePre) {
            lastKnownShareValue = assetsPerSharePost;
        }

        // Note: In practice, you would want to add detection for legitimate cases where
        // share value might decrease, such as:
        //
        // 1. Fee collection events - Some vaults charge periodic fees by reducing share value
        //    This could be detected by:
        //    - Checking specific fee collection function calls
        //    - Looking for fee events emitted by the vault
        //    - Using a timestamp-based approach to see if a fee collection period has occurred
        //    - Adding a fee collection flag or method to the vault interface
        //
        // 2. Investment loss events - When underlying investments lose value
        //    This could be detected by:
        //    - Monitoring for loss events emitted by the vault
        //    - Tracking investment strategy function calls that might result in losses
        //    - Detecting significant changes in underlying asset values
        //    - Adding a loss event flag or method to the vault interface
        //
        // These detection mechanisms should be customized based on the specific
        // implementation of the vault you're working with.
    }

    // Helper function to calculate assets per share with 1e18 precision
    function _calculateAssetsPerShare(IERC4626 vault) internal view returns (uint256) {
        uint256 totalSupply = vault.totalSupply();
        if (totalSupply == 0) {
            return lastKnownShareValue; // Return last known value if supply is zero
        }

        uint256 totalAssets = vault.totalAssets();
        return (totalAssets * 1e18) / totalSupply;
    }
}

interface IERC4626 {
    // Deposit/mint
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);

    // Withdraw/redeem
    function withdraw(uint256 assets, address receiver, address owner) external returns (uint256);
    function previewWithdraw(uint256 assets) external view returns (uint256);

    // View functions
    function totalAssets() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function asset() external view returns (address);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}
