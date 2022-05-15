// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILeverV1Pool {
    function deposit() external payable;

    function collect(uint256 amountRequested) external;

    function quickSell() external;

    function liquidate() external;

    function liquidateAll() external;

    function borrow() external payable;

    function repay(address borrower, bytes memory loanHash) external payable;
}
