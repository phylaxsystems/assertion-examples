// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CoolVault} from "../../src/ass2-erc4626-operations.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";
import {MockToken} from "../../src/MockToken.sol";
import {ERC4626OperationsAssertion} from "../src/ass2-erc4626-operations.a.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract TestERC4626OperationsAssertion is CredibleTest, Test {
    // Contract state variables
    CoolVault public vault;
    MockToken public mockToken;
    address public user1 = address(0x1111);
    address public user2 = address(0x2222);
    address public user3 = address(0x3333);
    address public initialOwner = address(0xdead);

    // Set up the test environment
    function setUp() public {
        vm.startPrank(initialOwner);

        // Deploy mock token and vault
        mockToken = new MockToken("MockToken", "MTK", 0); // 0 initial supply, we'll mint as needed
        vault = new CoolVault(mockToken, "CoolVault", "cvTOKEN");

        vm.stopPrank();

        // Setup users with tokens and approvals
        _setupUser(user1, 1000 ether);
        _setupUser(user2, 1000 ether);
        _setupUser(user3, 1000 ether);
        _setupUser(initialOwner, 1000 ether);
    }

    function _setupUser(address user, uint256 amount) internal {
        // Mint tokens to user
        mockToken.mint(user, amount);

        // Approve vault to spend user's tokens
        vm.prank(user);
        mockToken.approve(address(vault), type(uint256).max);
    }

    // Helper function to check vault state consistency
    function _checkVaultConsistency() internal view {
        uint256 totalAssets = vault.totalAssets();
        uint256 totalSupply = vault.totalSupply();
        uint256 actualBalance = mockToken.balanceOf(address(vault));

        // Total assets should equal actual token balance
        assertEq(totalAssets, actualBalance, "Total assets should equal actual token balance");

        // If there are shares, there should be assets (and vice versa for non-empty vault)
        if (totalSupply > 0) {
            assertGt(totalAssets, 0, "If shares exist, assets should exist");
        }
    }

    // Helper function to log vault state for debugging
    function _logVaultState() internal view {
        console.log("=== Vault State ===");
        console.log("Total Assets:", vault.totalAssets());
        console.log("Total Supply:", vault.totalSupply());
        console.log("Token Balance:", mockToken.balanceOf(address(vault)));
        console.log("User1 Shares:", vault.balanceOf(user1));
        console.log("User2 Shares:", vault.balanceOf(user2));
        console.log("==================");
    }

    // ===== Basic Operation Tests =====

    // Test deposit function assertion
    function test_assertionDepositUpdatesSupplyAndAssets() public {
        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionDepositIncreasesBalance.selector
        });

        // Test single deposit
        vm.prank(user1);
        vault.deposit(100 ether, user1);
    }

    // Test mint function assertion
    function test_assertionMintUpdatesSupplyAndAssets() public {
        // First, make an initial deposit to establish exchange rate
        vm.prank(user1);
        vault.deposit(50 ether, user1);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Test mint function
        vm.prank(user2);
        vault.mint(75 ether, user2);
    }

    // Test withdraw function assertion
    function test_assertionWithdrawUpdatesSupplyAndAssets() public {
        // Setup: Users deposit first
        vm.prank(user1);
        vault.deposit(200 ether, user1);

        vm.prank(user2);
        vault.deposit(150 ether, user2);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Test withdraw function
        vm.prank(user1);
        vault.withdraw(50 ether, user1, user1);
    }

    // Test redeem function assertion
    function test_assertionRedeemUpdatesSupplyAndAssets() public {
        // Setup: Users deposit first
        vm.prank(user1);
        vault.deposit(300 ether, user1);

        vm.prank(user2);
        vault.deposit(200 ether, user2);

        // Get user1's share balance for redeem test
        uint256 user1Shares = vault.balanceOf(user1);
        uint256 sharesToRedeem = user1Shares / 4; // Redeem 25% of shares

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Test redeem function
        vm.prank(user1);
        vault.redeem(sharesToRedeem, user1, user1);
    }

    // ===== Base Invariant Tests =====

    function test_assertionVaultAlwaysAccumulatesAssetsWithDeposit() public {
        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionVaultAlwaysAccumulatesAssets.selector
        });

        vm.prank(user1);
        vault.deposit(0.1 ether, user1);
    }

    function test_assertionVaultAlwaysAccumulatesAssetsWithWithdraw() public {
        // Setup: user1 has shares to withdraw
        vm.prank(user1);
        vault.deposit(0.1 ether, user1);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionVaultAlwaysAccumulatesAssets.selector
        });

        vm.prank(user1);
        vault.withdraw(0.1 ether, user1, user1);
    }

    // ===== Accounting Bug Tests =====

    // Test Bug 1: Buggy deposit function that mints extra shares (only when assets == 13)
    function test_buggyDeposit_TriggersAssertion() public {
        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionDepositIncreasesBalance.selector
        });

        // Trigger the buggy deposit with value 13 - this should cause assertion to fail
        // The deposit function mints 10% extra shares when assets == 13
        vm.prank(user1);
        vm.expectRevert("Deposit assertion failed: User did not receive the correct number of shares");
        vault.deposit(13 ether, user1);
    }

    // Test that normal deposit works fine (non-13 values)
    function test_normalDeposit_WorksFine() public {
        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionDepositIncreasesBalance.selector
        });

        // Normal deposit with value != 13 should work fine
        vm.prank(user1);
        vault.deposit(100 ether, user1);
    }

    // Test Bug 2: Buggy mint function that requires fewer assets (only when shares == 13)
    function test_buggyMint_TriggersAssertion() public {
        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Trigger the buggy mint with value 13 - this should cause assertion to fail
        // The mint function only takes 90% of required assets when shares == 13
        vm.prank(user1);
        vm.expectRevert("Batch Operations: Assets added mismatch");
        vault.mint(13 ether, user1);
    }

    // Test that normal mint works fine (non-13 values)
    function test_normalMint_WorksFine() public {
        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Normal mint with value != 13 should work fine
        vm.prank(user2);
        vault.mint(50 ether, user2);
    }

    // Test Bug 3: Buggy withdraw function that burns fewer shares (only when assets == 13)
    function test_buggyWithdraw_TriggersAssertion() public {
        // Setup: user1 has shares to withdraw using normal deposit
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Trigger the buggy withdraw with value 13 - this should cause assertion to fail
        // The withdraw function burns 5% fewer shares when assets == 13
        vm.prank(user1);
        vm.expectRevert("Batch Operations: Shares removed mismatch");
        vault.withdraw(13 ether, user1, user1);
    }

    // Test that normal withdraw works fine (non-13 values)
    function test_normalWithdraw_WorksFine() public {
        // Setup: user1 has shares to withdraw
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Normal withdraw with value != 13 should work fine
        vm.prank(user1);
        vault.withdraw(50 ether, user1, user1);
    }

    // Test Bug 4: Buggy redeem function that gives extra assets (only when shares == 13)
    function test_buggyRedeem_TriggersAssertion() public {
        // Setup: user1 has shares to redeem using normal deposit
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Trigger the buggy redeem with value 13 - this should cause assertion to fail
        // The redeem function gives 15% more assets when shares == 13
        vm.prank(user1);
        vm.expectRevert("Batch Operations: Assets removed mismatch");
        vault.redeem(13 ether, user1, user1);
    }

    // Test that normal redeem works fine (non-13 values)
    function test_normalRedeem_WorksFine() public {
        // Setup: user1 has shares to redeem
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Normal redeem with value != 13 should work fine
        vm.prank(user1);
        vault.redeem(50 ether, user1, user1);
    }

    // Test redeem functionality without using assertion library
    function test_normalRedeem_WorksFine_NoAssertion() public {
        // Log initial state
        console.log("=== Initial State ===");
        _logVaultState();

        // Setup: user1 has shares to redeem
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        // Log state after deposit
        console.log("\n=== State After Deposit ===");
        _logVaultState();

        // Get initial balances
        uint256 initialUser1Shares = vault.balanceOf(user1);
        uint256 initialUser1Assets = mockToken.balanceOf(user1);
        uint256 initialVaultAssets = mockToken.balanceOf(address(vault));

        console.log("\n=== Pre-Redeem Balances ===");
        console.log("User1 Shares:", initialUser1Shares);
        console.log("User1 Assets:", initialUser1Assets);
        console.log("Vault Assets:", initialVaultAssets);

        // Perform redeem
        vm.prank(user1);
        uint256 sharesToRedeem = 50 ether;
        uint256 assetsReceived = vault.redeem(sharesToRedeem, user1, user1);

        // Log state after redeem
        console.log("\n=== State After Redeem ===");
        _logVaultState();

        // Get final balances
        uint256 finalUser1Shares = vault.balanceOf(user1);
        uint256 finalUser1Assets = mockToken.balanceOf(user1);
        uint256 finalVaultAssets = mockToken.balanceOf(address(vault));

        console.log("\n=== Post-Redeem Balances ===");
        console.log("User1 Shares:", finalUser1Shares);
        console.log("User1 Assets:", finalUser1Assets);
        console.log("Vault Assets:", finalVaultAssets);
        console.log("Assets Received:", assetsReceived);

        // Verify the redeem operation
        assertEq(finalUser1Shares, initialUser1Shares - sharesToRedeem, "Shares not burned correctly");
        assertEq(finalUser1Assets, initialUser1Assets + assetsReceived, "Assets not received correctly");
        assertEq(finalVaultAssets, initialVaultAssets - assetsReceived, "Vault assets not decreased correctly");
        assertEq(assetsReceived, sharesToRedeem, "Assets received should equal shares redeemed in 1:1 vault");
    }

    // ===== Batch Operation Tests =====

    // Test multiple operations in sequence to ensure consistency
    function test_multipleOperationsSequence() public {
        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // 1. Initial deposits
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        vm.prank(user2);
        vault.deposit(150 ether, user2);

        // 2. Mint shares (smaller amount to avoid exchange rate issues)
        vm.prank(user3);
        vault.mint(25 ether, user3);

        // 3. Withdraw some assets (use maxWithdraw to ensure we don't exceed limits)
        uint256 maxWithdrawUser1 = vault.maxWithdraw(user1);
        uint256 withdrawAmount = maxWithdrawUser1 / 10; // Withdraw 10% of max
        vm.prank(user1);
        vault.withdraw(withdrawAmount, user1, user1);

        // 4. Redeem some shares (use maxRedeem to ensure we don't exceed limits)
        uint256 maxRedeemUser2 = vault.maxRedeem(user2);
        uint256 redeemAmount = maxRedeemUser2 / 10; // Redeem 10% of max
        vm.prank(user2);
        vault.redeem(redeemAmount, user2, user2);
    }

    // Test batch operations with mixed deposit/withdraw in same transaction
    function test_batchMixedOperations() public {
        // Setup initial state
        vm.prank(user1);
        vault.deposit(1000 ether, user1);

        vm.prank(user2);
        vault.deposit(800 ether, user2);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Test a deposit followed by a withdrawal in the same validation
        // This tests the batch assertion's ability to handle net changes
        vm.prank(user3);
        vault.deposit(200 ether, user3);
    }

    // Test batch operations with all four functions
    function test_batchAllFourOperations() public {
        // Setup: All users have deposits and shares
        vm.prank(user1);
        vault.deposit(400 ether, user1);

        vm.prank(user2);
        vault.deposit(300 ether, user2);

        vm.prank(user3);
        vault.deposit(200 ether, user3);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Test deposit operation (will trigger batch assertion)
        vm.prank(user1);
        vault.deposit(50 ether, user1);

        // Test mint operation
        vm.prank(user2);
        vault.mint(25 ether, user2);

        // Test withdraw operation
        uint256 maxWithdraw = vault.maxWithdraw(user3);
        vm.prank(user3);
        vault.withdraw(maxWithdraw / 5, user3, user3);

        // Test redeem operation
        uint256 maxRedeem = vault.maxRedeem(user1);
        vm.prank(user1);
        vault.redeem(maxRedeem / 10, user1, user1);
    }

    // ===== Edge Case Tests =====

    // Test edge case: operations with zero amounts (should still maintain consistency)
    function test_zeroAmountOperations() public {
        // Setup with initial deposit
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Test zero deposit (should not change totals)
        vm.prank(user2);
        vault.deposit(0, user2);
    }

    // Test large amounts to ensure no overflow issues
    function test_largeAmountOperations() public {
        // Setup users with large amounts
        uint256 largeAmount = 1e24; // 1 million tokens with 18 decimals
        _setupUser(user1, largeAmount);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Test large deposit
        vm.prank(user1);
        vault.deposit(largeAmount / 2, user1);
    }

    // Test edge case: batch operations with zero amounts
    function test_batchOperationsWithZeroAmounts() public {
        // Setup initial state
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.assertion({
            adopter: address(vault),
            createData: type(ERC4626OperationsAssertion).creationCode,
            fnSelector: ERC4626OperationsAssertion.assertionBatchOperationsConsistency.selector
        });

        // Test zero amount operations (should maintain consistency)
        vm.prank(user2);
        vault.deposit(0, user2);

        vm.prank(user2);
        vault.mint(0, user2);
    }
}

