// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IMarketplace {
  function getListing(uint256 tokenId) external;

  function list(uint256 tokenId, uint256 value) external;

  function purchase(uint256 tokenId) external payable;

  function sell(uint256 tokenId, uint256 value) external;
}
