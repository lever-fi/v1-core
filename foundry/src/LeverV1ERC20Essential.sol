// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IERC20Essential.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// only owner
contract LeverV1ERC20Essential is ERC20 {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {}

    function mintTo(address account, uint256 amount) external returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burnFrom(address account, uint256 amount) external returns (bool) {
        _burn(account, amount);
        return true;
    }
}
