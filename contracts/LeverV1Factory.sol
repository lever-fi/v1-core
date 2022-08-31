// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./LeverV1Pool.sol";

import "./interfaces/ILeverV1Factory.sol";

/// @notice Deploys and manages Lever V1 pools
contract LeverV1Factory is ILeverV1Factory {
  mapping(address => bool) private _collectionRegistry;
  mapping(address => bool) private _poolRegistry;
  mapping(address => address) private _collectionPoolTable;

  address public owner;
  event DeployPool(
    address indexed pool,
    address indexed token0,
    uint256 coverageRatio,
    uint256 interestRate,
    uint256 fee,
    uint256 chargeInterval,
    uint256 loanTerm,
    uint256 paymentFrequency,
    uint256 minLiquidity,
    uint256 minDeposit,
    address indexed assetManager
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
    address token0,
    uint64 coverageRatio,
    uint64 interestRate,
    uint64 fee,
    uint32 chargeInterval,
    uint32 loanTerm,
    uint32 paymentFrequency,
    uint128 minDeposit,
    uint256 minLiquidity,
    address agentRouter,
    address assetManager
  ) external onlyOwner returns (address pool) {
    require(_collectionRegistry[token0] == false, "Collection is supported");

    _collectionRegistry[token0] = true;

    pool = address(
      new LeverV1Pool(
        address(this),
        token0,
        coverageRatio,
        interestRate,
        fee,
        chargeInterval,
        loanTerm,
        paymentFrequency,
        minDeposit,
        minLiquidity,
        agentRouter,
        assetManager
      )
    );

    _poolRegistry[pool] = true;
    _collectionPoolTable[token0] = pool;

    emit DeployPool(
      pool,
      token0,
      coverageRatio,
      interestRate,
      fee,
      chargeInterval,
      loanTerm,
      paymentFrequency,
      minDeposit,
      minLiquidity,
      assetManager
    );
  }

  function setOwner(address newOwner) external onlyOwner {
    owner = newOwner;
  }

  function collectionExists(address collection)
    external
    view
    override
    returns (bool)
  {
    return _collectionRegistry[collection];
  }

  function isValidPool(address pool) external view override returns (bool) {
    return _poolRegistry[pool];
  }
}
