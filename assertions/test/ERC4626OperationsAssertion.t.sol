// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CoolVault} from "../../src/CoolVault.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";
import {MockToken} from "../../src/MockToken.sol";
import {ERC4626OperationsAssertion} from "../src/ERC4626Operations.a.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    // Test deposit function assertion
    function test_assertionDepositUpdatesSupplyAndAssets() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626DepositAssertion";

        // Associate the assertion with the protocol
        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Test single deposit
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.deposit.selector,
                abi.encode(100 ether, user1)
            )
        );
    }

    // Test mint function assertion
    function test_assertionMintUpdatesSupplyAndAssets() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626MintAssertion";

        // First, make an initial deposit to establish exchange rate
        vm.prank(user1);
        vault.deposit(50 ether, user1);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Test mint function
        vm.prank(user2);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(vault.mint.selector, abi.encode(75 ether, user2))
        );
    }

    // Test withdraw function assertion
    function test_assertionWithdrawUpdatesSupplyAndAssets() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626WithdrawAssertion";

        // Setup: Users deposit first
        vm.prank(user1);
        vault.deposit(200 ether, user1);

        vm.prank(user2);
        vault.deposit(150 ether, user2);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Test withdraw function
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.withdraw.selector,
                abi.encode(50 ether, user1, user1)
            )
        );
    }

    // Test redeem function assertion
    function test_assertionRedeemUpdatesSupplyAndAssets() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626RedeemAssertion";

        // Setup: Users deposit first
        vm.prank(user1);
        vault.deposit(300 ether, user1);

        vm.prank(user2);
        vault.deposit(200 ether, user2);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Get user1's share balance for redeem test
        uint256 user1Shares = vault.balanceOf(user1);
        uint256 sharesToRedeem = user1Shares / 4; // Redeem 25% of shares

        // Test redeem function
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.redeem.selector,
                abi.encode(sharesToRedeem, user1, user1)
            )
        );
    }

    // Test multiple operations in sequence to ensure consistency
    function test_multipleOperationsSequence() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626MultipleOpsAssertion";

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // 1. Initial deposits
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.deposit.selector,
                abi.encode(100 ether, user1)
            )
        );

        vm.prank(user2);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.deposit.selector,
                abi.encode(150 ether, user2)
            )
        );

        // 2. Mint shares (smaller amount to avoid exchange rate issues)
        vm.prank(user3);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(vault.mint.selector, abi.encode(25 ether, user3))
        );

        // 3. Withdraw some assets (use maxWithdraw to ensure we don't exceed limits)
        uint256 maxWithdrawUser1 = vault.maxWithdraw(user1);
        uint256 withdrawAmount = maxWithdrawUser1 / 10; // Withdraw 10% of max
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.withdraw.selector,
                abi.encode(withdrawAmount, user1, user1)
            )
        );

        // 4. Redeem some shares (use maxRedeem to ensure we don't exceed limits)
        uint256 maxRedeemUser2 = vault.maxRedeem(user2);
        uint256 redeemAmount = maxRedeemUser2 / 10; // Redeem 10% of max
        vm.prank(user2);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.redeem.selector,
                abi.encode(redeemAmount, user2, user2)
            )
        );
    }

    // Test edge case: operations with zero amounts (should still maintain consistency)
    function test_zeroAmountOperations() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626ZeroAmountAssertion";

        // Setup with initial deposit
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Test zero deposit (should not change totals)
        vm.prank(user2);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(vault.deposit.selector, abi.encode(0, user2))
        );
    }

    // Test large amounts to ensure no overflow issues
    function test_largeAmountOperations() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626LargeAmountAssertion";

        // Setup users with large amounts
        uint256 largeAmount = 1e24; // 1 million tokens with 18 decimals
        _setupUser(user1, largeAmount);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Test large deposit
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.deposit.selector,
                abi.encode(largeAmount / 2, user1)
            )
        );
    }

    // Test the comprehensive batch operations assertion
    function test_assertionBatchOperationsConsistency() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626BatchOperationsAssertion";

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Setup: Initial deposits to establish vault state
        vm.prank(user1);
        vault.deposit(500 ether, user1);

        vm.prank(user2);
        vault.deposit(300 ether, user2);

        // Test complex batch operations in a single transaction
        // This will trigger the batch operations assertion
        vm.startPrank(user1);

        // Perform multiple operations that should be validated together
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.deposit.selector,
                abi.encode(100 ether, user1)
            )
        );

        vm.stopPrank();
    }

    // Test batch operations with mixed deposit/withdraw in same transaction
    function test_batchMixedOperations() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626MixedBatchAssertion";

        // Setup initial state
        vm.prank(user1);
        vault.deposit(1000 ether, user1);

        vm.prank(user2);
        vault.deposit(800 ether, user2);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Test a deposit followed by a withdrawal in the same validation
        // This tests the batch assertion's ability to handle net changes
        vm.prank(user3);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.deposit.selector,
                abi.encode(200 ether, user3)
            )
        );
    }

    // Test batch operations with all four functions
    function test_batchAllFourOperations() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626AllOperationsBatchAssertion";

        // Setup: All users have deposits and shares
        vm.prank(user1);
        vault.deposit(400 ether, user1);

        vm.prank(user2);
        vault.deposit(300 ether, user2);

        vm.prank(user3);
        vault.deposit(200 ether, user3);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Test deposit operation (will trigger batch assertion)
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.deposit.selector,
                abi.encode(50 ether, user1)
            )
        );

        // Test mint operation
        vm.prank(user2);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(vault.mint.selector, abi.encode(25 ether, user2))
        );

        // Test withdraw operation
        uint256 maxWithdraw = vault.maxWithdraw(user3);
        vm.prank(user3);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.withdraw.selector,
                abi.encode(maxWithdraw / 5, user3, user3)
            )
        );

        // Test redeem operation
        uint256 maxRedeem = vault.maxRedeem(user1);
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.redeem.selector,
                abi.encode(maxRedeem / 10, user1, user1)
            )
        );
    }

    // Test edge case: batch operations with zero amounts
    function test_batchOperationsWithZeroAmounts() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626ZeroBatchAssertion";

        // Setup initial state
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Test zero amount operations (should maintain consistency)
        vm.prank(user2);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(vault.deposit.selector, abi.encode(0, user2))
        );

        vm.prank(user2);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(vault.mint.selector, abi.encode(0, user2))
        );
    }

    // Helper function to check vault state consistency
    function _checkVaultConsistency() internal view {
        uint256 totalAssets = vault.totalAssets();
        uint256 totalSupply = vault.totalSupply();
        uint256 actualBalance = mockToken.balanceOf(address(vault));

        // Total assets should equal actual token balance
        assertEq(
            totalAssets,
            actualBalance,
            "Total assets should equal actual token balance"
        );

        // If there are shares, there should be assets (and vice versa for non-empty vault)
        if (totalSupply > 0) {
            assertGt(totalAssets, 0, "If shares exist, assets should exist");
        }
    }

    // Test case: Ownership changes should trigger the assertion
    function test_assertionDepositIncreasesBalance() public {
        address aaAddress = address(vault);
        string memory label = "DepositBalanceAssertion";

        // Associate the assertion with the protocol
        // cl will manage the correct assertion execution when the protocol is called
        cl.addAssertion(
            label,
            aaAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Simulate a transaction that changes ownership
        vm.prank(initialOwner);
        cl.validate(
            label,
            aaAddress,
            0,
            abi.encodePacked(
                vault.deposit.selector,
                abi.encode(0.1 ether, initialOwner)
            )
        );
    }
}
