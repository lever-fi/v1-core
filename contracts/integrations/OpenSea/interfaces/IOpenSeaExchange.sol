// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OpenSeaOrderTypes} from "../libraries/OpenSeaOrderTypes.sol";

interface IOpenSeaExchange {
    function fulfillBasicOrder(
        OpenSeaOrderTypes.BasicOrderParameters calldata parameters
    ) external payable returns (bool fulfilled);
}
