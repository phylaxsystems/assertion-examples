// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Assertion} from "../lib/credible-std/src/Assertion.sol";
import {PhEvm} from "../lib/credible-std/src/PhEvm.sol";

interface IVestraDAO {
    struct Stake {
        uint64 startTime;
        uint256 stakeAmount;
        uint256 yield;
        uint256 penalty;
        uint64 endTime;
        bool isActive;
    }

    mapping(address => mapping(uint8 => Stake)) public stakes;

    function unStake(uint8 maturity) external;
}

// Assert that the user has already unstaked for a maturity
contract VestraDAOHack is Assertion {
    IVestraDAO public vestraDAO = IVestraDAO(address(0xbeef));

    function fnSelectors() external pure override returns (bytes4[] memory assertions) {
        assertions = new bytes4[](1); // Define the number of triggers
        assertions[0] = this.assertionExample.selector; // Define the trigger
        return assertions;
    }

    // Check if the user has already unstaked for a maturity
    // return true indicates a valid state
    // return false indicates an invalid state
    function assertionExample() external {
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(vestraDAO), vestraDAO.unStake.selector);
        if (callInputs.length == 0) {
            return;
        }

        for (uint256 i = 0; i < callInputs.length; i++) {
            bytes memory data = callInputs[i].input;
            address from = callInputs[i].caller;
            uint8 maturity = abi.decode(stripSelector(data), (uint8));
            IVestraDAO.Stake storage user = vestraDAO.stakes[from][maturity];
            require(!user.isActive, "User has already unstaked");
        }
    }

    function stripSelector(bytes memory input) internal pure returns (bytes memory) {
        bytes memory paramData = new bytes(32);
        for (uint256 i = 4; i < input.length; i++) {
            paramData[i - 4] = input[i];
        }
        return paramData;
    }
}
