// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// TODO: Import the contract / interface you want to assert
import {IAmm} from "../../lib/Amm.sol";
import {Assertion} from "../../lib/credible-std/Assertion.sol";

// TODO: Explain the assertion
contract AmmFeeVerificationAssertion is Assertion, IAmm {
    IAmm public amm = IAmm(0xbeef);

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1);
        assertions[0] = this.feeVerification.selector;
    }

    // TODO: Describe the assertion
    // return true indicates a valid state
    // return false indicates an invalid state
    function feeVerification() external returns (bool) {
        ph.forkPreState();
        uint256 preFee = amm.fee();
        ph.forkPostState();
        uint256 postFee = amm.fee();
        return preFee == postFee;
    }

    // function assertionAnotherExample() external returns (bool) {
    //     ph.forkPreState();
    //     address preOwner = example.admin();
    //     ph.forkPostState();
    //     address postOwner = example.admin();
    //     return preOwner == postOwner;
    // }
}
