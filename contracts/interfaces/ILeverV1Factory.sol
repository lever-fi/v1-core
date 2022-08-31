// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ILeverV1Factory {
  error DuplicatePool();
  error Unauthorized();

  function collectionExists(address collection) external view returns (bool);

  function isValidPool(address pool) external view returns (bool);
}
