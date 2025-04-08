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
        registerCallTrigger(this.assertionDeposit.selector, erc4626.deposit.selector);
    }

    // Assert that deposits maintain correct share accounting
    function assertionDeposit() external {
        // Get all deposit calls to the ERC4626 vault
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(erc4626), erc4626.deposit.selector);

        // Check each deposit call
        for (uint256 i = 0; i < callInputs.length; i++) {
            // Get pre-state values
            ph.forkPreState();
            (uint256 assets, address receiver) = abi.decode(callInputs[i].input, (uint256, address));

            // Calculate expected shares and capture pre-state balances
            uint256 expectedShares = erc4626.previewDeposit(assets);
            uint256 preTotalAssets = erc4626.totalAssets();
            uint256 preBalance = erc4626.balanceOf(receiver);

            // Get post-state values
            ph.forkPostState();
            uint256 postBalance = erc4626.balanceOf(receiver);
            uint256 postTotalAssets = erc4626.totalAssets();

            // Verify share accounting is correct
            require(postBalance == expectedShares + preBalance, "Deposit assertion failed: incorrect share balance");
            require(postTotalAssets == preTotalAssets + assets, "Deposit assertion failed: incorrect total assets");
        }
    }
}
