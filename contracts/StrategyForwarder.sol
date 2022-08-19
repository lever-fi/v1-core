// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// installments
//

contract StrategyForwarder {
  mapping(uint256 => address) public strategies;

  uint256 strategyCounter = 0;

  function addStrategy(address location) external {
    strategies[strategyCounter] = location;
    strategyCounter += 1;
  }

  function removeStrategy(uint256 strategy) external {
    strategies[strategy] = address(0);
  }
}
