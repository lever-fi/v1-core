// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/IERC20Essential.sol";
import "./interfaces/IERC721Minimal.sol";
import "./LeverV1ERC20Essential.sol";
import "./interfaces/ILeverV1Pool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract LeverV1Pool is ILeverV1Pool {
    /*
        [holdings] how much ETH has a certain address contributed
        [principals] how much ETH does a borrower owe. Aggregated value
        [offers] how much WETH a certain address is willing to purchase an NFT for
        [positions] how much ETH does a borrower owe for a specific txn

        [riskIndex] 0 - 100 how risky is the collection
        [minLiquidity] minimum percent of liquidity a pool will hold at any given time
    */
    mapping(address => uint256) public holdings;
    mapping(address => uint256) public principals;
    mapping(address => uint256) public offers;
    mapping(bytes => uint256) public positions;

    // bytes to loan struct for checking specific loan status. one address can have multiple loans

    address public immutable factory;
    address public immutable originalCollection;
    address public immutable wrappedCollection;
    address public immutable poolToken;

    uint256 riskIndex;
    uint256 minLiquidity;
    uint256 minDeposit;

    struct Loan {
        uint256 balance;
        address borrower;
        uint256 createdTimestamp;
        uint256 expirationTimestamp;
        uint256 loanTerm;
        uint256 finalizedTimestamp;
    }

    /*
    factory contract location
    base rate at which principle interest starts
    rate at which pool revenue is burnt
    time difference between which a loan must be repaid

    */
    constructor(
        address _factory,
        address _originalCollection,
        uint256 _basePrincipleRate,
        uint256 _burnRate,
        uint256 _loanTerm
    ) {
        // deploy erc20 token
        // deloy erc721 wrapper
        factory = _factory;
        originalCollection = _originalCollection;
        wrappedCollection = 0x0000000000000000000000000000000000000000;

        (bool success, bytes memory data) = _originalCollection.staticcall(
            abi.encodeWithSelector(IERC721Minimal.name.selector)
        );
        require(success && data.length >= 32);
        string memory collectionName = string(
            abi.encodePacked(abi.decode(data, (string)), "-LP-LFI")
        );
        poolToken = address(
            new LeverV1ERC20Essential(collectionName, collectionName)
        );
    }

    // deposit funds into pool and get tokens in return
    function deposit() external payable override {
        (bool success, bytes memory data) = poolToken.call(
            abi.encodeWithSelector(
                IERC20Essential.mintTo.selector,
                msg.sender,
                msg.value
            )
        );
        require(success, "Failed to deposit");
    }

    // trade in token for pool earnings
    function collect(uint256 amountRequested) external override {
        uint256 poolValue = address(this).balance;
        require(poolValue >= minLiquidity, "BLTML"); // contract balance less than min liquidity

        // lp token balance must be greater than requested collected amt
        (bool balanceSuccess, bytes memory balanceData) = poolToken.staticcall(
            abi.encodeWithSelector(
                IERC20Essential.balanceOf.selector,
                msg.sender
            )
        );
        require(balanceSuccess);
        uint256 userBalance = abi.decode(balanceData, (uint256));
        require(userBalance >= amountRequested, "AMRLTB"); // amount requested less than balance

        // total supply
        (bool supplySuccess, bytes memory supplyData) = poolToken.staticcall(
            abi.encodeWithSelector(IERC20Essential.totalSupply.selector)
        );
        require(supplySuccess);

        uint256 owedBalance = amountRequested * 100 /
            abi.decode(supplyData, (uint256)) * poolValue / 100;

        // successfully burn tokens before any important action
        (bool burnSuccess, bytes memory burnData) = poolToken.call(
            abi.encodeWithSelector(
                IERC20Essential.burnFrom.selector,
                msg.sender,
                amountRequested
            )
        );
        require(burnSuccess);

        payable(msg.sender).transfer(owedBalance);
    }

    // sell asset before loans are paid off.
    function quickSell() external override {}

    // liquidate current position - mindful of gas but oracle will handle
    function liquidate() external override {
        // swap with offers or list on exchanges
    }

    // liquidate all NFTs
    function liquidateAll() external override {
        // swap with offers or list on exchanges
    }

    // "borrow" funds to purchase NFTs
    function borrow() external payable override {
        /* 
        check to see if there is enough eth in the pool
        check to see if floor price of collection - message value is within coverage range of pool
        create loan struct
        purchase floor nft from opensea - oracle
        assign mapping
         */
    }

    // borrowers pay back loan. If loan payment is complete, transfer NFT ownership
    function repay(address borrower, bytes memory loanHash)
        external
        payable
        override
    {
        /* 
        require loanHash to be active
        require borrower to be loanHash owner
        if loan balance is 0 at the end of the payment, transfer NFT to borrower and burn the NFT
         */
    }
}
