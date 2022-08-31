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

  uint128 public override interestAccumulated;
  uint128 public override minDeposit;
  uint256 public override minLiquidity;
  uint256 public override truePoolValue;

  address public override agentRouter;
  address public override assetManager;

  uint32 lastCharge;
  bool isPaused;
  address owner;

  mapping(bytes32 => Loan.Info) public loans;
  mapping(uint256 => bool) public override book;

  // struct Params {
  //   uint64 coverageRatio;
  //   uint64 interestRate;
  //   uint32 chargeInterval;
  //   uint32 loanTerm;
  //   uint32 paymentFrequenc;
  //   uint128 interestAccumulated;
  //   uint128 minDeposit;
  //   uint256 minLiquidity;
  //   uint256 truepoolValue;
  //   address agentRouter;
  //   address assetManager;
  // }

  struct BorrowData {
    uint256 tokenId;
    uint256 price;
    uint8 agentId;
  }

  modifier notPaused() {
    require(isPaused == false, "Paused");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not Owner");
    _;
  }

  constructor(
    address _factory,
    address _token0,
    uint64 _coverageRatio,
    uint64 _interestRate,
    uint64 _fee,
    uint32 _chargeInterval,
    uint32 _loanTerm,
    uint32 _paymentFrequency,
    uint128 _minDeposit,
    uint256 _minLiquidity,
    address _agentRouter,
    address _assetManager
  ) {
    owner = msg.sender;
    factory = _factory;
    token0 = _token0;
    coverageRatio = _coverageRatio;
    interestRate = _interestRate;
    fee = _fee;
    chargeInterval = _chargeInterval;
    loanTerm = _loanTerm;
    paymentFrequency = _paymentFrequency;
    minDeposit = _minDeposit;
    minLiquidity = _minLiquidity;
    agentRouter = _agentRouter;
    assetManager = _assetManager;

    string memory tk0Symbol = IERC721Minimal(token0).symbol();
    string memory tkName = string(abi.encodePacked(tk0Symbol, "_LFI_LPT"));
    string memory tk1Name = string(abi.encodePacked(tk0Symbol, "_LFI_LPS"));

    token1 = address(
      new LeverV1ERC721(tk1Name, tk1Name, address(this), token0)
    );
    token = address(new LeverV1ERC20(tkName, tkName));
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

    Loan.Info storage loan = loans.get(msg.sender, _data.tokenId);
    uint256 balance = address(this).balance;

    if (
      _data.price >= balance + msg.value ||
      balance + msg.value - _data.price < minLiquidity
    ) {
      revert InsufficientLiquidity();
    }

    if ((msg.value * 1 ether) / _data.price < coverageRatio) {
      revert InsufficientContribution();
    }

    bool success = AgentRouter(agentRouter).purchase(_data.agentId, agentData);

    if (!success) {
      revert Unsuccessful();
    }

    LeverV1ERC721(token1).mint(msg.sender, _data.tokenId);
    uint256 principal = _data.price - msg.value;
    uint8 installmentCount = uint8(loanTerm / paymentFrequency);

    loan.active = true;
    loan.borrower = msg.sender;
    loan.expirationTimestamp = block.timestamp + loanTerm;
    loan.loanTerm = loanTerm;
    loan.principal = principal;
    loan.interest = 0;
    loan.interestRate = interestRate / 365;
    loan.chargeInterval = chargeInterval;
    loan.lastCharge = block.timestamp;
    loan.paymentFrequency = paymentFrequency;
    loan.repaymentAllowance = 0;
    loan.collateral = 0;

    for (uint256 i = 0; i < loan.installmentsRemaining; i++) {
      loan.installments[i].amount = principal / installmentCount;
      loan.installments[i].dueBy =
        block.timestamp +
        ((i + 1) * loan.paymentFrequency);
      //   Installment(
      //     principal / installmentCount,
      //     block.timestamp + ((i + 1) * loan.paymentFrequency)
      //   )
      // );
    }

    loan.installmentsRemaining = installmentCount;

    emit Borrow(msg.sender, msg.value, _data.tokenId);
  }

  function _repay(uint256 tokenId) internal {
    require(msg.value > 0, "Invalid repayment amount");
    Loan.Info storage loan = loans.get(msg.sender, tokenId);
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
    interestAccumulated += uint128(interest < msg.value ? interest : msg.value);

    loan.repay(msg.value);

    if (loan.principal == 0) {
      book[tokenId] = false;
      delete loans[keccak256(abi.encodePacked(msg.sender, tokenId))];
      _release(tokenId);

      emit LoanEvent(tokenId, uint8(LOAN_EVENT.CLOSED));
    }

    emit LoanRepay(tokenId, msg.value);
  }

  function deposit() external payable override {
    require(msg.value > minDeposit, "Insufficient contribution");
    IERC20Minimal _token0 = IERC20Minimal(token0);
    truePoolValue += msg.value;
    uint256 amountToMint = msg.value.computeTokenConversion(
      truePoolValue,
      _token0.totalSupply()
    );
    bool success = _token0.mintTo(msg.sender, amountToMint);

    if (!success) {
      revert Unsuccessful();
    }

    emit Deposit(msg.sender, msg.value, amountToMint);
  }

  function collect(uint256 amount) external override {
    IERC20Minimal tk = IERC20Minimal(token);
    require(amount > 0 && amount <= tk.balanceOf(msg.sender), "Invalid amount");
    uint256 amountToWithdraw = amount.computeEthConversion(
      truePoolValue,
      tk.totalSupply()
    );
    if (amountToWithdraw > address(this).balance) {
      revert InsufficientLiquidity();
    }
    truePoolValue -= amountToWithdraw;
    bool success = tk.burnFrom(msg.sender, amount);

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

  function charge() external override onlyOwner {}

  function liquidate(bytes calldata assetData, bytes calldata agentData)
    external
    override
    onlyOwner
  {}

  function collapse() external override onlyOwner {}

  receive() external payable {}
}
