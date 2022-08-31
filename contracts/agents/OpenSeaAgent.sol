// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Agent.sol";

import "../integrations/OpenSea/interfaces/IOpenSeaExchange.sol";
import "../integrations/OpenSea/libraries/OpenSeaOrderTypes.sol";

contract OpenSeaAgent is Agent {
  using OpenSeaOrderTypes for OpenSeaOrderTypes.BasicOrderParameters;

  address public constant MARKETPLACE =
    0x00000000006c3852cbEf3e08E8dF289169EdE581;

  function _purchase(
    OpenSeaOrderTypes.BasicOrderParameters memory parameters,
    uint256 price
  ) private returns (bool) {
    // ILooksRareExchange(LOOKSRARE_EXCHANGE).matchAskWithTakerBidUsingETHAndWETH{
    //   value: makerAsk.price
    // }(takerBid, makerAsk);

    (bool success, bytes memory result) = OPENSEA_EXCHANGE.delegatecall(
      abi.encodeWithSignature(
        "fulfillBasicOrder(OpenSeaOrderTypes.BasicOrderParameters)",
        parameters
      )
    );

    //return success;
    emit Purchase(
      Marketplace.OPENSEA,
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
    (
        OpenSeaOrderTypes.BasicOrderParameters memory parameters,
        uint256 price
      ) = abi.decode(_data, (OpenSeaOrderTypes.BasicOrderParameters, uint256));

    _success = _purchase(parameters, price);
  }
}
