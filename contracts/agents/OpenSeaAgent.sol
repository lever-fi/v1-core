// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Agent.sol";

import "../integrations/OpenSea/interfaces/IOpenSeaExchange.sol";

contract OpenSeaAgent is Agent {
  // using OpenSeaOrderTypes for OpenSeaOrderTypes.BasicOrderParameters;
  // using OpenSeaOrderTypes for OpenSeaOrderTypes.Advanced
  event Seaport(OpenSeaOrderTypes.BasicOrderParameters params);
  event sigs(bytes4 sig1, bytes4 sig2);
  event Status(bool a, bool b, uint256 c, uint256 d);

  address public constant EXCHANGE = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

  constructor(uint8 _agentId, address router) Agent(_agentId, router) {
    emit sigs(this.isValidSignature.selector, bytes4(0));
  }

  // function _purchase(
  //   address recipient,
  //   OpenSeaOrderTypes.AdvancedOrder memory advancedOrder,
  //   OpenSeaOrderTypes.CriteriaResolver[] memory criteriaResolvers,
  //   bytes32 fulfillerConduitKey
  // ) private returns (bool success) {
  //   success = IOpenSeaExchange(EXCHANGE).fulfillAdvancedOrder{
  //     value: msg.value
  //   }(advancedOrder, criteriaResolvers, fulfillerConduitKey, recipient);
  // }

  // function purchase(address recipient, bytes calldata data)
  //   external
  //   payable
  //   override
  //   returns (bool success)
  // {
  //   (
  //     OpenSeaOrderTypes.AdvancedOrder memory advancedOrder,
  //     OpenSeaOrderTypes.CriteriaResolver[] memory criteriaResolvers,
  //     bytes32 fulfillerConduitKey,
  //     uint256 price
  //   ) = abi.decode(data, (OpenSeaOrderTypes.AdvancedOrder, OpenSeaOrderTypes.CriteriaResolver[], bytes32, uint256));

  //   success = _purchase(
  //     recipient,
  //     advancedOrder,
  //     criteriaResolvers,
  //     fulfillerConduitKey
  //   );

  //   if (!success) {
  //     revert BadRequest();
  //   }

  //   // collection = parameters.offerToken;
  //   uint256 tokenId = advancedOrder.parameters.offer[0].identifierOrCriteria;

  //   emit Purchase(agentId, EXCHANGE, tokenId, price);
  // }

  function _purchase(
    address recipient,
    OpenSeaOrderTypes.BasicOrderParameters memory parameters
  ) private returns (bool success) {
    IOpenSeaExchange(EXCHANGE).fulfillBasicOrder{ value: msg.value }(
      parameters
    );

    IERC721Minimal(parameters.offerToken).safeTransferFrom(
      address(this),
      recipient,
      parameters.offerIdentifier
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
    // (bool a, bool b, uint256 c, uint256 d) = IOpenSeaExchange(EXCHANGE)
    //   .getOrderStatus(
    //     0x8c34c6ab19d1939a39a475e926c48964f8030893c41b4c7997e33acec842e2c4
    //   );
    // emit Status(a, b, c, d);

    (
      OpenSeaOrderTypes.BasicOrderParameters memory parameters,
      uint256 price
    ) = abi.decode(data, (OpenSeaOrderTypes.BasicOrderParameters, uint256));

    success = _purchase(recipient, parameters);

    if (!success) {
      revert BadRequest();
    }

    // collection = parameters.offerToken;
    uint256 tokenId = parameters.offerIdentifier;

    emit Purchase(agentId, EXCHANGE, tokenId, price);
  }

  function setApprovalForAll(
    address operator,
    address collection,
    bool state
  ) external onlyOwner {
    IERC721Minimal(collection).setApprovalForAll(EXCHANGE, state);
  }
}

/* (params: (
  0x0000000000000000000000000000000000000000, 
  0, 
  3, 
  0x736b78bd08095461b1de06f4eec5b505e5c5f96f, 
  0x004c00500000ad104d7dbd00e3ae0a5c00560c00, 
  0xbc4ca0eda7647a8ab7c2061c2e118a18a936f13d, 
  3596, 
  1, 
  2, 
  1662360034, 
  1662619234, 
  0x0000000000000000000000000000000000000000000000000000000000000000, 
  99961984364471261, 
  0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000, 
  0x0000000000000000000000000000000000000000000000000000000000000000, 
  3, 
  [
    (75810000000000000000, 0x736b78bd08095461b1de06f4eec5b505e5c5f96f), 
    (1995000000000000000, 0x0000a26b00c1f0df003000390027140000faa719), 
    (1995000000000000000, 0xa858ddc0445d8131dac4d1de01f834ffcba52ef1)
  ], 
  0x2dc0f4e898da0c034f79a83be300d1b2ed0b4573d340e17a529ec10bb998725406cb247cc2eeca40d30d038e6af8f9b47d09d16b5cf887869de34b138df39c7d1c)
  ) */
