// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

// TODO: Import the contract / interface you want to assert
import {Assertion} from "../lib/credible-std/Assertion.sol";

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
    function assertionExample() external returns (bool) {
        ph.forkPostState();
        (address from, , , bytes memory data) = ph.getTransaction(); // TODO: Check if this works once we have the cheatcode
        bytes4 functionSelector = bytes4(data[:4]);
        if (functionSelector != vestraDAO.unStake.selector) {
            return true; // Skip the assertion if the function is not withdrawCollateral
        }
        uint8 maturity = abi.decode(data[4:], (uint8));
        IVestraDAO.Stake storage user = vestraDAO.stakes[from][maturity];
        return user.isActive;
    }
}
