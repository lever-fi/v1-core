// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ILooksRareExchange} from "./integrations/LooksRare/interfaces/ILooksRareExchange.sol";
import {IExecutionStrategy} from "./integrations/LooksRare/interfaces/IExecutionStrategy.sol";
import {LooksRareOrderTypes} from "./integrations/LooksRare/libraries/LooksRareOrderTypes.sol";

import {IOpenSeaExchange} from "./integrations/OpenSea/interfaces/IOpenSeaExchange.sol";

import {IPurchaseAgent} from "./interfaces/IPurchaseAgent.sol";

import "hardhat/console.sol";

contract PurchaseAgent is IPurchaseAgent {
    using LooksRareOrderTypes for LooksRareOrderTypes.MakerOrder;
    using LooksRareOrderTypes for LooksRareOrderTypes.TakerOrder;

    address public constant OPENSEA_EXCHANGE =
        0x00000000006c3852cbEf3e08E8dF289169EdE581; //0x7f268357A8c2552623316e2562D90e642bB538E5;
    address public constant LOOKSRARE_EXCHANGE =
        0x1AA777972073Ff66DCFDeD85749bDD555C0665dA; //0x59728544B08AB483533076417FbBB2fD0B17CE3a;

    function looksrarePurchase(
        LooksRareOrderTypes.TakerOrder memory takerBid,
        LooksRareOrderTypes.MakerOrder memory makerAsk
    ) private returns (bool) {
        ILooksRareExchange(LOOKSRARE_EXCHANGE)
            .matchAskWithTakerBidUsingETHAndWETH{value: makerAsk.price}(
            takerBid,
            makerAsk
        );

        /* (bool success, bytes memory result) = LOOKSRARE_EXCHANGE.delegatecall(
            abi.encodeWithSignature(
                "matchAskWithTakerBidUsingETHAndWETH(LooksRareOrderTypes.TakerOrder,LooksRareOrderTypes.MakerOrer)",
                takerBid,
                makerAsk
            )
        ); */

        //return success;

        return true;
        // 205-210
    }

    function openseaPurchase(Order memory order, bytes32 fulfillerConduitKey)
        private
        returns (bool)
    {
        bool fulfilled = IOpenSeaExchange(OPENSEA_EXCHANGE).fulfillOrder{value: }(
            order,
            fulfillerConduitKey
        );

        return fulfilled;
    }

    function purchase(Marketplace marketplace, bytes calldata _data)
        external
        payable
        override
    {
        if (marketplace == Marketplace.OPENSEA) {
            (Order memory order, bytes32 fulfillerConduitKey) = abi.decode(
                _data,
                (Order, bytes32)
            );

            bool _success = openseaPurchase(_data);
        } else if (marketplace == Marketplace.LOOKSRARE) {
            LooksRareOrderTypes.MakerOrder memory makerAsk = abi.decode(
                _data,
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

            bool _success = looksrarePurchase(takerBid, makerAsk);
        }
    }
}
