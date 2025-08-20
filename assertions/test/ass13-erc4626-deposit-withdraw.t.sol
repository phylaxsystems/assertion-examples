// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {ERC4626Vault} from "../../src/ass13-erc4626-deposit-withdraw.sol";
import {ERC4626DepositWithdrawAssertion} from "../src/ass13-erc4626-deposit-withdraw.a.sol";

contract TestERC4626DepositWithdraw is CredibleTest, Test {
    // Contract state variables
    ERC4626Vault public protocol;
    address public user = address(0x1234);
    uint256 public depositAmount = 1 ether; // Using 1 ether (1e18) instead of 1000
    uint256 public withdrawAmount = 0.5 ether; // Using 0.5 ether (5e17) instead of 500

    // Special amounts that trigger bugs in the protocol
    uint256 public constant SPECIAL_DEPOSIT_AMOUNT = 13 ether;
    uint256 public constant SPECIAL_WITHDRAW_AMOUNT = 7 ether;

    function setUp() public {
        // Deploy the protocol with a mock token (pass address(0) to let it create one)
        protocol = new ERC4626Vault(address(0));

        vm.deal(user, 100 ether);

        // Set initial asset balances for our mock asset
        protocol.setAssetBalance(user, 30 ether); // 30 ether to have enough for special cases
        protocol.setAssetBalance(address(protocol), 0);
    }

    function test_assertionDepositAssets_pass() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(ERC4626DepositWithdrawAssertion).creationCode,
            fnSelector: ERC4626DepositWithdrawAssertion.assertionDepositAssets.selector
        });

        vm.prank(user);
        // This should pass because we're depositing assets correctly
        protocol.deposit(depositAmount, user);
    }

    function test_assertionDepositAssets_fail() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(ERC4626DepositWithdrawAssertion).creationCode,
            fnSelector: ERC4626DepositWithdrawAssertion.assertionDepositAssets.selector
        });

        // The deposit of exactly 13 ether will trigger the special case
        // where _totalAssets is incorrectly updated (1 ether less)
        vm.prank(user);
        // This should fail because the deposit function has a special case
        // that deliberately miscalculates assets when exactly 13 ether is deposited
        vm.expectRevert("Deposit assets assertion failed: incorrect total assets");
        protocol.deposit(SPECIAL_DEPOSIT_AMOUNT, user);
    }

    function test_assertionWithdrawAssets_pass() public {
        // First deposit some assets
        vm.prank(user);
        protocol.deposit(depositAmount, user);

        cl.assertion({
            adopter: address(protocol),
            createData: type(ERC4626DepositWithdrawAssertion).creationCode,
            fnSelector: ERC4626DepositWithdrawAssertion.assertionWithdrawAssets.selector
        });

        vm.prank(user);
        // This should pass because we're withdrawing assets correctly
        protocol.withdraw(withdrawAmount, user, user);
    }

    function test_assertionWithdrawAssets_fail() public {
        // First deposit enough assets to cover the special withdrawal amount
        vm.prank(user);
        protocol.deposit(SPECIAL_WITHDRAW_AMOUNT * 2, user); // Double to ensure enough balance

        cl.assertion({
            adopter: address(protocol),
            createData: type(ERC4626DepositWithdrawAssertion).creationCode,
            fnSelector: ERC4626DepositWithdrawAssertion.assertionWithdrawAssets.selector
        });

        vm.prank(user);
        // This should fail because the withdraw function has a special case
        // that deliberately miscalculates assets when exactly 7 ether is withdrawn
        vm.expectRevert("Withdraw assets assertion failed: incorrect total assets");
        protocol.withdraw(SPECIAL_WITHDRAW_AMOUNT, user, user);
    }

    function test_assertionPreviewDeposit_pass() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(ERC4626DepositWithdrawAssertion).creationCode,
            fnSelector: ERC4626DepositWithdrawAssertion.assertionDepositShares.selector
        });

        vm.prank(user);
        // This should pass because we're previewing a deposit correctly
        protocol.deposit(depositAmount, user);
    }

    function test_assertionPreviewDeposit_fail() public {
        cl.assertion({
            adopter: address(protocol),
            createData: type(ERC4626DepositWithdrawAssertion).creationCode,
            fnSelector: ERC4626DepositWithdrawAssertion.assertionDepositShares.selector
        });

        // Try depositing the special amount (13 ether), which should fail because
        // the vault has a deliberate accounting error for this specific amount
        vm.prank(user);
        vm.expectRevert("Deposit shares assertion failed: total assets not updated correctly");
        protocol.deposit(SPECIAL_DEPOSIT_AMOUNT, user);
    }

    function test_assertionPreviewWithdraw_pass() public {
        // First deposit some assets
        vm.prank(user);
        protocol.deposit(depositAmount, user);

        cl.assertion({
            adopter: address(protocol),
            createData: type(ERC4626DepositWithdrawAssertion).creationCode,
            fnSelector: ERC4626DepositWithdrawAssertion.assertionWithdrawShares.selector
        });

        vm.prank(user);
        // This should pass because we're previewing a withdrawal correctly
        protocol.withdraw(withdrawAmount, user, user);
    }

    function test_assertionPreviewWithdraw_fail() public {
        // First deposit enough assets to cover the special withdrawal amount
        vm.prank(user);
        protocol.deposit(SPECIAL_WITHDRAW_AMOUNT * 2, user); // Double to ensure enough balance

        cl.assertion({
            adopter: address(protocol),
            createData: type(ERC4626DepositWithdrawAssertion).creationCode,
            fnSelector: ERC4626DepositWithdrawAssertion.assertionWithdrawShares.selector
        });

        // Use the special withdrawal amount that triggers the vulnerability
        vm.prank(user);
        vm.expectRevert("Withdraw shares assertion failed: total assets not updated correctly");
        protocol.withdraw(SPECIAL_WITHDRAW_AMOUNT, user, user);
    }
}
