// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAgent {
  event Purchase(
    uint8 indexed marketplace,
    address indexed location,
    uint256 tokenId,
    uint256 price
  );

  function purchase(bytes calldata data) external payable returns (bool);

  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
