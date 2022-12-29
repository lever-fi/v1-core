/* 
Uint256, Address, Uint256, Uint256, Uint256, Uint256, Address, Bytes, Uint256, Bytes, [], Bytes32, Bytes32, Uint8, Uint8, [], Uint8, Uint256, Uint256, Uint256, Bytes32, Address, Bytes, Uint256, Uint256, Uint256, Uint256, Address, [], [], Uint256, Uint256, Uint256, Uint256, Address, Bool, Bytes32, Bytes32, Uint8
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Agent.sol";

import "../integrations/X2Y2/interfaces/IX2Y2Exchange.sol";
import "../integrations/X2Y2/libraries/X2Y2MarketTypes.sol";

contract X2Y2Agent is Agent {
  using X2Y2MarketTypes for X2Y2MarketTypes.RunInput;

  address public constant EXCHANGE = 0x6d7812d41a08bc2a910b562d8b56411964a4ed88;

  constructor(uint8 _agentId) Agent(_agentId) {}

  function _purchase()
    private
    returns (
      //X2Y2MarketTypes.RunInput memory input,
      bool success
    )
  {
    // IX2Y2Exchange(EXCHANGE).run{
    //   value: msg.value
    // }(input);
    // success = true;
  }

  function purchase(bytes calldata data)
    external
    payable
    override
    returns (
      bool success,
      address collection,
      uint256 tokenId
    )
  {
    // X2Y2MarketTypes.RunInput memory runInput = abi.decode(
    //   data,
    //   (X2Y2MarketTypes.RunInput)
    // );

    // success = _purchase(runInput);

    // if (!success) {
    //   revert BadRequest();
    // }

    // collection = makerAsk.collection;
    // tokenId = makerAsk.tokenId;

    // emit Purchase(agentId, EXCHANGE, tokenId, makerAsk.price);
    success = false;
    collection = address(0);
    tokenId = 0;
  }
}
