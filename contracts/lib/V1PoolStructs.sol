// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Marketplace } from "../interfaces/IPurchaseAgent.sol";

/**
 * @dev
 * ...
 */
struct Installment {
  uint256 amount;
  uint256 dueTimestamp;
}

/**
 * @dev
 * ...
 */
struct Loan {
  // hash
  // r s v
  // block timestamp of loan's last interest rate application
  uint256 lastCharge;
  // principal balance owed
  uint256 principal;
  // interest balance owed
  uint256 interest;
  // daily rate added to interest, taken from principal
  uint256 dailyPercentRate;
  // how often must a borrower pay off their loan
  uint256 paymentFrequency;
  // loan initator
  address borrower;
  // block timestamp at which loan was originated
  uint256 createdTimestamp;
  // block timestamp at which loan must be liquidated
  uint256 expirationTimestamp;
  // time between createdTimestamp and expirationTimestamp
  uint256 loanTerm;
  // time at which loan was finalized if at all
  uint256 finalizedTimestamp;
  // can actions be taken on this loan
  bool active;
  // subtract from here add to principal when compounded. Allowance given for auto-payments
  uint256 repaymentAllowance;
  // installments needed to pay off. Pop when an installment hits 0
  Installment[] installments;
  // how many installments are left. installmentsRemaining must be greater than or equal to len(installments) at all times
  uint256 installmentsRemaining;
  // given to cover underlying asset in case of poor collection performance
  uint256 collateral;
}

/**
 * @dev
 * ...
 */
struct BorrowAssetData {
  uint256 tokenId;
  uint256 price;
  Marketplace marketplace;
}
