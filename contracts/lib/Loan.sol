// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Installment.sol";

library Loan {
  using Installment for Installment.Info[];

  struct Info {
    bool active;
    address borrower;
    //uint256 createdTimestamp;
    // time by which loan must be paid off by
    uint256 expirationTimestamp;
    //uint256 finalizedTimestamp;
    // length of term in seconds
    uint256 loanTerm;
    // principal in ether to be paid by borrower
    uint256 principal;
    // interest in ether to be paid by borrower
    uint256 interest;
    // rate for interest calculation off principal
    uint256 interestRate;
    // frequency of interest charge in seconds
    uint256 chargeInterval;
    // last time interest was applied
    uint256 lastCharge;
    // frequency of payment in seconds
    uint256 paymentFrequency;
    // allows for interest and principal autopay
    uint256 repaymentAllowance;
    // eth tolerance before asset gets liquidated due to price action
    uint256 collateral;
    Installment.Info[] installments;
    uint8 installmentsRemaining;
  }

  // get daily interest rate from interest rate
  function getDailyInterestRate(uint256 x) internal pure returns (uint256 y) {
    y = x / 365;
  }

  // get interest from principal x and rate y
  function getInterest(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = (x * y) / 1 ether;
  }

  function get(
    mapping(bytes32 => Info) storage self,
    address owner,
    uint256 tokenId
  ) internal view returns (Loan.Info storage loan) {
    loan = self[keccak256(abi.encodePacked(owner, tokenId))];
  }

  function repay(Info storage self, uint256 paymentDelta) internal {
    Info memory _self = self;

    uint256 interest;
    if (_self.interest <= paymentDelta) {
      interest = 0;
      paymentDelta -= _self.interest;
    } else {
      interest = _self.interest - paymentDelta;
      paymentDelta = 0;
    }

    uint256 principal;
    uint8 installmentsRemaining = _self.installmentsRemaining;
    //Installment.Info[] memory installments = _self.installments;
    if (_self.principal <= paymentDelta) {
      principal = 0;
      installmentsRemaining = 0;
      paymentDelta -= _self.principal;
      for (uint8 index = 0; index < self.installments.length; index++) {
        delete self.installments[index];
      }
    } else {
      while (paymentDelta > 0 && principal > 0) {
        (, uint8 index) = self.installments.whereSum();

        principal -= self.installments[index].amount;
        if (self.installments[index].amount > paymentDelta) {
          self.installments[index].amount -= paymentDelta;
          paymentDelta = 0;
        } else {
          paymentDelta -= self.installments[index].amount;
          self.installments[index].amount = 0;
          installmentsRemaining -= 1;
          delete self.installments[index];
        }
      }
    }

    self.interest = interest;
    self.principal = principal;
    self.installmentsRemaining = installmentsRemaining;
    //self.installments = installments;
  }
}
