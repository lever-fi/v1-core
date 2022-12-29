// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ILeverV1Factory {
  error DuplicatePool();
  error Unauthorized();

  // address indexed token0,
  // uint256 coverageRatio,
  // uint256 interestRate,
  // uint256 fee,
  // uint256 chargeInterval,
  // uint256 loanTerm,
  // uint256 paymentFrequency,
  // uint256 minLiquidity,
  // uint256 minDeposit,

  event DeployPool(address indexed pool, address indexed assetManager);

  function collectionExists(address collection) external view returns (bool);

  function isValidPool(address pool) external view returns (bool);
}
