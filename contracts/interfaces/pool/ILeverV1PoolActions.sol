// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ILeverV1PoolActions {
  function deposit() external payable;

  function collect(uint256 amount) external;

  function borrow(bytes calldata assetData, bytes calldata purchaseData)
    external
    payable;

  function repay(uint256 tokenId) external payable;

  //function batchRepay(bytes[] calldata data) external payable;
}
