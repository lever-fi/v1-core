// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILeverV1Pool.sol";
import "./interfaces/IERC20Essential.sol";
import "./interfaces/IERC721Minimal.sol";

import "./LeverV1ERC20Essential.sol";
import "./LeverV1ERC721L.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "hardhat/console.sol";

contract LeverV1Pool is ILeverV1Pool {
    /*
        [holdings] how much ETH has a certain address contributed
        [principals] how much ETH does a borrower owe. Aggregated value
        [limits] how much WETH a certain address is willing to purchase any NFT for
        [offers] how much WETH a certain address is willing to purchase an NFT for
        [positions] how much ETH does a borrower owe for a specific tokenId

        [riskIndex] 0 - 100 how risky is the collection
        [minLiquidity] minimum percent of liquidity a pool will hold at any given time
    */
    mapping(address => uint256) public holdings;
    mapping(address => uint256) public principals;
    //mapping(address => uint256) public limits;
    //mapping(uint256 => Offer) public offers;
    mapping(uint256 => Loan) public positions;
    mapping(uint256 => address) public owners;

    // bytes to loan struct for checking specific loan status. one address can have multiple loans

    address public immutable factory;
    address public immutable originalCollection;
    address public immutable wrappedCollection;
    address public immutable poolToken;
    address public immutable treasury;

    address public oracle;

    uint256 public collateralCoverageRatio;
    uint256 public interestRate;
    uint256 public compoundInterval;
    uint256 public burnRate;
    uint256 public loanTerm;
    uint256 public minLiquidity;
    uint256 public minDeposit;
    uint256 public riskIndex;

    struct Loan {
        uint256 lastCompound;
        uint256 principal;
        address borrower;
        uint256 createdTimestamp;
        uint256 expirationTimestamp;
        uint256 loanTerm;
        uint256 finalizedTimestamp;
        bool active;
    }

    /* struct Offer {
        address owner;
        uint256 amount;
    } */

    /*
    factory contract location
    base rate at which principle interest starts
    rate at which pool revenue is burnt
    time difference between which a loan must be repaid

    */
    constructor(
        address _factory,
        address _oracle,
        address _originalCollection,
        uint256 _collateralCoverageRatio,
        uint256 _interestRate,
        uint256 _compoundInterval,
        uint256 _burnRate,
        uint256 _loanTerm,
        uint256 _minLiquidity,
        uint256 _minDeposit
    ) {
        factory = _factory;
        oracle = _oracle;
        originalCollection = _originalCollection;
        collateralCoverageRatio = _collateralCoverageRatio;
        interestRate = _interestRate;
        compoundInterval = _compoundInterval;
        burnRate = _burnRate;
        loanTerm = _loanTerm;
        minLiquidity = _minLiquidity;
        _minDeposit = minDeposit;

        treasury = address(0);

        IERC721Minimal OriginalCollection = IERC721Minimal(_originalCollection);
        string memory tokenName = string(abi.encodePacked(OriginalCollection.name(), "-LP-LFI"));
        string memory nftCollectionName = string(abi.encodePacked(tokenName, "-NFT"));

        wrappedCollection = address(new LeverV1ERC721L(nftCollectionName, nftCollectionName, address(this)));
        poolToken = address(
            new LeverV1ERC20Essential(tokenName, tokenName, address(this))
        );
    }

    // deposit funds into pool and get lp tokens in return
    function deposit() external payable override {
        require(msg.value >= minDeposit, "LeverV1Pool: Deposit < required"); // deposit less than min required deposit
        IERC20Essential PoolToken = IERC20Essential(poolToken);
        uint256 aPost = address(this).balance;
        uint256 totalSupply = PoolToken.totalSupply();

        uint256 split = msg.value * 1 ether / aPost;
        uint256 amount;

        if (totalSupply == 0) {
            amount = msg.value;
        } else {
            amount = split * totalSupply / (1 ether - split);
        }

        bool success = PoolToken.mintTo(msg.sender, amount);

        require(success, "LeverV1Pool: LP Token mint");
    }

    // trade in token for pool earnings
    function collect(uint256 amountRequested) external override {
        uint256 poolValue = address(this).balance;
        //require(poolValue >= minLiquidity, "Balance < min liquidity"); // contract balance less than min liquidity

        // lp token balance must be greater than requested collected amt
        IERC20Essential PoolToken = IERC20Essential(poolToken);
        uint256 userBalance = PoolToken.balanceOf(msg.sender);

        require(userBalance >= amountRequested, "AMRLTB"); // amount requested less than balance

        // total supply
        uint256 totalSupply = PoolToken.totalSupply();
        
        uint256 owedBalance = (((amountRequested * 1 ether) /
            totalSupply) * poolValue) / 1 ether;

        require(poolValue >= owedBalance, "LeverV1Pool: not enough liquidity to collect balance");

        // successfully burn tokens before any important action
        bool success = PoolToken.burnFrom(msg.sender, amountRequested);
        require(success, "LeverV1Pool: LP Token burn");

        payable(msg.sender).transfer(owedBalance);
    }

    // sell asset before loans are paid off.
    function quickSell() external override {}


    // chainlink keeper function
    function compound() external override {}

    // liquidate current position - mindful of gas but oracle will handle
    function liquidate() external override {
        // swap with offers or list on exchanges
    }

    // liquidate all NFTs
    function liquidateAll() external override {
        // swap with offers or list on exchanges
    }

    // "borrow" funds to purchase NFTs
    function borrow(uint256 tokenId) external payable override {
        // token listing must exist
        require(address(this).balance - msg.value >= minLiquidity, "LeverV1Pool: pool funds too low"); // balance below min liquidity
        require(true, "LeverV1Pool: Max coverage exceeded"); // pool required to input more than max coverage 
        
        Loan memory _loan = positions[tokenId];

        require(_loan.active == false, "LeverV1Pool: active");

        /* 
        check to see if there is enough eth in the pool
        check to see if floor price of collection - message value is within coverage range of pool
        create loan struct
        purchase floor nft from opensea - oracle
        assign mapping
         */
    }

    // borrowers pay back loan. If loan payment is complete, transfer NFT ownership
    function repay(/* address borrower,  */uint256 tokenId/* bytes memory loanHash */)
        external
        payable
        override
    {
        Loan memory _loan = positions[tokenId];
        require(_loan.active == true, "LeverV1Pool: inactive");
        require(_loan.principal > 0, "LeverV1Pool: no principal");
        require(_loan.expirationTimestamp < block.timestamp, "LeverV1Pool: loan expired");
        require(_loan.borrower == /* borrower */msg.sender, "LeverV1Pool: Mismatched borrowers");
    
        uint256 timeDifference = block.timestamp - _loan.lastCompound;

        require(timeDifference < compoundInterval, "LeverV1Pool: overdrafted");
        uint256 amountToRepay = getRepaymentAmount(_loan);

        if (msg.value >= amountToRepay) {
            _loan.principal = 0;
            _loan.finalizedTimestamp = block.timestamp;
            _loan.active = false;
            owners[tokenId] = address(0);
            // transfer NFT
        } else {
            _loan.principal = _loan.principal - amountToRepay;
        }

        //if (timeDifference >= compoundInterval) {
        _loan.lastCompound = block.timestamp;
        //}

        positions[tokenId] = _loan;
    }

    //
    function getRepaymentAmount(Loan memory _loan) internal view returns (uint256) {
        //uint256 timeDifference = block.timestamp - _loan.lastCompound;

        /* if (timeDifference >= compoundInterval) {
            return _loan.principal;
        }
        
        uint256 overlap;

        while (timeDifference > compoundInterval) {
            timeDifference -= compoundInterval;
            overlap += 1;
        } */

        //return _loan.principal * (1 ether + interestRate) ** overlap;
        return _loan.principal * (1 ether + interestRate);
    }

    function setOracle(address _oracle) external {
        oracle = _oracle;
    }

    // multisig, migrate assets, sender can only be from factory
    function collapse() external {}

    // offer for NFTs. Upon liquidation, orders will be matched against offers list before hitting other markets
    function offer() external {}

    receive() external payable {}
}
