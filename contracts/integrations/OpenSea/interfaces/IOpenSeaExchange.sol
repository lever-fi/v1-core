// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../libraries/OpenSeaOrderTypes.sol";

interface IOpenSeaExchange {
  function fulfillBasicOrder(
    OpenSeaOrderTypes.BasicOrderParameters calldata parameters
  ) external payable returns (bool fulfilled);

  function fulfillAdvancedOrder(
    OpenSeaOrderTypes.AdvancedOrder calldata advancedOrder,
    OpenSeaOrderTypes.CriteriaResolver[] calldata criteriaResolvers,
    bytes32 fulfillerConduitKey,
    address recipient
  ) external payable returns (bool fulfilled);

  function getOrderStatus(bytes32 orderHash)
    external
    view
    returns (
      bool isValidated,
      bool isCancelled,
      uint256 totalFilled,
      uint256 totalSize
    );
}
