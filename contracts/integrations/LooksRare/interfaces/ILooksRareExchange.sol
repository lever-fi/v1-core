// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LooksRareOrderTypes} from "../libraries/LooksRareOrderTypes.sol";

interface ILooksRareExchange {
    function matchAskWithTakerBidUsingETHAndWETH(
        LooksRareOrderTypes.TakerOrder calldata takerBid,
        LooksRareOrderTypes.MakerOrder calldata makerAsk
    ) external payable;

    function matchAskWithTakerBid(
        LooksRareOrderTypes.TakerOrder calldata takerBid,
        LooksRareOrderTypes.MakerOrder calldata makerAsk
    ) external;

    function matchBidWithTakerAsk(
        LooksRareOrderTypes.TakerOrder calldata takerAsk,
        LooksRareOrderTypes.MakerOrder calldata makerBid
    ) external;
}
