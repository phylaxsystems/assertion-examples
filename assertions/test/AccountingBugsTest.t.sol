// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CoolVault} from "../../src/CoolVault.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";
import {MockToken} from "../../src/MockToken.sol";
import {ERC4626OperationsAssertion} from "../src/ERC4626Operations.a.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {console} from "forge-std/console.sol";

contract TestAccountingBugs is CredibleTest, Test {
    // Contract state variables
    CoolVault public vault;
    MockToken public mockToken;
    address public user1 = address(0x1111);
    address public user2 = address(0x2222);
    address public initialOwner = address(0xdead);

    // Set up the test environment
    function setUp() public {
        vm.startPrank(initialOwner);

        // Deploy mock token and vault
        mockToken = new MockToken("MockToken", "MTK", 0);
        vault = new CoolVault(mockToken, "CoolVault", "cvTOKEN");

        vm.stopPrank();

        // Setup users with tokens and approvals
        _setupUser(user1, 1000 ether);
        _setupUser(user2, 1000 ether);
        _setupUser(initialOwner, 1000 ether);
    }

    function _setupUser(address user, uint256 amount) internal {
        mockToken.mint(user, amount);
        vm.prank(user);
        mockToken.approve(address(vault), type(uint256).max);
    }

    // Test Bug 1: Buggy deposit function that mints extra shares (only when assets == 13)
    function test_buggyDeposit_TriggersAssertion() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626DepositBugTest";

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Trigger the buggy deposit with value 13 - this should cause assertion to fail
        // The deposit function mints 10% extra shares when assets == 13
        vm.prank(user1);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.deposit.selector,
                abi.encode(13 ether, user1)
            )
        );
    }

    // Test that normal deposit works fine (non-13 values)
    function test_normalDeposit_WorksFine() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626NormalDepositTest";

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Normal deposit with value != 13 should work fine
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

    // Test Bug 2: Buggy mint function that requires fewer assets (only when shares == 13)
    function test_buggyMint_TriggersAssertion() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626MintBugTest";

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Trigger the buggy mint with value 13 - this should cause assertion to fail
        // The mint function only takes 90% of required assets when shares == 13
        vm.prank(user1);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(vault.mint.selector, abi.encode(13 ether, user1))
        );
    }

    // Test that normal mint works fine (non-13 values)
    function test_normalMint_WorksFine() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626NormalMintTest";

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Normal mint with value != 13 should work fine
        vm.prank(user2);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(vault.mint.selector, abi.encode(50 ether, user2))
        );
    }

    // Test Bug 3: Buggy withdraw function that burns fewer shares (only when assets == 13)
    function test_buggyWithdraw_TriggersAssertion() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626WithdrawBugTest";

        // Setup: user1 has shares to withdraw using normal deposit
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Trigger the buggy withdraw with value 13 - this should cause assertion to fail
        // The withdraw function burns 5% fewer shares when assets == 13
        vm.prank(user1);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.withdraw.selector,
                abi.encode(13 ether, user1, user1)
            )
        );
    }

    // Test that normal withdraw works fine (non-13 values)
    function test_normalWithdraw_WorksFine() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626NormalWithdrawTest";

        // Setup: user1 has shares to withdraw
        vm.prank(user1);
        vault.deposit(200 ether, user1);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Normal withdraw with value != 13 should work fine
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

    // Test Bug 4: Buggy redeem function that gives extra assets (only when shares == 13)
    function test_buggyRedeem_TriggersAssertion() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626RedeemBugTest";

        // Setup: user1 has shares to redeem using normal deposit
        vm.prank(user1);
        vault.deposit(100 ether, user1);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Trigger the buggy redeem with value 13 - this should cause assertion to fail
        // The redeem function gives 15% more assets when shares == 13
        vm.prank(user1);
        vm.expectRevert("Assertions Reverted");
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.redeem.selector,
                abi.encode(13 ether, user1, user1)
            )
        );
    }

    // Test that normal redeem works fine (non-13 values)
    function test_normalRedeem_WorksFine() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626NormalRedeemTest";

        // Setup: user1 has shares to redeem
        vm.prank(user1);
        vault.deposit(200 ether, user1);

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Normal redeem with value != 13 should work fine
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(
                vault.redeem.selector,
                abi.encode(50 ether, user1, user1)
            )
        );
    }

    // Test edge case: zero amounts
    function test_buggyOperationsWithZeroAmounts() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626ZeroBugTest";

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Even zero amount operations might trigger bugs due to rounding
        vm.prank(user1);
        cl.validate(
            label,
            vaultAddress,
            0,
            abi.encodePacked(vault.deposit.selector, abi.encode(0, user1))
        );
    }

    // Helper function to check vault state for debugging
    function _logVaultState() internal view {
        console.log("=== Vault State ===");
        console.log("Total Assets:", vault.totalAssets());
        console.log("Total Supply:", vault.totalSupply());
        console.log("Token Balance:", mockToken.balanceOf(address(vault)));
        console.log("User1 Shares:", vault.balanceOf(user1));
        console.log("User2 Shares:", vault.balanceOf(user2));
        console.log("==================");
    }

    // Test batching multiple ERC4626 operations in one transaction
    function test_batchedOperations_TriggersAssertion() public {
        address vaultAddress = address(vault);
        string memory label = "ERC4626BatchOperationsTest";

        cl.addAssertion(
            label,
            vaultAddress,
            type(ERC4626OperationsAssertion).creationCode,
            abi.encode(vault)
        );

        // Create a batch operator that will make multiple operations
        BatchOperations batchOperator = new BatchOperations(
            address(vault),
            address(mockToken)
        );

        vm.prank(user1);
        // Setup the batch operator with tokens and approvals
        _setupUser(address(batchOperator), 2000 ether);

        // Execute the batch operations - this should trigger assertion failures
        // because some operations use the buggy value of 13
        vm.expectRevert("Assertions Reverted");
        vm.prank(user1);
        cl.validate(
            label,
            address(batchOperator),
            0,
            new bytes(0) // Empty calldata triggers fallback
        );
    }

    // // Test batching normal operations (no bugs triggered)
    // function test_batchedNormalOperations_WorksFine() public {
    //     address vaultAddress = address(vault);
    //     string memory label = "ERC4626BatchNormalOperationsTest";

    //     cl.addAssertion(
    //         label,
    //         vaultAddress,
    //         type(ERC4626OperationsAssertion).creationCode,
    //         abi.encode(vault)
    //     );

    //     // Create a batch operator for normal operations
    //     BatchNormalOperations batchNormalOperator = new BatchNormalOperations(
    //         address(vault),
    //         address(mockToken)
    //     );

    //     vm.prank(user1);
    //     // Setup the batch operator with tokens and approvals
    //     _setupUser(address(batchNormalOperator), 2000 ether);

    //     // Execute the batch operations - this should work fine since no buggy values are used
    //     vm.prank(user1);
    //     cl.validate(
    //         label,
    //         address(batchNormalOperator),
    //         0,
    //         new bytes(0) // Empty calldata triggers fallback
    //     );
    // }
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
