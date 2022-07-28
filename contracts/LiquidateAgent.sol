// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ILooksRareExchange} from "./integrations/LooksRare/interfaces/ILooksRareExchange.sol";
import {IExecutionStrategy} from "./integrations/LooksRare/interfaces/IExecutionStrategy.sol";
import {LooksRareOrderTypes} from "./integrations/LooksRare/libraries/LooksRareOrderTypes.sol";

import {IOpenSeaExchange} from "./integrations/OpenSea/interfaces/IOpenSeaExchange.sol";

import "hardhat/console.sol";

contract LiquidateAgent {
    address public constant OPENSEA_EXCHANGE =
        0x00000000006c3852cbEf3e08E8dF289169EdE581; //0x7f268357A8c2552623316e2562D90e642bB538E5;
    address public constant LOOKSRARE_EXCHANGE =
        0x1AA777972073Ff66DCFDeD85749bDD555C0665dA; //0x59728544B08AB483533076417FbBB2fD0B17CE3a;

    function looksrareLiquidate() private {}

    function openseaLiquidate() private {}

    function liquidate() external {}
}
