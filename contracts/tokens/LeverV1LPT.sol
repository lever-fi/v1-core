// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Lever V1 Lever Pool Token
contract LeverV1LPT is ERC20 {
    address public pool;

    event Mint(address indexed account, uint256 amount);

    event Burn(address indexed account, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == pool, "LeverV1LPT: not owner");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        address _pool
    ) ERC20(_name, _symbol) {
        pool = _pool;
    }

    function mintTo(address account, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        _mint(account, amount);

        emit Mint(account, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount)
        external
        onlyOwner
        returns (bool)
    {
        _burn(account, amount);

        emit Burn(account, amount);
        return true;
    }
}
