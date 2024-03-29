// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC20Minimal {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function totalSupply() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  function mintTo(address account, uint256 amount) external returns (bool);

  function burnFrom(address account, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
