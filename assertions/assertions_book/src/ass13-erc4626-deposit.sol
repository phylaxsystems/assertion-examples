// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

interface IERC4626 {
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

contract ERC4626DepositAssertion is Assertion {
    IERC4626 public erc4626 = IERC4626(address(0xbeef));

    function triggers() external view override {
        // Register trigger for deposit calls to the ERC4626 vault
        registerCallTrigger(this.assertionDepositAssets.selector, erc4626.deposit.selector);
        registerCallTrigger(this.assertionDepositShares.selector, erc4626.deposit.selector);
    }

    // Assert that deposits correctly update total assets
    function assertionDepositAssets() external {
        // Get all deposit calls to the ERC4626 vault
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(erc4626), erc4626.deposit.selector);

        // First, do a simple pre/post state check for the overall transaction
        ph.forkPreState();
        uint256 preTotalAssets = erc4626.totalAssets();

        // Get post-state values
        ph.forkPostState();
        uint256 postTotalAssets = erc4626.totalAssets();

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
        // Get all deposit calls to the ERC4626 vault
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(erc4626), erc4626.deposit.selector);

        // Check each deposit call for correct share accounting
        for (uint256 i = 0; i < callInputs.length; i++) {
            (uint256 assets, address receiver) = abi.decode(callInputs[i].input, (uint256, address));

            // Calculate expected shares to be minted for this deposit
            uint256 expectedSharesToMint = erc4626.previewDeposit(assets);

            // Get pre-state share balance for this specific receiver
            ph.forkPreState();
            uint256 preShareBalance = erc4626.balanceOf(receiver);

            // Get post-state share balance for this specific receiver
            ph.forkPostState();
            uint256 postShareBalance = erc4626.balanceOf(receiver);

            // Verify that the receiver received exactly the expected number of shares
            require(
                postShareBalance == expectedSharesToMint + preShareBalance,
                "Deposit shares assertion failed: receiver did not receive expected number of shares"
            );
        }
    }
}
