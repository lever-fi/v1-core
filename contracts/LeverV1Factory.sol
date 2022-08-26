// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { LeverV1Pool } from "./LeverV1Pool.sol";

/// @notice Deploys and manages Lever V1 pools
contract LeverV1Factory {
  error DuplicatePool();
  error Unauthorized();

  mapping(address => bool) private _collectionRegistry;
  mapping(address => bool) private _poolRegistry;
  mapping(address => address) private _collectionPoolTable;

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
    if (msg.sender != owner) {
      revert Unauthorized();
    }
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
    if (_collectionRegistry[originalCollection]) {
      revert DuplicatePool();
    }

    _collectionRegistry[originalCollection] = true;

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

    _poolRegistry[pool] = true;
    _collectionPoolTable[originalCollection] = pool;

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

  function collectionExists(address collection) external view returns (bool) {
    return _collectionRegistry[collection];
  }

  function isValidPool(address pool) external view returns (bool) {
    return _poolRegistry[pool];
  }
}
