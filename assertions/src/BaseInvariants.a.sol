// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol"; // Using remapping for credible-std
import {CoolVault} from "../../src/CoolVault.sol"; // Ownable contract
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract BaseInvariantsAssertion is Assertion {
    // The contract we're monitoring
    CoolVault coolVault;

    // Constructor takes the address of the contract to monitor
    constructor(address _coolVault) {
        coolVault = CoolVault(_coolVault);
    }

    // The triggers function tells the Credible Layer which assertion functions to run
    // This is required by the Assertion interface
    function triggers() external view override {
        registerStorageChangeTrigger(
            this.assertionVaultAlwaysAccumulatesAssets.selector,
            bytes32(uint256(2))
        );
    }

    function assertionVaultAlwaysAccumulatesAssets() external {
        ph.forkPostState();

        uint256 vaultAssetPostBalance = CoolVault(coolVault).totalAssets();
        uint256 vaultSharesPostBalance = CoolVault(coolVault).balanceOf(
            address(coolVault)
        );

        require(
            vaultAssetPostBalance >= vaultSharesPostBalance,
            "There are less underlying assets than shares"
        );
    }
}
