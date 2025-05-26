// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol"; // Using remapping for credible-std
import {CoolVault} from "../../src/CoolVault.sol"; // Ownable contract
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract DepositAssertion is Assertion {
    // The contract we're monitoring
    CoolVault coolVault;

    // Constructor takes the address of the contract to monitor
    constructor(address _coolVault) {
        coolVault = CoolVault(_coolVault);
    }

    // The triggers function tells the Credible Layer which assertion functions to run
    // This is required by the Assertion interface
    function triggers() external view override {
        registerCallTrigger(
            this.assertionDepositIncreasesBalance.selector,
            coolVault.deposit.selector
        );
        registerCallTrigger(
            this.assertionDepositerSharesIncreases.selector,
            coolVault.deposit.selector
        );
    }

    function assertionDepositIncreasesBalance() external {
        // create a snapshot of the blockchain state before the transaction
        ph.forkPreState();

        // get the balance of the vault before the transaction
        uint256 vaultAssetPreBalance = CoolVault(coolVault).totalAssets();

        PhEvm.CallInputs[] memory inputs = ph.getCallInputs(
            address(coolVault),
            coolVault.deposit.selector
        );

        uint256 totalBalanceDeposited = 0;
        for (uint256 i = 0; i < inputs.length; i++) {
            (uint256 assets, address receiver) = abi.decode(
                inputs[i].input,
                (uint256, address)
            );
            totalBalanceDeposited += assets;
        }

        // get the snapshot of state after the transaction
        ph.forkPostState();

        uint256 vaultAssetPostBalance = CoolVault(coolVault).totalAssets();

        require(
            vaultAssetPostBalance ==
                vaultAssetPreBalance + totalBalanceDeposited,
            "Deposit assertion failed"
        );
    }

    function assertionDepositerSharesIncreases() external {
        PhEvm.CallInputs[] memory inputs = ph.getCallInputs(
            address(coolVault),
            coolVault.deposit.selector
        );

        for (uint256 i = 0; i < inputs.length; i++) {
            ph.forkPreState();
            (uint256 assets, address receiver) = abi.decode(
                inputs[i].input,
                (uint256, address)
            );
            uint256 previewPreAssets = CoolVault(coolVault).previewDeposit(
                assets
            );
            address depositer = inputs[0].caller;
            uint256 preShares = CoolVault(coolVault).balanceOf(depositer);

            ph.forkPostState();

            uint256 postShares = CoolVault(coolVault).balanceOf(depositer);

            require(
                postShares == preShares + previewPreAssets,
                "Depositer shares assertion failed"
            );
        }
    }
}
