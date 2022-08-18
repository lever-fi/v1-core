// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ILeverV1Pool} from "./interfaces/ILeverV1Pool.sol";
import {IERC20Minimal} from "./tokens/interfaces/IERC20Minimal.sol";
import {IERC721Minimal} from "./tokens/interfaces/IERC721Minimal.sol";

import {Installment, Loan, BorrowAssetData} from "./lib/V1PoolStructs.sol";

import {LeverV1LPT} from "./tokens/LeverV1LPT.sol";
import {LeverV1LPS} from "./tokens/LeverV1LPS.sol";

import {PurchaseAgent} from "./PurchaseAgent.sol";

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// WETH setApproval

// manual listing request for specific price

// set up autopay + preload. Autopay WETH only gets triggered if no more funds preloaded
// borrowers can contribute ether to their outstanding loan balance, effectively making early payments, to maintain sufficient collateralization

// min/max loanTerm
// min/max interestRate (min + % to get max)

// include loan principal into pool value calculations

contract LeverV1Pool is
    ILeverV1Pool,
    PurchaseAgent,
    ERC721Holder,
    ReentrancyGuard
{
    /*
        [holdings] how much ETH has a certain address contributed
        [principals] how much ETH does a borrower owe. Aggregated value
        [positions] how much ETH does a borrower owe for a specific tokenId

        [riskIndex] 0 - 100 how risky is the collection
        [minLiquidity] minimum eth liquidity a pool will hold at any given time
    */
    mapping(address => uint256) public holdings;
    mapping(address => uint256) public principals;
    mapping(uint256 => Loan) public positions;
    mapping(uint256 => address) public owners;

    /* 
        positions vs activePositions
        positions = tokenId mapping to Loan struct
        activePositions = array consisting of activePosition tokenIds
    */
    // used for applying
    uint256[] public activePositions;
    uint256[] public liquidationQueue; // implement
    uint256[] public collectorsQueue; // implement
    //Offer[] public poolOffers; // implement (WETH only)
    // add and remove from activepositions

    // bytes to loan struct for checking specific loan status. one address can have multiple active loans

    address public immutable factory;
    address public immutable originalCollection;
    address public immutable syntheticCollection;
    address public immutable poolToken;
    address public immutable treasury;

    //address public oracle;
    //address public purchaseAgent;

    uint256 public collateralCoverageRatio;
    uint256 public interestRate;
    uint256 public chargeInterval;
    uint256 public burnRate;
    uint256 public loanTerm;
    uint256 public minLiquidity;
    uint256 public minDeposit;
    //uint256 public riskIndex;
    uint256 public paymentFrequency;

    address public deployer;
    address public WETHContract;

    string symbol;
    uint256 lastCharge;
    uint256 public truePoolValue;

    modifier onlyDeployer() {
        require(msg.sender == deployer, "LeverV1Pool: Sender not Deployer");
        _;
    }

    /*
    factory contract location
    base rate at which principle interest starts
    rate at which pool revenue is burnt
    time difference between which a loan must be repaid
    */
    constructor(
        address _factory,
        //address _marketplace,
        //address _oracle,
        //address _purchaseAgent,
        address _originalCollection,
        uint256 _collateralCoverageRatio,
        uint256 _interestRate,
        uint256 _chargeInterval,
        uint256 _burnRate,
        uint256 _loanTerm,
        uint256 _minLiquidity,
        uint256 _minDeposit,
        uint256 _paymentFrequency,
        address _deployer
    ) PurchaseAgent(_originalCollection) {
        factory = _factory;
        //marketplace = _marketplace;
        //oracle = _oracle;
        //purchaseAgent = _purchaseAgent;
        originalCollection = _originalCollection;
        collateralCoverageRatio = _collateralCoverageRatio;
        interestRate = _interestRate;
        chargeInterval = _chargeInterval;
        burnRate = _burnRate;
        loanTerm = _loanTerm;
        minLiquidity = _minLiquidity;
        minDeposit = _minDeposit;
        deployer = _deployer;
        paymentFrequency = _paymentFrequency;

        treasury = address(0);

        IERC721Minimal OriginalCollection = IERC721Minimal(_originalCollection);
        symbol = string(
            abi.encodePacked(OriginalCollection.symbol(), "_LFI_LPP")
        );
        string memory tokenName = string(
            abi.encodePacked(OriginalCollection.symbol(), "_LFI_LPT")
        );
        string memory nftCollectionName = string(
            abi.encodePacked(OriginalCollection.symbol(), "_LFI_LPS")
        );

        syntheticCollection = address(
            new LeverV1LPS(
                nftCollectionName,
                nftCollectionName,
                address(this),
                _originalCollection
            )
        );
        poolToken = address(
            new LeverV1LPT(tokenName, tokenName, address(this))
        );

        emit Create(
            _originalCollection,
            _collateralCoverageRatio,
            _interestRate,
            _chargeInterval,
            _burnRate,
            _loanTerm,
            _minLiquidity,
            _minDeposit
        );
    }

    // deposit funds into pool and get lp tokens in return
    function deposit() external payable override nonReentrant {
        if (msg.value < minDeposit) {
            revert Error_InsufficientBalance();
        }

        IERC20Minimal PoolToken = IERC20Minimal(poolToken);
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

        if (!success) {
            revert Error_NotSuccessful();
        }

        truePoolValue += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function collect(uint256 amountRequested) external override nonReentrant {
        uint256 poolValue = truePoolValue; //address(this).balance;

        IERC20Minimal PoolToken = IERC20Minimal(poolToken);
        uint256 userBalance = PoolToken.balanceOf(msg.sender);

        if (userBalance < amountRequested || userBalance == 0) {
            revert Error_InsufficientBalance();
        }

        uint256 totalSupply = PoolToken.totalSupply();
        uint256 owedBalance = (((amountRequested * 1 ether) / totalSupply) *
            poolValue) / 1 ether;

        if (address(this).balance < owedBalance) {
            //if (poolValue <= owedBalance) {
            // add to queue, transfer possible balance, and add throw
            revert Error_InsufficientLiquidity();
        }

        bool success = PoolToken.burnFrom(msg.sender, amountRequested);

        if (!success) {
            revert Error_NotSuccessful();
        }

        (bool sent, bytes memory data) = payable(msg.sender).call{
            value: owedBalance
        }(""); //.transfer(owedBalance);

        if (!sent) {
            revert Error_NotSuccessful();
        }

        truePoolValue -= owedBalance;
        emit Collect(msg.sender, owedBalance);
    }

    // sell asset before loans are paid off.
    function quickSell(uint256 tokenId) external override {}

    function quickSell(uint256 tokenId, uint256 value) external override {}

    // borrow funds to purchase NFTs
    function borrow(bytes calldata assetData, bytes calldata purchaseData)
        external
        payable
        override
        nonReentrant
    {
        BorrowAssetData memory _assetData = abi.decode(
            assetData,
            (BorrowAssetData)
        );

        //check to see if tokenId exists in synthetic collection

        if (
            positions[_assetData.tokenId].active == true ||
            positions[_assetData.tokenId].principal > 0
        ) {
            revert Error_ExistingLoan();
        }

        if (
            address(this).balance + msg.value - _assetData.price < minLiquidity
        ) {
            revert Error_InsufficientLiquidity();
        }

        // retrieving token price
        uint256 listingPrice = _assetData.price;

        if ((msg.value * 1 ether) / listingPrice < collateralCoverageRatio) {
            revert Error_InsufficientContribution();
        }

        // call PurchaseAgent
        bool purchaseSuccess = purchase(_assetData.marketplace, purchaseData);

        // if purchase success
        LeverV1LPS(syntheticCollection).mint(msg.sender, _assetData.tokenId);

        uint256 principal = listingPrice - msg.value;
        uint256 installmentCount = loanTerm / paymentFrequency;

        Loan storage _loan = positions[_assetData.tokenId];

        _loan.lastCharge = block.timestamp;
        _loan.principal = listingPrice - msg.value;
        _loan.interest = 0;
        _loan.dailyPercentRate = interestRate / 365;
        _loan.paymentFrequency = paymentFrequency;
        _loan.borrower = msg.sender;
        _loan.createdTimestamp = block.timestamp;
        _loan.expirationTimestamp = block.timestamp + loanTerm;
        _loan.loanTerm = loanTerm;
        _loan.finalizedTimestamp = 0;
        _loan.active = true;
        _loan.repaymentAllowance = 0;
        _loan.installmentsRemaining = installmentCount;
        _loan.collateral = 0;

        for (uint256 i = 0; i < _loan.installmentsRemaining; i++) {
            _loan.installments.push(
                Installment(
                    principal / _loan.installmentsRemaining,
                    block.timestamp + ((i + 1) * _loan.paymentFrequency)
                )
            );
        }

        //positions[_assetData.tokenId] = _loan;

        emit Borrow(msg.sender, msg.value, _assetData.tokenId);
    }

    // borrowers pay back loan. If loan payment is complete, transfer NFT ownership
    function repay(
        uint256 tokenId /* bytes memory loanHash */
    ) external payable override nonReentrant {
        require(msg.value > 0, "LeverV1Pool: can't repay nothing");
        Loan storage _loan = positions[tokenId];
        require(_loan.active == true, "LeverV1Pool: inactive");
        require(_loan.principal > 0, "LeverV1Pool: no principal");
        require(
            _loan.expirationTimestamp <= block.timestamp,
            "LeverV1Pool: loan expired"
        );
        require(
            _loan.borrower == msg.sender,
            "LeverV1Pool: Mismatched borrowers"
        );

        uint256 timeDifference = block.timestamp - _loan.lastCharge;
        uint256 _msgValue = msg.value;

        require(timeDifference > paymentFrequency, "LeverV1Pool: times up");
        uint256 _interestPayment = _loan.interest;
        uint256 _principalPayment = _loan.principal;
        //uint256 amountToRepay = _interestPayment + _principalPayment; //getRepaymentAmount(_loan);

        // if msg.value is not sufficient enough to cover interest payment
        if (_msgValue < _interestPayment) {
            truePoolValue += _msgValue;
            _loan.interest -= _msgValue; // subtract interest from msg value
            // else just set interest to 0 and subtract from msg value
        } else {
            truePoolValue += _loan.interest;
            _loan.interest = 0;
            _msgValue -= _interestPayment;

            if (_msgValue < _principalPayment) {
                _loan.principal -= _msgValue;
            } else {
                _loan.principal = 0;
            }

            (uint256 _installmentSum, uint256 _firstIndex) = sumInstallments(
                tokenId
            );

            // contribute to installment payments
            // while value is still remaining, keep hacking off of installments
            while (_msgValue > 0 && _installmentSum > 0) {
                if (_msgValue < _loan.installments[_firstIndex].amount) {
                    _loan.installments[_firstIndex].amount -= _msgValue;
                    break;
                } else {
                    _msgValue -= _loan.installments[_firstIndex].amount;
                    delete _loan.installments[_firstIndex];
                }

                (_installmentSum, _firstIndex) = sumInstallments(tokenId);
            }

            // loan has been successfully paid off
            if (_loan.principal == 0) {
                // ILeverV1LPS
                LeverV1LPS _syntheticCollection = LeverV1LPS(
                    syntheticCollection
                );
                IERC721Minimal _originalCollection = IERC721Minimal(
                    originalCollection
                );

                _loan.principal = 0;
                _loan.finalizedTimestamp = block.timestamp;
                _loan.active = false;
                //owners[tokenId] = address(0);
                // redistrib collateral

                // burn
                _syntheticCollection.burn(tokenId);
                // transfer NFT
                _originalCollection.transferFrom(
                    address(this),
                    msg.sender,
                    tokenId
                );
            }
        }

        emit Repay(msg.sender, msg.value, tokenId);
    }

    function calculateInterest(uint256 _principal, uint256 _dailyPercentRate)
        public
        pure
        returns (uint256)
    {
        return (_principal * _dailyPercentRate) / 1 ether;
    }

    // chainlink keeper function
    // maybe charge on a certain tokenId?
    function chargeInterest() external override {
        uint256 positionIndex = 0;
        while (positionIndex < activePositions.length) {
            uint256 position = activePositions[positionIndex];
            bool shouldLiquidate = false;

            // do we subtract installmentsRemaining?
            // if installment due date is less than current time, decrement
            //
            if (
                block.timestamp >=
                positions[position].installments[0].dueTimestamp
            ) {
                positions[position].installmentsRemaining -= 1;
                if (
                    positions[position].installmentsRemaining == 0 ||
                    positions[position].installmentsRemaining <
                    positions[position].installments.length
                ) {
                    shouldLiquidate = true;
                }
            }

            if (positions[position].expirationTimestamp > block.timestamp) {
                shouldLiquidate = true;
            }

            if (shouldLiquidate) {
                // trigger liquidation
                activePositions[positionIndex] = activePositions[
                    activePositions.length - 1
                ];
                activePositions.pop();
            } else {
                positions[position].lastCharge = block.timestamp;
                positions[position].interest += calculateInterest(
                    positions[position].principal,
                    positions[position].dailyPercentRate
                );
            }

            positionIndex += 1;
        }
    }

    function sumInstallments(uint256 tokenId)
        internal
        view
        returns (uint256 sum, uint256 firstIndex)
    {
        bool indexFound = false;
        for (uint256 i = 0; i < positions[tokenId].installments.length; i++) {
            if (
                positions[tokenId].installments[i].amount > 0 &&
                indexFound == false
            ) {
                indexFound = true;
                firstIndex = i;
            }

            sum += positions[tokenId].installments[i].amount;
        }
    }

    function getTokenLoanStatus(uint256 tokenId)
        public
        view
        returns (Loan memory)
    {
        return positions[tokenId];
    }

    // liquidate current position - mindful of gas but oracle will handle
    function liquidate(uint256 tokenId, uint256 value) external override {
        // swap with offers or list on exchanges
    }

    // liquidate all NFTs in collection
    function liquidateAll() external override {
        // swap with offers or list on exchanges
    }

    // multisig, migrate assets, sender can only be from factory
    function collapse() external {}

    // offer for NFTs. Upon liquidation, orders will be matched against offers list before hitting other markets
    function offer() external {}

    function unwrap() public {
        // get balance
        /* 
        deposit(){value: depositAmt}
        withdraw(uint256 amt)
        approve(address operator, uint256 amt)
        */
    }

    receive() external payable {}

    // used for quickSell and liquidation
    function _sell(uint256 tokenId, uint256 value) internal returns (bool) {
        return false;
    }

    function canCharge() external view returns (bool) {
        return lastCharge + chargeInterval >= block.timestamp;
    }

    function wenCharge() external view returns (uint256) {
        return lastCharge + chargeInterval;
    }

    function setCollateralCoverageRatio(uint256 _collateralCoverageRatio)
        external
        onlyDeployer
    {
        collateralCoverageRatio = _collateralCoverageRatio;
    }

    function setInterestRate(uint256 _interestRate) external onlyDeployer {
        interestRate = _interestRate;
    }

    function setChargeInterval(uint256 _chargeInterval) external onlyDeployer {
        chargeInterval = _chargeInterval;
    }

    function setBurnRate(uint256 _burnRate) external onlyDeployer {
        burnRate = _burnRate;
    }

    function setLoanTerm(uint256 _loanTerm) external onlyDeployer {
        loanTerm = _loanTerm;
    }

    function setMinLiquidity(uint256 _minLiquidity) external onlyDeployer {
        minLiquidity = _minLiquidity;
    }

    function setMinDeposit(uint256 _minDeposit) external onlyDeployer {
        minDeposit = _minDeposit;
    }

    function setDeployer(address _deployer) external onlyDeployer {
        deployer = _deployer;
    }
}
