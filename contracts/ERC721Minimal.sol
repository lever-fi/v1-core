// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IERC721Minimal} from "./interfaces/IERC721Minimal.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// only owner
contract ERC721Minimal is ERC721Enumerable {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function mint(address target, uint256 count) external {
        for (uint256 tokenId = 0; tokenId < count; tokenId++) {
            _mint(target, tokenId);
        }
    }
}
