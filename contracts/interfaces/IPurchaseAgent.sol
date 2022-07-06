// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPurchaseAgent {
    enum Marketplace {
        OPENSEA,
        LOOKSRARE
    }

    function purchase(Marketplace marketplace, bytes calldata _data)
        external
        payable;
}
