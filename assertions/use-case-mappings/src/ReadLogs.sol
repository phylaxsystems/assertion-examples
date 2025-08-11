// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Assertion} from "credible-std/Assertion.sol";
import {PhEvm} from "credible-std/PhEvm.sol";

contract Protocol {
    event Transfer(address from, address to, uint256 amount);

    mapping(address => uint256) public balances;

    function transfer(address to, uint256 amount) public {
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function mint(address to, uint256 amount) public {
        balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}

/// It is possible to get the logs of all transactions within a transaction.
/// The struct returned can be found here:
/// https://github.com/phylaxsystems/credible-std/blob/f4dfdfb8b0f160f7350dc343e65e41993478f33c/src/PhEvm.sol#L6-L13
/// Log data can often be used to assert the expected outcome of state changes.
/// Note: It needs to be made sure that logs are emitted for every corresponding state change.
contract ReadLogsAssertion is Assertion {
    Protocol public protocol;

    constructor(Protocol protocol_) {
        protocol = protocol_;
    }

    function triggers() public view override {
        registerCallTrigger(this.assertionReadLogs.selector);
    }

    mapping(address => int256) public balanceChanges;
    address[] changedAddresses;

    function assertionReadLogs() public {
        PhEvm.Log[] memory logs = ph.getLogs();

        for (uint256 i = 0; i < logs.length; i++) {
            (address from, address to, uint256 amount) = abi.decode(logs[i].data, (address, address, uint256));
            // There is an edge case where the changedBalance has gone back to 0
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

            if (balanceChanges[changedAddresses[i]] > 0) {
                absDiff = uint256(balanceChanges[changedAddresses[i]]);
                require(protocol.balances(changedAddresses[i]) == preBalance + absDiff, "Balance change mismatch");
            } else {
                absDiff = uint256(balanceChanges[changedAddresses[i]] * -1);
                require(protocol.balances(changedAddresses[i]) == preBalance - absDiff, "Balance change mismatch");
            }
        }
    }
}
