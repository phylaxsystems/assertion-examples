// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {PhEvm} from "credible-std/PhEvm.sol";
import {Assertion} from "credible-std/Assertion.sol";

contract Protocol {
    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        balances[msg.sender] -= amount;
        balances[to] += amount;
    }

    function mint(address to, uint256 amount) public {
        balances[to] += amount;
    }
}

/// It is possible to get the inputs of all calls within a transaction and their respective
/// call data. The struct returned can be found here:
/// https://github.com/phylaxsystems/credible-std/blob/f4dfdfb8b0f160f7350dc343e65e41993478f33c/src/PhEvm.sol#L16-L39
/// Input data can often be used to assert the expected outcome of a function call.
/// Note: It is typical that there can be multiple state changing function calls in a single transaction.
/// The assertion should consider this.
/// Note: The returned array is ordered by the order of the calls in the transaction.
/// Currently, it is only possible to fetch call inputs for a specific function selector.
/// There is no ordering guarantee between call inputs of different function selectors.
contract FunctionCallInputsAssertion is Assertion {
    mapping(address => int256) public balanceChanges;
    address[] changedAddresses;

    function triggers() public view override {
        registerCallTrigger(this.assertionFunctionCallInputs.selector);
    }

    function assertionFunctionCallInputs() public {
        Protocol protocol = Protocol(ph.getAssertionAdopter());
        PhEvm.CallInputs[] memory callInputs = ph.getCallInputs(address(protocol), protocol.transfer.selector);

        for (uint256 i = 0; i < callInputs.length; i++) {
            address from = callInputs[i].caller;
            (address to, uint256 amount) = abi.decode(callInputs[i].input, (address, uint256));
            // There is an edge case where the balanceChanges has gone back to 0
            // In this case, it would be duplicated in the changedAddresses array
            // Additional flags can remove duplicates
            if (balanceChanges[from] == 0) {
                changedAddresses.push(from);
            }
            if (balanceChanges[to] == 0) {
                changedAddresses.push(to);
            }
            balanceChanges[from] -= int256(amount);
            balanceChanges[to] += int256(amount);
        }

        uint256 preBalance;
        uint256 absDiff;

        for (uint256 i = 0; i < changedAddresses.length; i++) {
            ph.forkPreTx();
            preBalance = protocol.balances(changedAddresses[i]);
            ph.forkPostTx();

            if (balanceChanges[changedAddresses[i]] >= 0) {
                absDiff = uint256(balanceChanges[changedAddresses[i]]);
                require(protocol.balances(changedAddresses[i]) == preBalance + absDiff, "Balance change mismatch");
            } else {
                absDiff = uint256(balanceChanges[changedAddresses[i]] * -1);
                require(protocol.balances(changedAddresses[i]) == preBalance - absDiff, "Balance change mismatch");
            }
        }
    }
}
