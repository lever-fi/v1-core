// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IAgent {
  error BadRequest();

  event Purchase(
    uint8 indexed marketplace,
    address indexed location,
    uint256 tokenId,
    uint256 price
  );

  function purchase(address recipient, bytes calldata data)
    external
    payable
    returns (bool success);

  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
