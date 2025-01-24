// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol"; // Credible Layer precompiles
import {PhEvm} from "../../lib/credible-std/src/PhEvm.sol";

interface IERC4626 {
    function deposit(uint256 assets, address receiver) external returns (uint256);
    function previewDeposit(uint256 assets) external view returns (uint256);
    function totalAssets() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

// Make sure that deposit are correct
contract ERC4626DepositAssertion is Assertion {
    IERC4626 public erc4626 = IERC4626(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1);
        assertions[0] = this.assertionDeposit.selector;
    }

    // Make sure that the preview deposit is correct
    // return true indicates a valid state
    // return false indicates an invalid state
    function assertionDeposit() external {
        // Get the sender of the transaction and the calldata
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(erc4626), erc4626.deposit.selector); // TODO: Check if this works once we have the cheatcode
        // If there are no call inputs, return
        if (callInputs.length == 0) {
            return;
        }
        for (uint256 i = 0; i < callInputs.length; i++) {
            ph.forkPreState();
            bytes memory data = callInputs[i].input;
            (uint256 assets, address receiver) = abi.decode(stripSelector(data), (uint256, address));
            uint256 expectedShares = erc4626.previewDeposit(assets);
            uint256 preTotalAssets = erc4626.totalAssets();
            ph.forkPostState();
            uint256 postBalance = erc4626.balanceOf(receiver);
            uint256 postTotalAssets = erc4626.totalAssets();
            require(postBalance == expectedShares, "Deposit assertion failed");
            require(postTotalAssets == preTotalAssets + assets, "Total assets assertion failed");
        }
    }

    function stripSelector(bytes memory input) internal pure returns (bytes memory) {
        // Create a new bytes memory and copy everything after the selector
        bytes memory paramData = new bytes(32);
        for (uint256 i = 4; i < input.length; i++) {
            paramData[i - 4] = input[i];
        }
        return paramData;
    }
}
