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
    address agentRouter,
    address assetManager,
    address token0
  ) external onlyOwner returns (address pool) {
    require(_collectionRegistry[token0] == false, "Collection is supported");

    _collectionRegistry[token0] = true;

    pool = address(
      new LeverV1Pool(
        agentRouter,
        assetManager,
        msg.sender,
        address(this),
        token0
      )
    );

    _poolRegistry[pool] = true;
    _collectionPoolTable[token0] = pool;

    /*
    token0,
    coverageRatio,
    interestRate,
    fee,
    chargeInterval,
    loanTerm,
    paymentFrequency,
    minDeposit,
    minLiquidity,
    */
    emit DeployPool(pool, assetManager);
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
