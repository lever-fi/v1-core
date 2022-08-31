// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Agent.sol";

import "../integrations/LooksRare/interfaces/ILooksRareExchange.sol";
import "../integrations/LooksRare/interfaces/IExecutionStrategy.sol";
import "../integrations/LooksRare/libraries/LooksRareOrderTypes.sol";

contract LooksRareAgent is Agent {
  using LooksRareOrderTypes for LooksRareOrderTypes.MakerOrder;
  using LooksRareOrderTypes for LooksRareOrderTypes.TakerOrder;

  address public constant MARKETPLACE =
    0x59728544B08AB483533076417FbBB2fD0B17CE3a;

  function _purchase(
    LooksRareOrderTypes.TakerOrder memory takerBid,
    LooksRareOrderTypes.MakerOrder memory makerAsk
  ) private returns (bool) {
    // ILooksRareExchange(LOOKSRARE_EXCHANGE).matchAskWithTakerBidUsingETHAndWETH{
    //   value: makerAsk.price
    // }(takerBid, makerAsk);

    (bool success, bytes memory result) = LOOKSRARE_EXCHANGE.delegatecall(
      abi.encodeWithSignature(
        "matchAskWithTakerBidUsingETHAndWETH(LooksRareOrderTypes.TakerOrder,LooksRareOrderTypes.MakerOrer)",
        takerBid,
        makerAsk
      )
    );

    //return success;
    emit Purchase(
      Marketplace.LOOKSRARE,
      LOOKSRARE_EXCHANGE,
      makerAsk.tokenId,
      makerAsk.price
    );

    return success;
    // 205-210
  }

  function purchase(bytes calldata data)
    external
    payable
    override
    returns (bool)
  {
    LooksRareOrderTypes.MakerOrder memory makerAsk = abi.decode(
      data,
      (LooksRareOrderTypes.MakerOrder)
    );

    LooksRareOrderTypes.TakerOrder memory takerBid = LooksRareOrderTypes
      .TakerOrder({
        isOrderAsk: false,
        taker: address(this),
        price: makerAsk.price,
        tokenId: makerAsk.tokenId,
        minPercentageToAsk: makerAsk.minPercentageToAsk,
        params: makerAsk.params
      });

    _success = _purchase(takerBid, makerAsk);
  }
}
