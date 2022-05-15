// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/IERC721Minimal.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// only owner
contract ERC721Minimal is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}
}
