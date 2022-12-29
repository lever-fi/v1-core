// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../lib/Loan.sol";

interface ILeverV1PoolOwnerActions {
  function pause() external;

  function charge(Loan.Charge[] calldata charges) external;

  function liquidate(bytes calldata assetData, bytes calldata agentData)
    external;

  function collapse() external;

  function approveExchange(address exchange, bool state) external;

  function setup(
    uint64 _coverageRatio,
    uint64 _interestRate,
    uint64 _fee,
    uint32 _chargeInterval,
    uint32 _loanTerm,
    uint32 _paymentFrequency,
    uint128 _minDeposit,
    uint256 _minLiquidity
  ) external;
}
