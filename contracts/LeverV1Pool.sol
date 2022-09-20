// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ILeverV1Pool.sol";

import "./lib/ConversionMath.sol";

import "./lib/Loan.sol";
import "./lib/Installment.sol";

import "./tokens/interfaces/IERC20Minimal.sol";
import "./tokens/LeverV1ERC20.sol";
import "./tokens/interfaces/IERC721Minimal.sol";
import "./tokens/LeverV1ERC721.sol";

import "./AgentRouter.sol";

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract LeverV1Pool is ILeverV1Pool, ERC721Holder, ReentrancyGuard {
  using ConversionMath for uint256;
  using ConversionMath for int256;
  using Loan for mapping(bytes32 => Loan.Info);
  using Loan for Loan.Info;
  using Installment for Installment.Info[];

  address public immutable override factory;
  address public immutable override token;
  address public immutable override token0;
  address public immutable override token1;

  uint64 public override coverageRatio;
  uint64 public override interestRate;
  uint64 public override fee;
  uint32 public override chargeInterval;
  uint32 public override loanTerm;
  uint32 public override paymentFrequency;

  uint128 public override interestAccrued;
  uint128 public override minDeposit;
  uint256 public override minLiquidity;
  uint256 public override truePoolValue;

  address public override agentRouter;
  address public override assetManager;

  uint32 lastCharge;
  bool isPaused;
  address owner;

  mapping(bytes32 => Loan.Info) loans;
  mapping(uint256 => bool) book;

  modifier notPaused() {
    require(isPaused == false, "Paused");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not Owner");
    _;
  }

  constructor(
    address _agentRouter,
    address _assetManager,
    address _deployer,
    address _factory,
    address _token0
  ) {
    agentRouter = _agentRouter;
    assetManager = _assetManager;
    owner = _deployer;
    factory = _factory;
    token0 = _token0;

    string memory tk0Symbol = IERC721Minimal(token0).symbol();
    string memory tkName = string(abi.encodePacked(tk0Symbol, "_LFI_LPT"));
    string memory tk1Name = string(abi.encodePacked(tk0Symbol, "_LFI_LPS"));

    token = address(new LeverV1ERC20(tkName, tkName));
    token1 = address(
      new LeverV1ERC721(tk1Name, tk1Name, address(this), token0)
    );
  }

  function _release(uint256 tokenId) internal {
    IERC721Minimal tk0 = IERC721Minimal(token0);
    LeverV1ERC721 tk1 = LeverV1ERC721(token1);

    tk1.burn(tokenId);
    tk0.transferFrom(address(this), msg.sender, tokenId);
  }

  function _borrow(bytes calldata borrowData, bytes calldata agentData)
    internal
  {
    BorrowData memory _data = abi.decode(borrowData, (BorrowData));

    require(book[_data.tokenId] == false, "Loan in progress");

    uint256 balance = address(this).balance;

    if (
      _data.price > balance + msg.value ||
      balance + msg.value - _data.price < minLiquidity
    ) {
      revert InsufficientLiquidity();
    }

    if ((msg.value * 1 ether) / _data.price < coverageRatio) {
      revert InsufficientContribution();
    }

    bool success = AgentRouter(agentRouter).purchase{ value: _data.price }(
      _data.agentId,
      agentData
    );

    if (!success) {
      revert Unsuccessful();
    }

    LeverV1ERC721(token1).mint(msg.sender, _data.tokenId);

    Loan.Info storage loan = loans.get(msg.sender, _data.tokenId);
    loan.initialize(
      true,
      msg.sender,
      block.timestamp + loanTerm,
      loanTerm,
      _data.price - msg.value,
      0,
      interestRate / 365,
      chargeInterval,
      block.timestamp,
      paymentFrequency,
      0,
      0,
      uint8(loanTerm / paymentFrequency)
    );

    emit Borrow(msg.sender, msg.value, _data.price, _data.tokenId);
  }

  function _repay(uint256 tokenId) internal {
    require(msg.value > 0, "Invalid repayment amount");
    Loan.Info storage loan = loans.get(msg.sender, tokenId);
    require(loan.borrower == msg.sender, "Invalid signer");

    if (
      !loan.active ||
      loan.principal == 0 ||
      block.timestamp > loan.expirationTimestamp ||
      block.timestamp >
      loan
        .installments[loan.installments.length - loan.installmentsRemaining]
        .dueBy
    ) {
      revert DeadLoan();
    }

    uint256 interest = loan.interest;
    interestAccrued += uint128(interest < msg.value ? interest : msg.value);

    loan.repay();

    if (loan.principal == 0) {
      book[tokenId] = false;
      delete loans[keccak256(abi.encodePacked(msg.sender, tokenId))];
      _release(tokenId);

      emit LoanEvent(tokenId, uint8(LOAN_EVENT.CLOSED));
    }

    emit LoanRepay(tokenId, msg.value);
  }

  function deposit() external payable override {
    uint256 msgValue = msg.value;
    require(msgValue >= minDeposit, "Insufficient contribution");
    IERC20Minimal _token = IERC20Minimal(token);
    truePoolValue += msgValue;
    uint256 amountToMint = msgValue.computeTokenConversion(
      truePoolValue,
      _token.totalSupply()
    );
    bool success = _token.mintTo(msg.sender, amountToMint);

    if (!success) {
      revert Unsuccessful();
    }

    emit Deposit(msg.sender, msgValue, amountToMint);
  }

  function collect(uint256 amount) external override {
    IERC20Minimal _token = IERC20Minimal(token);
    require(
      amount > 0 && amount <= _token.balanceOf(msg.sender),
      "Invalid amount"
    );
    uint256 amountToWithdraw = amount.computeEthConversion(
      truePoolValue,
      _token.totalSupply()
    );
    if (amountToWithdraw > address(this).balance) {
      revert InsufficientLiquidity();
    }
    truePoolValue -= amountToWithdraw;
    bool success = _token.burnFrom(msg.sender, amount);

    if (!success) {
      revert Unsuccessful();
    }

    (success, ) = payable(msg.sender).call{ value: amountToWithdraw }("");

    if (!success) {
      revert Unsuccessful();
    }

    emit Collect(msg.sender, amountToWithdraw, amount);
  }

  function borrow(bytes calldata borrowData, bytes calldata agentData)
    external
    payable
    override
  {
    _borrow(borrowData, agentData);
  }

  function repay(uint256 tokenId) external payable override {
    _repay(tokenId);
  }

  //function batchRepay(uint256[] tokens, uint256[] values) external payable {}

  function pause() external override onlyOwner {
    isPaused = !isPaused;
  }

  function charge(Loan.Charge[] calldata charges) external override onlyOwner {
    uint256 chargeIndex = 0;

    while (chargeIndex < charges.length) {
      Loan.Info storage loan = loans.get(charges[chargeIndex].owner, charges[chargeIndex].tokenId);
      bool shouldLiquidate = false;

      if (block.timestamp > loan.expirationTimestamp) {
        shouldLiquidate = true;
      }

      if (block.timestamp >= loan.installments[loan.installments.length - loan.installmentsRemaining].dueBy) {
        loan.installmentsRemaining -= 1;
        if (loan.installmentsRemaining == 0 || loan.installmentsRemaining < loan.installments.length) {
          shouldLiquidate = true;
        }
      }

      if (shouldLiquidate) {
        book[charges[chargeIndex].tokenId] = false;
        delete loans[keccak256(abi.encodePacked(charges[chargeIndex].owner, charges[chargeIndex].tokenId))];
        _release(charges[chargeIndex].tokenId);

        emit LoanEvent(charges[chargeIndex].tokenId, uint8(LOAN_EVENT.CLOSED));

        // trigger charge event
        // trigger liquidate function
      } else {
        loan.lastCharge = block.timestamp;
        uint256 _interest = loan.applyInterest();
        loan.interest += _interest;
        // emit event
        //loan.installments[0].amount += interest;
      }

      chargeIndex += 1;
    }
  }

  function liquidate(bytes calldata assetData, bytes calldata agentData)
    external
    override
    onlyOwner
  {}

  function collapse() external override onlyOwner {}

  function approveExchange(address exchange, bool state)
    external
    override
    onlyOwner
  {
    IERC721Minimal(token0).setApprovalForAll(exchange, state);
  }

  function setup(
    uint64 _coverageRatio,
    uint64 _interestRate,
    uint64 _fee,
    uint32 _chargeInterval,
    uint32 _loanTerm,
    uint32 _paymentFrequency,
    uint128 _minDeposit,
    uint256 _minLiquidity
  ) external override onlyOwner {
    coverageRatio = _coverageRatio;
    interestRate = _interestRate;
    fee = _fee;
    chargeInterval = _chargeInterval;
    loanTerm = _loanTerm;
    paymentFrequency = _paymentFrequency;
    minDeposit = _minDeposit;
    minLiquidity = _minLiquidity;
  }

  function getLoan(address borrower, uint256 tokenId)
    external
    view
    returns (Loan.Info memory)
  {
    return loans.get(borrower, tokenId);
  }

  receive() external payable {}
}
