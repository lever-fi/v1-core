// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import {IERC721Minimal} from "./interfaces/IERC721Minimal.sol";

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// only owner
contract ERC721Minimal is ERC721Enumerable {
  using Address for address;
  using Strings for uint256;

  string public baseURI;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _baseURI
  ) ERC721(_name, _symbol) {
    baseURI = _baseURI;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  function mint(address target, uint256 count) external {
    uint256 currentSupply = totalSupply();
    for (
      uint256 tokenId = currentSupply;
      tokenId < currentSupply + count;
      tokenId++
    ) {
      _mint(target, tokenId);
    }
  }
}
