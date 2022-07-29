// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";


/**
* @title Stacker Contract
* @author scaffold-eth
* @notice A contract that allow users to stack ETH
*/
contract Staker {

  
  ExampleExternalContract public exampleExternalContract;

  
  mapping(address => uint256) public balances;

  
  uint256 public constant threshold = 1 ether;

  
  uint256 public deadline = block.timestamp + 30 seconds;

  
  event Stake(address indexed sender, uint256 amount);

  
  /**
  * @notice Modifier that require the deadline to be reached or not
  * @param requireReached Check if the deadline has reached or not
  */
  modifier deadlineReached( bool requireReached ) {
    uint256 timeRemaining = timeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Deadline is already reached");
    }
    _;
  }

  /**
  * @notice Modifier that require the external contract to not be completed
  */
  modifier stakeNotCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "staking process already completed");
    _;
  }


  /**
  * @notice Contract Constructor
  * @param exampleExternalContractAddress Address of the external contract that will hold stacked funds
  */
  constructor(address exampleExternalContractAddress) {
    exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
  }

  function execute() public stakeNotCompleted deadlineReached(true) {
    uint256 contractBalance = address(this).balance;

    
    if(contractBalance >= threshold){
      (bool sent,) = address(exampleExternalContract).call{value: contractBalance}(abi.encodeWithSignature("complete()"));
      require(sent, "exampleExternalContract.complete failed");}

  }

  /**
  * @notice Stake method that update the user's balance
  */
  function stake() public payable deadlineReached(false) stakeNotCompleted {
    
    balances[msg.sender] += msg.value;

    
    emit Stake(msg.sender, msg.value);
  }

  /**
  * @notice Allow users to withdraw their balance from the contract only if deadline is reached but the stake is not completed
  */
  function withdraw() public deadlineReached(true) stakeNotCompleted {
    uint256 userBalance = balances[msg.sender];
    
    require(userBalance > 0, "You don't have balance to withdraw");
    
    balances[msg.sender] = 0;
    
    (bool sent,) = msg.sender.call{value: userBalance}("");
    require(sent, "Failed to send user balance back to the user");
  }

  /**
  * @notice The number of seconds remaining until the deadline is reached
  */
  function timeLeft() public view returns (uint256 timeleft) {
    if( block.timestamp >= deadline ) {
      return 0;
    } else {
      return deadline - block.timestamp;
    }
  }

}