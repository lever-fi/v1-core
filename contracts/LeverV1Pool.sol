// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./interfaces/ILeverV1Pool.sol";
import "./interfaces/IERC20Essential.sol";
import "./interfaces/IERC721Minimal.sol";

import "./LeverV1ERC20Essential.sol";
import "./LeverV1ERC721L.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./extras/IMarketplace.sol";

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

    // used for compounding
    uint256[] public activePositions;

    // bytes to loan struct for checking specific loan status. one address can have multiple loans

    address public immutable factory;
    address public immutable originalCollection;
    address public immutable wrappedCollection;
    address public immutable poolToken;
    address public immutable treasury;
    address public immutable marketplace;

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
        address _marketplace,
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
        marketplace = _marketplace;
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
        string memory tokenName = string(
            abi.encodePacked(OriginalCollection.name(), "-LP-LFI")
        );
        string memory nftCollectionName = string(
            abi.encodePacked(tokenName, "-NFT")
        );

        wrappedCollection = address(
            new LeverV1ERC721L(
                nftCollectionName,
                nftCollectionName,
                address(this)
            )
        );
        poolToken = address(
            new LeverV1ERC20Essential(tokenName, tokenName, address(this))
        );

        emit Create(
            _originalCollection,
            _collateralCoverageRatio,
            _interestRate,
            _compoundInterval,
            _burnRate,
            _loanTerm,
            _minLiquidity,
            _minDeposit
        );
    }

    // deposit funds into pool and get lp tokens in return
    function deposit() external payable override {
        require(msg.value >= minDeposit, "LeverV1Pool: Deposit < required"); // deposit less than min required deposit
        IERC20Essential PoolToken = IERC20Essential(poolToken);
        uint256 aPost = address(this).balance;
        uint256 totalSupply = PoolToken.totalSupply();

        uint256 split = (msg.value * 1 ether) / aPost;
        uint256 amount;

        if (totalSupply == 0) {
            amount = msg.value;
        } else {
            amount = (split * totalSupply) / (1 ether - split);
        }

        bool success = PoolToken.mintTo(msg.sender, amount);

        require(success, "LeverV1Pool: LP Token mint");

        emit Deposit(msg.sender, msg.value);
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

        uint256 owedBalance = (((amountRequested * 1 ether) / totalSupply) *
            poolValue) / 1 ether;

        require(
            poolValue >= owedBalance,
            "LeverV1Pool: not enough liquidity to collect balance"
        );

        // successfully burn tokens before any important action
        bool success = PoolToken.burnFrom(msg.sender, amountRequested);
        require(success, "LeverV1Pool: LP Token burn");

        payable(msg.sender).transfer(owedBalance);

        emit Collect(msg.sender, owedBalance);
    }

    // sell asset before loans are paid off.
    function quickSell(uint256 tokenId) external override {}

    function quickSell(uint256 tokenId, uint256 value) external override {}

    // chainlink keeper function
    function compound() external override {}

    // liquidate current position - mindful of gas but oracle will handle
    function liquidate(uint256 tokenId, uint256 value) external override {
        // swap with offers or list on exchanges
    }

    // liquidate all NFTs
    function liquidateAll() external override {
        // swap with offers or list on exchanges
    }

    // "borrow" funds to purchase NFTs
    function borrow(uint256 tokenId) external payable override {
        /* 
         retrieve tokenId price
        check to see if there is enough eth in the pool
        check to see if token price of collection - message value is within coverage range of pool
        create loan
        purchase token from opensea - aggregate later
        assign mapping
         */

        require(
            positions[tokenId].active == false &&
                positions[tokenId].principal == 0,
            "LeverV1Pool: existant loan"
        );
        require(
            address(this).balance - msg.value >= minLiquidity,
            "LeverV1Pool: pool funds too low"
        ); // balance below min liquidity

        // retrieving token price
        (bool listingPriceSuccess, bytes memory listingPriceData) = marketplace
            .staticcall(
                abi.encodeWithSelector(
                    IMarketplace.getListing.selector,
                    tokenId
                )
            );
        uint256 listingPrice = abi.decode(listingPriceData, (uint256));

        // test
        require(
            (msg.value * 1 ether) / listingPrice > collateralCoverageRatio,
            "LeverV1Pool: Max coverage exceeded"
        ); // pool required to input more than max coverage

        // purchase
        (bool purchaseSuccess, bytes memory purchaseData) = marketplace.call{
            value: listingPrice
        }(abi.encodeWithSelector(IMarketplace.purchase.selector, tokenId));
        require(purchaseSuccess, "LeverV1Pool: purchase failed");

        // if success mint fake
        if (purchaseSuccess) {
            LeverV1ERC721L WrappedCollection = LeverV1ERC721L(
                wrappedCollection
            );

            positions[tokenId] = Loan(
                block.timestamp,
                listingPrice - msg.value,
                msg.sender,
                block.timestamp,
                block.timestamp + loanTerm,
                loanTerm,
                0,
                true
            );

            WrappedCollection.mint(msg.sender, tokenId);

            emit Borrow(msg.sender, msg.value, tokenId);
        } else {
            revert("LeverV1Pool: nft purchase failed");
        }
    }

    // borrowers pay back loan. If loan payment is complete, transfer NFT ownership
    function repay(
        /* address borrower,  */
        uint256 tokenId /* bytes memory loanHash */
    ) external payable override {
        Loan memory _loan = positions[tokenId];
        require(_loan.active == true, "LeverV1Pool: inactive");
        require(_loan.principal > 0, "LeverV1Pool: no principal");
        require(
            _loan.expirationTimestamp < block.timestamp,
            "LeverV1Pool: loan expired"
        );
        require(
            _loan.borrower ==
                /* borrower */
                msg.sender,
            "LeverV1Pool: Mismatched borrowers"
        );

        uint256 timeDifference = block.timestamp - _loan.lastCompound;

        require(timeDifference < compoundInterval, "LeverV1Pool: overdrafted");
        uint256 amountToRepay = getRepaymentAmount(_loan);

        //console.log("%s\n%s\n%s", _loan.principal, amountToRepay, msg.value);

        if (msg.value >= amountToRepay) {
            // ILeverV1ERC721L
            LeverV1ERC721L WrappedCollection = LeverV1ERC721L(
                wrappedCollection
            );
            IERC721Minimal OriginalCollection = IERC721Minimal(
                originalCollection
            );

            _loan.principal = 0;
            _loan.finalizedTimestamp = block.timestamp;
            _loan.active = false;
            owners[tokenId] = address(0);
            // burn
            WrappedCollection.burn(tokenId);
            // transfer NFT
            OriginalCollection.transferFrom(address(this), msg.sender, tokenId);
        } else {
            _loan.principal = _loan.principal - msg.value;
        }

        //if (timeDifference >= compoundInterval) {
        _loan.lastCompound = block.timestamp;
        //}

        positions[tokenId] = _loan;

        emit Repay(msg.sender, msg.value, tokenId);
    }

    //
    function getRepaymentAmount(Loan memory _loan)
        internal
        view
        returns (uint256)
    {
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
        return (_loan.principal * (1 ether + interestRate)) / 1 ether;
    }

    function getTokenLoanStatus(uint256 tokenId)
        public
        view
        returns (Loan memory)
    {
        return positions[tokenId];
    }

    function setOracle(address _oracle) external {
        oracle = _oracle;
    }

    // multisig, migrate assets, sender can only be from factory
    function collapse() external {}

    // offer for NFTs. Upon liquidation, orders will be matched against offers list before hitting other markets
    function offer() external {}

    receive() external payable {}

    // used for quickSell and liquidation
    function _sell(uint256 tokenId, uint256 value) internal returns (bool) {
        (bool sellSuccess, bytes memory sellData) = marketplace.call(
            abi.encodeWithSelector(IMarketplace.sell.selector, tokenId, value)
        );
        require(sellSuccess, "LeverV1Pool: sale failed");

        return sellSuccess;
    }

    function _getPrice(uint256 tokenId) internal returns (uint256) {}
}
