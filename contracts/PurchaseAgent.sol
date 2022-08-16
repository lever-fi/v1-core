// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IOpenSeaExchange} from "./integrations/OpenSea/interfaces/IOpenSeaExchange.sol";
import {OpenSeaOrderTypes} from "./integrations/OpenSea/libraries/OpenSeaOrderTypes.sol";

import {ILooksRareExchange} from "./integrations/LooksRare/interfaces/ILooksRareExchange.sol";
import {IExecutionStrategy} from "./integrations/LooksRare/interfaces/IExecutionStrategy.sol";
import {LooksRareOrderTypes} from "./integrations/LooksRare/libraries/LooksRareOrderTypes.sol";

import {Marketplace, IPurchaseAgent} from "./interfaces/IPurchaseAgent.sol";
import {IERC721Minimal} from "./tokens/interfaces/IERC721Minimal.sol";

contract PurchaseAgent is IPurchaseAgent {
    using OpenSeaOrderTypes for OpenSeaOrderTypes.BasicOrderParameters;
    using LooksRareOrderTypes for LooksRareOrderTypes.MakerOrder;
    using LooksRareOrderTypes for LooksRareOrderTypes.TakerOrder;

    event AssetPurchase(
        Marketplace marketplace,
        address indexed exchangeLocation,
        uint256 tokenId,
        uint256 price
    );

    address public constant OPENSEA_EXCHANGE =
        0x00000000006c3852cbEf3e08E8dF289169EdE581; //0x7f268357A8c2552623316e2562D90e642bB538E5;
    address public constant LOOKSRARE_EXCHANGE =
        0x1AA777972073Ff66DCFDeD85749bDD555C0665dA; //0x59728544B08AB483533076417FbBB2fD0B17CE3a;

    constructor(address _originalCollection) {
        IERC721Minimal collection = IERC721Minimal(_originalCollection);
        collection.setApprovalForAll(OPENSEA_EXCHANGE, true);
        collection.setApprovalForAll(LOOKSRARE_EXCHANGE, true);
    }

    function openseaPurchase(
        OpenSeaOrderTypes.BasicOrderParameters memory parameters,
        uint256 price
    ) private returns (bool) {
        bool fulfilled = IOpenSeaExchange(OPENSEA_EXCHANGE).fulfillBasicOrder{
            value: price
        }(parameters);

        emit AssetPurchase(
            Marketplace.OPENSEA,
            OPENSEA_EXCHANGE,
            parameters.offerIdentifier,
            price
        );

        return fulfilled;
    }

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
        emit AssetPurchase(
            Marketplace.LOOKSRARE,
            LOOKSRARE_EXCHANGE,
            makerAsk.tokenId,
            makerAsk.price
        );

        return true;
        // 205-210
    }

    function purchase(Marketplace marketplace, bytes calldata _data)
        public
        payable
        returns (bool _success)
    {
        if (marketplace == Marketplace.OPENSEA) {
            (
                OpenSeaOrderTypes.BasicOrderParameters memory parameters,
                uint256 price
            ) = abi.decode(
                    _data,
                    (OpenSeaOrderTypes.BasicOrderParameters, uint256)
                );

            _success = openseaPurchase(parameters, price);
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

            _success = looksrarePurchase(takerBid, makerAsk);
        }
    }
}
