// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@rari-capital/solmate/src/tokens/ERC721.sol";

// Lever V1 Lever Pool Sythetic
contract LeverV1ERC721 is ERC721 {
  address public pool;
  address public original;

  event Mint(address indexed account, uint256 tokenId);

  event Burn(uint256 tokenId);

  modifier onlyOwner() {
    require(msg.sender == pool, "LeverV1LPS: not owner");
    _;
  }

  constructor(
    string memory name,
    string memory symbol,
    address _pool,
    address _original
  ) ERC721(name, symbol) {
    pool = _pool;
    original = _original;
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

  // forward
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    return ERC721(original).tokenURI(tokenId);
  }

  function transferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual override {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 id
  ) public virtual override {}

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    bytes memory data
  ) public virtual override {}
}
