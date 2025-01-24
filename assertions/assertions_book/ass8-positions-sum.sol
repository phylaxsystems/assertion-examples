// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

// !!! This assertion is not working currently, as the pre-compile needed is not yet implemented

// We use Morpho as an example, but this could be any lending protocol
interface IMorpho {
    function totalSupply() external view returns (uint256);
}

// Assert that the sum of all positions is the same as the total supply reported by the protocol
contract PositionSumAssertion is Assertion {
    IMorpho morpho = IMorpho(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1);
        assertions[0] = this.assertionPositionsSum.selector;
    }

    // Compare the sum of all positions to the total supply reported by the protocol
    function assertionPositionsSum() external {
        ph.forkPostState();
        uint256[] memory assets = ph.iterator().assets; // TODO: Assuming there is a cheatcode that allows to iterate
        uint256 allSupplyPositionsSum = 0;
        for (uint256 i = 0; i < assets.length; i++) {
            allSupplyPositionsSum += assets[i];
        }
        require(allSupplyPositionsSum == morpho.totalSupply(), "Positions sum does not match total supply");
    }
}
