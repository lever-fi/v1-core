// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ILeverV1PoolErrors {
  error DeadLoan();
  error Unsuccessful();
  error InsufficientLiquidity();
  error InsufficientContribution();
  error Error_NotSuccessful();
  error Error_InsufficientBalance();
  error Error_InsufficientLiquidity();
  error Error_ExistingLoan();
  error Error_InsufficientContribution();
}