// Contract that batches multiple ERC4626 operations including buggy ones
contract BatchOperations {
    CoolVault public vault;
    MockToken public token;

    constructor(address vault_, address token_) {
        vault = CoolVault(vault_);
        token = MockToken(token_);

        // Approve the vault to spend our tokens
        token.approve(address(vault), type(uint256).max);
    }

    fallback() external {
        // Make multiple operations in a single transaction
        // Some of these will trigger bugs due to the special value 13

        // Normal deposits first to establish some balance
        vault.deposit(100 ether, address(this));
        vault.deposit(50 ether, address(this));

        // Buggy deposit (triggers extra shares bug)
        vault.deposit(13 ether, address(this));

        // Normal mint
        vault.mint(25 ether, address(this));

        // Buggy mint (triggers fewer assets bug)
        vault.mint(13 ether, address(this));

        // More normal operations
        vault.deposit(75 ether, address(this));

        // Now try some withdrawals/redeems with bugs
        // Buggy withdraw (triggers fewer shares burned bug)
        vault.withdraw(13 ether, address(this), address(this));

        // Buggy redeem (triggers extra assets bug)
        vault.redeem(13 ether, address(this), address(this));

        // Normal operations
        vault.withdraw(20 ether, address(this), address(this));
        vault.redeem(10 ether, address(this), address(this));
    }
}

// Contract that batches multiple normal ERC4626 operations (no bugs)
contract BatchNormalOperations {
    CoolVault public vault;
    MockToken public token;

    constructor(address vault_, address token_) {
        vault = CoolVault(vault_);
        token = MockToken(token_);

        // Approve the vault to spend our tokens
        token.approve(address(vault), type(uint256).max);
    }

    fallback() external {
        // Make multiple operations in a single transaction
        // All using non-buggy values (avoiding 13)

        // Multiple deposits
        vault.deposit(100 ether, address(this));

        // Multiple mints
        vault.mint(40 ether, address(this));

        // Multiple withdrawals
        vault.withdraw(10 ether, address(this), address(this));

        // Multiple redeems
        vault.redeem(10 ether, address(this), address(this));
    }
}
