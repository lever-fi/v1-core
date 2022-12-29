// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../../lib/Installment.sol";

interface ILeverV1PoolStructs {
  struct BorrowData {
    uint256 tokenId;
    uint256 price;
    uint8 agentId;
  }
}
