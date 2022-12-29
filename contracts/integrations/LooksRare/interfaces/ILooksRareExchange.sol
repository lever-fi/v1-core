// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/LooksRareOrderTypes.sol";

interface ILooksRareExchange {
  function matchAskWithTakerBidUsingETHAndWETH(
    LooksRareOrderTypes.TakerOrder calldata takerBid,
    LooksRareOrderTypes.MakerOrder calldata makerAsk
  ) external payable;

  function matchAskWithTakerBid(
    LooksRareOrderTypes.TakerOrder calldata takerBid,
    LooksRareOrderTypes.MakerOrder calldata makerAsk
  ) external payable;

  function matchBidWithTakerAsk(
    LooksRareOrderTypes.TakerOrder calldata takerAsk,
    LooksRareOrderTypes.MakerOrder calldata makerBid
  ) external payable;
}
