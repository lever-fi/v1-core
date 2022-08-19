// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "hardhat/console.sol";

contract Marketplace {
  mapping(uint256 => uint256) public listings;
  address public immutable collection;

  // constructor
  constructor(address _collection) {
    collection = _collection;
  }

  // list
  function list(uint256 tokenId, uint256 value) external {
    listings[tokenId] = value;
  }

  // purchase
  function purchase(uint256 tokenId) external payable {
    IERC721 _collection = IERC721(collection);
    require(listings[tokenId] == msg.value);
    _collection.transferFrom(address(this), msg.sender, tokenId);
  }

  // sell
  function sell(uint256 tokenId, uint256 value) external {
    IERC721 _collection = IERC721(collection);
    _collection.transferFrom(msg.sender, address(this), tokenId);
    payable(msg.sender).transfer(value);
  }

  function getListing(uint256 tokenId) public view returns (uint256) {
    return listings[tokenId];
  }

  receive() external payable {}
}
