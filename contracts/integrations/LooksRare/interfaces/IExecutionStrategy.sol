// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {LooksRareOrderTypes} from "../libraries/LooksRareOrderTypes.sol";

interface IExecutionStrategy {
    function canExecuteTakerAsk(
        LooksRareOrderTypes.TakerOrder calldata takerAsk,
        LooksRareOrderTypes.MakerOrder calldata makerBid
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(
        LooksRareOrderTypes.TakerOrder calldata takerBid,
        LooksRareOrderTypes.MakerOrder calldata makerAsk
    )
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
}
