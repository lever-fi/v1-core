// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract LeverV1ERC721L is ERC721 {
    address public pool;

    event Mint(address indexed account, uint256 tokenId);

    event Burn(uint256 tokenId);

    modifier onlyOwner() {
        require(msg.sender == pool, "LeverV1ERC721L: not owner");
        _;
    }

    constructor(
        string memory name,
        string memory symbol,
        address _pool
    ) ERC721(name, symbol) {
        pool = _pool;
    }

    function mint(address account, uint256 tokenId)
        public
        onlyOwner
        returns (bool)
    {
        _mint(account, tokenId);

        emit Mint(account, tokenId);

        return true;
    }

    function burn(uint256 tokenId) public onlyOwner returns (bool) {
        _burn(tokenId);

        emit Burn(tokenId);

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {}

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {}

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {}
}
