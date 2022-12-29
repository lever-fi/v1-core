// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../lib/Loan.sol";

interface ILeverV1PoolState {
  /// @notice min ratio for which borrower must cover cost of asset
  function coverageRatio() external view returns (uint64);

  /// @notice interest rate that gets applied on loan principal
  function interestRate() external view returns (uint64);

  /// @notice rate in which interest repayments get sent to fee manager;
  function fee() external view returns (uint64);

  /// @notice time in seconds between interest rate charges
  function chargeInterval() external view returns (uint32);

  /// @notice duration in seconds for loan
  function loanTerm() external view returns (uint32);

  /// @notice how often payments are expected in seconds
  function paymentFrequency() external view returns (uint32);

  /// @notice interest accrued since last burn
  function interestAccrued() external view returns (uint128);

  /// @notice minimum eth required from borrower to deposit in pool
  function minDeposit() external view returns (uint128);

  /// @notice minimum amount of eth to be in pool in order for new loans
  /// to be initialized
  function minLiquidity() external view returns (uint256);

  /// @notice total value of pool, not balance (eth + loans)
  function truePoolValue() external view returns (uint256);

  /// @notice agent responsible for purchasing NFTs from marketplaces
  function agentRouter() external view returns (address);

  /// @notice automated EOA (listing manager, fund transfer)
  function assetManager() external view returns (address);

  // /// @notice returns loan info given key
  // function loans(bytes32 key)
  //   external
  //   view
  //   returns (Loan.Info memory);

  // /// @notice tokenid mapped to loan state
  // function book(uint256 id) external view returns (bool);

  /// @notice keccak owner and tokenId mapped to loan
  // function loans(bytes32 id) external view returns (
  //   bool active,
  //   address borrower,
  //   uint256 expirationTimestamp,
  //   uint256 loanTerm,
  //   uint256 principal,
  //   uint256 interest,
  //   uint256 interestRate,
  //   uint256 chargeInterval,
  //   uint256 lastCharge,
  //   uint256 paymentFrequency,
  //   uint256 repaymentAllowance,
  //   uint256 collateral,
  //   Installment.Info[] memory installments,
  //   uint8 installmentsRemaining
  // );
}

/* 
tuple(bool,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint8)
tuple(bool,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,struct Installment.Info memory[] memory,uint8)

 */
