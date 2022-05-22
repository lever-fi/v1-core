// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ILeverV1Pool {
    function deposit() external payable;

    function collect(uint256 amountRequested) external;

    function quickSell(uint256 tokenId) external;

    function quickSell(uint256 tokenId, uint256 value) external;

    function compound() external;

    function liquidate(uint256 tokenId, uint256 value) external;

    function liquidateAll() external;

    function borrow(uint256 tokenId) external payable;

    function repay(
        /* address borrower,  */
        uint256 tokenId /* bytes memory loanHash */
    ) external payable;

    event Created(
        address originalCollection,
        uint256 collaterateCoverageRatio,
        uint256 interestRate,
        uint256 compoundInterval,
        uint256 burnRate,
        uint256 loanTerm,
        uint256 minLiquduity,
        uint256 minDeposit
    );
    event Deposit(address depositor, uint256 value);
    event Collect(address collector, uint256 value);
    event Borrow(address borrower, uint256 value, uint256 tokenId);
    event Repay(address borrower, uint256 value, uint256 tokenId); // maybe change to borrow hash
    event Liquidate(uint256 tokenId, uint256 value);
}
