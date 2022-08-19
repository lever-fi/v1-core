// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { LeverV1Pool } from "./LeverV1Pool.sol";

/// @notice Deploys and manages Lever V1 pools
contract LeverV1Factory {
  mapping(address => bool) private _poolRegistry;
  address public owner;
  event DeployPool(
    address indexed pool,
    address indexed originalCollection,
    uint256 collateralCoverageRatio,
    uint256 interestRate,
    uint256 chargeInterval,
    uint256 burnRate,
    uint256 loanTerm,
    uint256 minLiquidity,
    uint256 minDeposit,
    uint256 paymentFrequency
  );

  constructor() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "LeverV1Factory: Sender is not owner");
    _;
  }

  function deployPool(
    address originalCollection,
    uint256 collateralCoverageRatio,
    uint256 interestRate,
    uint256 chargeInterval,
    uint256 burnRate,
    uint256 loanTerm,
    uint256 minLiquidity,
    uint256 minDeposit,
    uint256 paymentFrequency
  ) external onlyOwner returns (address pool) {
    require(
      _poolRegistry[originalCollection] == false,
      "PoolFactory: Pool is already registered"
    );
    _poolRegistry[originalCollection] = true;

    pool = address(
      new LeverV1Pool(
        address(this),
        originalCollection,
        collateralCoverageRatio,
        interestRate,
        chargeInterval,
        burnRate,
        loanTerm,
        minLiquidity,
        minDeposit,
        paymentFrequency,
        msg.sender
      )
    );

    emit DeployPool(
      pool,
      originalCollection,
      collateralCoverageRatio,
      interestRate,
      chargeInterval,
      burnRate,
      loanTerm,
      minLiquidity,
      minDeposit,
      paymentFrequency
    );
  }

  function setOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function poolExists(address collection) external view returns (bool) {
    return _poolRegistry[collection];
  }
}
