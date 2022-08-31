// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ILeverV1PoolEvents {
  enum LOAN_EVENT {
    ORIGINATE,
    LIQUIDATE,
    CLOSED
  }

  // event Create(
  //   address indexed originalCollection,
  //   uint256 collaterateCoverageRatio,
  //   uint256 interestRate,
  //   uint256 compoundInterval,
  //   uint256 burnRate,
  //   uint256 loanTerm,
  //   uint256 minLiquduity,
  //   uint256 minDeposit
  // );

  event Deposit(address indexed from, uint256 eth, uint256 tokens);

  event Collect(address indexed from, uint256 eth, uint256 tokens);

  event Borrow(address indexed from, uint256 value, uint256 tokenId);

  event LoanRepay(uint256 tokenId, uint256 value);

  event Liquidate(uint256 tokenId, uint256 value);

  event LoanEvent(uint256 tokenId, uint8 indexed _event);
}
