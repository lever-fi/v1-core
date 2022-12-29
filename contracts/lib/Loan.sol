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

  struct Charge {
    address owner;
    uint256 tokenId;
  }

  // get daily interest rate from interest rate
  function getDailyInterestRate(uint256 x) internal pure returns (uint256 y) {
    y = x / 365;
  }

  // get interest from principal x and rate y
  function getInterest(uint256 x, uint256 y) internal pure returns (uint256 z) {
    z = (x * y) / 1 ether;
  }

  function initialize(
    Info storage self,
    bool active,
    address borrower,
    uint256 expirationTimestamp,
    uint256 loanTerm,
    uint256 principal,
    uint256 interest,
    uint256 interestRate,
    uint256 chargeInterval,
    uint256 lastCharge,
    uint256 paymentFrequency,
    uint256 repaymentAllowance,
    uint256 collateral,
    uint8 numInstallments
  ) internal {
    self.active = active;
    self.borrower = borrower;
    self.expirationTimestamp = expirationTimestamp;
    self.loanTerm = loanTerm;
    self.principal = principal;
    self.interest = interest;
    self.interestRate = interestRate;
    self.chargeInterval = chargeInterval;
    self.lastCharge = lastCharge;
    self.paymentFrequency = paymentFrequency;
    self.repaymentAllowance = repaymentAllowance;
    self.collateral = collateral;

    for (uint256 i = 0; i < self.installments.length; i++) {
      delete self.installments[i];
    }

    for (uint256 i = 0; i < numInstallments; i++) {
      self.installments.push(
        Installment.Info(
          principal / numInstallments,
          block.timestamp + ((i + 1) * paymentFrequency)
        )
      );
    }

    self.installmentsRemaining = numInstallments;
  }

  function applyInterest(
    Info memory self
  ) internal returns(uint256 interest) {
    interest = getInterest(self.principal, self.interestRate);
  }

  function get(
    mapping(bytes32 => Info) storage self,
    address owner,
    uint256 tokenId
  ) internal view returns (Info storage) {
    return self[keccak256(abi.encodePacked(owner, tokenId))];
  }

  function repay(Info storage self) internal {
    uint256 paymentDelta = msg.value;

    if (self.interest <= paymentDelta) {
      paymentDelta -= self.interest;
      self.interest = 0;
    } else {
      self.interest -= paymentDelta;
      paymentDelta = 0;
    }

    if (paymentDelta > self.principal) {
      revert("Loan: Repaying extra");
    }

    if (self.principal <= paymentDelta) {
      //paymentDelta = 0;
      //paymentDelta -= self.principal;
      self.principal = 0;
      self.installmentsRemaining = 0;
      
      for (uint8 index = 0; index < self.installments.length; index++) {
        delete self.installments[index];
      }
    } else {
      self.principal -= paymentDelta;

      while (paymentDelta > 0 && self.principal > 0) {
        (, uint8 index) = self.installments.whereSum();

        if (self.installments[index].amount > paymentDelta) {
          self.installments[index].amount -= paymentDelta;
          paymentDelta = 0;
        } else {
          paymentDelta -= self.installments[index].amount;
          self.installments[index].amount = 0;
          self.installmentsRemaining -= 1;
          delete self.installments[index];
        }
      }
    }
  }
}
