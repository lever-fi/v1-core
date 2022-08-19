// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721Minimal {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function setApprovalForAll(address operator, bool _approved) external;

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
