// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Agent.sol";

import "../integrations/LooksRare/interfaces/ILooksRareExchange.sol";

contract LooksRareAgent is Agent {
  using LooksRareOrderTypes for LooksRareOrderTypes.MakerOrder;
  using LooksRareOrderTypes for LooksRareOrderTypes.TakerOrder;

  address public constant EXCHANGE = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;

  constructor(uint8 _agentId, address router) Agent(_agentId, router) {}

  function _purchase(
    address recipient,
    LooksRareOrderTypes.TakerOrder memory takerBid,
    LooksRareOrderTypes.MakerOrder memory makerAsk
  ) private returns (bool success) {
    ILooksRareExchange(EXCHANGE).matchAskWithTakerBidUsingETHAndWETH{
      value: msg.value
    }(takerBid, makerAsk);

    IERC721Minimal(makerAsk.collection).safeTransferFrom(
      address(this),
      recipient,
      makerAsk.tokenId
    );

    success = true;
  }

  function purchase(address recipient, bytes calldata data)
    external
    payable
    override
    returns (bool success)
  // address collection,
  // uint256 tokenId
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

    success = _purchase(recipient, takerBid, makerAsk);

    if (!success) {
      revert BadRequest();
    }

    // collection = makerAsk.collection;
    uint256 tokenId = makerAsk.tokenId;

    emit Purchase(agentId, EXCHANGE, makerAsk.tokenId, makerAsk.price);
  }

  function setApprovalForAll(
    address operator,
    address collection,
    bool state
  ) external onlyOwner {
    IERC721Minimal(collection).setApprovalForAll(EXCHANGE, state);
  }
}
