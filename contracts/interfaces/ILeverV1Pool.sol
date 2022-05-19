// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILeverV1Pool {
    function deposit() external payable;

    function collect(uint256 amountRequested) external;

    function quickSell() external;

    function compound() external;

    function liquidate() external;

    function liquidateAll() external;

    function borrow(uint256 tokenId) external payable;

    function repay(/* address borrower,  */uint256 tokenId /* bytes memory loanHash */) external payable;

    event Borrow(address borrower, uint256 amount, uint256 tokenId);
    event Repay(address borrower, uint256 amount, uint256 tokenId); // maybe change to borrow hash

}
