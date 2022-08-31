// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ILeverV1PoolOwnerActions {
  function pause() external;

  function charge() external;

  function liquidate(bytes calldata assetData, bytes calldata agentData)
    external;

  function collapse() external;
}
