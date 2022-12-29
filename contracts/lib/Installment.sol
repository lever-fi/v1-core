// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

library Installment {
  struct Info {
    uint256 amount;
    uint256 dueBy;
  }

  function whereSum(Info[] memory self)
    internal
    pure
    returns (uint256 sum, uint8 index)
  {
    bool found = false;
    for (uint8 i = 0; i < self.length; i++) {
      if (self[i].amount > 0 && found == false) {
        found = true;
        index = i;
      }

      sum += self[i].amount;
    }
  }
}
