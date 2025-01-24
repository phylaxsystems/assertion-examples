// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../../lib/credible-std/src/Assertion.sol";

// We assume Aerodrome style pool
interface IAmm {
    function getReserves() external view returns (uint256, uint256);

    function getK() external view returns (uint256);
}

contract ConstantProductAssertion is Assertion {
    IAmm public amm = IAmm(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1);
        assertions[0] = this.assertionConstantProduct.selector;
    }

    // Make sure that the product of the reserves is equal to the constant product
    // note: fees might have to be handled depending on the pool
    function assertionConstantProduct() external {
        ph.forkPostState(); // Fork the post state
        (uint256 reserve0, uint256 reserve1) = amm.getReserves();
        uint256 k = reserve0 * reserve1;
        require(k == amm.getK(), "Constant product does not hold");
    }
}
