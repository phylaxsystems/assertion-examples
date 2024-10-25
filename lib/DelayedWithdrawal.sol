pragma solidity ^0.8.17;

contract DelayedWithdrawal {
    address beneficiary;
    uint256 delay;
    uint256 lastDeposit;

    constructor(uint256 _delay) {
        beneficiary = msg.sender;
        lastDeposit = block.timestamp;
        delay = _delay;
    }

    modifier checkDelay() {
        require(block.timestamp >= lastDeposit + delay, "Keep waiting");
        _;
    }

    function deposit() public payable {
        require(msg.value != 0);
        lastDeposit = block.timestamp;
    }

    function withdraw() public checkDelay {
        (bool success, ) = beneficiary.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
}