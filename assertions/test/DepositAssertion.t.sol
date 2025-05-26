// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CoolVault} from "../../src/CoolVault.sol";
import {CredibleTest} from "credible-std/CredibleTest.sol";
import {Test} from "forge-std/Test.sol";
import {MockToken} from "../../src/MockToken.sol";
import {DepositAssertion} from "../src/Deposit.a.sol";

contract TestDepositAssertion is CredibleTest, Test {
    // Contract state variables
    CoolVault public assertionAdopter;
    address public initialOwner = address(0xdead);
    address public newOwner = address(0xdeadbeef);

    // Set up the test environment
    function setUp() public {
        vm.startPrank(initialOwner);
        MockToken mockToken = new MockToken("MockToken", "MTK", 18);
        assertionAdopter = new CoolVault(mockToken, "CoolVault", "cvTOKEN");
        mockToken.approve(address(assertionAdopter), 100 ether);
        mockToken.mint(initialOwner, 100 ether);
        vm.stopPrank();
        vm.deal(initialOwner, 1 ether);
    }

    // Test case: Ownership changes should trigger the assertion
    function test_assertionDepositIncreasesBalance() public {
        address aaAddress = address(assertionAdopter);
        string memory label = "DepositBalanceAssertion";

        // Associate the assertion with the protocol
        // cl will manage the correct assertion execution when the protocol is called
        cl.addAssertion(
            label,
            aaAddress,
            type(DepositAssertion).creationCode,
            abi.encode(assertionAdopter)
        );

        // Simulate a transaction that changes ownership
        vm.prank(initialOwner);
        cl.validate(
            label,
            aaAddress,
            0,
            abi.encodePacked(
                assertionAdopter.deposit.selector,
                abi.encode(0.1 ether, initialOwner)
            )
        );
    }
}
