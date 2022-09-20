// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "contracts/LeverV1Factory.sol";
import "contracts/LeverV1Pool.sol";
import "contracts/interfaces/ILeverV1Pool.sol";
import "contracts/AgentRouter.sol";
import "contracts/agents/LooksRareAgent.sol";
import "contracts/agents/OpenSeaAgent.sol";

import "contracts/tokens/interfaces/IERC20Minimal.sol";
import "contracts/tokens/interfaces/IERC721Minimal.sol";

import "contracts/lib/ConversionMath.sol";

error Error_InsufficientBalance();
error Error_InsufficientLiquidity();
error Error_InsufficientContribution();
error Error_ExistingLoan();
error DuplicatePool();
error Unauthorized();

contract LeverV1PoolTest is Test {
  using stdStorage for StdStorage;

  using ConversionMath for uint256;
  using Loan for mapping(bytes32 => Loan.Info);
  using Loan for Loan.Info;

  bytes constant MAGIC_LR_BORROW_DATA =
    hex"00000000000000000000000000000000000000000000000000000000000012aa00000000000000000000000000000000000000000000000437468af4f62100000000000000000000000000000000000000000000000000000000000000000001";
  bytes constant MAGIC_LR_PURCHASE_DATA =
    hex"000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000010000000000000000000000007ce30498e564f081ca65a226f44b1751f93a0f82000000000000000000000000bc4ca0eda7647a8ab7c2061c2e118a18a936f13d00000000000000000000000000000000000000000000000437468af4f621000000000000000000000000000000000000000000000000000000000000000012aa000000000000000000000000000000000000000000000000000000000000000100000000000000000000000056244bb70cbd3ea9dc8007399f61dfc065190031000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000631d14ae000000000000000000000000000000000000000000000000000000006344a168000000000000000000000000000000000000000000000000000000000000254e0000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001c19bf6d654eb32186dafba53b92d3e1f63d357ff14684e0c74e98ae3ee42041b15fddbb29b58a0ba2ef3a044c122a8d3315cef3286d026b30072242c19dd81bb60000000000000000000000000000000000000000000000000000000000000000";
  uint256 constant MAGIC_LR_BLOCK = 15_541_900;

  address constant OS_EXCHANGE = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
  address constant LR_EXCHANGE = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
  address constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
  address constant DOODLE = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
  address constant MOONBIRD = 0x23581767a106ae21c074b2276D25e5C3e136a68b;

  LeverV1Factory public FACTORY;
  address payable public BAYC_POOL;
  address payable public DOODLE_POOL;
  address payable public AGENT_ROUTER;
  address payable public ASSET_MANAGER =
    payable(0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051);

  mapping(address => uint256) _multiDistribTokenBalance;

  struct BorrowData {
    uint256 tokenId;
    uint256 price;
    uint8 agentId;
  }

  receive() external payable {}

  function _deployPool(address collection)
    internal
    returns (address payable pool)
  {
    pool = payable(FACTORY.deployPool(AGENT_ROUTER, ASSET_MANAGER, collection));
    AgentRouter _agentRouter = AgentRouter(AGENT_ROUTER);
    ILeverV1Pool _pool = ILeverV1Pool(pool);

    ILeverV1Pool(pool).setup(
      0.4 ether,
      0.045 ether,
      0.15 ether, // 15%
      86400, // daily
      2419200, // 4wks
      604800, // weekly
      0.05 ether,
      1 ether
    );

    // _agentRouter.setApprovalForAll(pool, collection, true);
    // _agentRouter.setApprovalForAll(OS_EXCHANGE, collection, true);
    // _agentRouter.setApprovalForAll(LR_EXCHANGE, collection, true);

    // _pool.approveExchange(OS_EXCHANGE, true);
    // _pool.approveExchange(LR_EXCHANGE, true);
  }

  function _deposit(address payable pool, uint256 amount) internal {
    ILeverV1Pool(pool).deposit{ value: amount }();
  }

  function _collect(address payable pool, uint256 amount) internal {
    ILeverV1Pool(pool).collect(amount);
  }

  function _borrow(
    address payable pool,
    uint256 amount,
    bytes memory borrowData,
    bytes memory purchaseData
  ) internal {
    ILeverV1Pool(pool).borrow{ value: amount }(borrowData, purchaseData);
  }

  function _repay(
    address payable pool,
    uint256 amount,
    uint256 tokenId
  ) internal {
    ILeverV1Pool(pool).repay{ value: amount }(tokenId);
  }

  function _charge(
    address payable pool,
    Loan.Charge[] memory charges
  ) internal {
    ILeverV1Pool(pool).charge(charges);
  }

  // function repay(
  //   LeverV1Pool pool,
  //   uint256 amount,
  //   uint256 tokenId
  // ) internal {
  //   pool.repay{ value: amount }(tokenId);
  // }

  function setUp() public {
    FACTORY = new LeverV1Factory();
    AgentRouter agentRouter = new AgentRouter(address(FACTORY));
    agentRouter.setAgent(
      0,
      "OPENSEA",
      address(new OpenSeaAgent(0, address(agentRouter)))
    );
    agentRouter.setAgent(
      1,
      "LOOKSRARE",
      address(new LooksRareAgent(1, address(agentRouter)))
    );

    AGENT_ROUTER = payable(address(agentRouter));
    BAYC_POOL = _deployPool(BAYC);
    DOODLE_POOL = _deployPool(DOODLE);
  }

  function testDeployUniquePool() public {
    _deployPool(MOONBIRD);
    assertEq(FACTORY.collectionExists(MOONBIRD), true);
  }

  function testFailDeployDuplicatePool() public {
    _deployPool(BAYC);
  }

  function testFailDeployPoolNotOwner(address rand) public {
    vm.assume(rand != address(0));
    vm.assume(rand != FACTORY.owner());
    //vm.expectRevert(Unauthorized.selector);
    vm.prank(rand);
    _deployPool(MOONBIRD);
  }

  function testSingleDeposit(address depositor, uint256 amount) public {
    vm.assume(depositor != address(0));
    ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);
    vm.assume(amount >= baycPool.minDeposit());
    IERC20Minimal token = IERC20Minimal(baycPool.token());

    startHoax(depositor, amount);
    _deposit(BAYC_POOL, amount);
    vm.stopPrank();

    assertEq(token.totalSupply(), amount);
    assertEq(token.balanceOf(depositor), amount);
  }

  function testFailInsufficientDeposit(address depositor, uint256 amount)
    public
  {
    vm.assume(depositor != address(0));
    ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);
    vm.assume(amount < baycPool.minDeposit());

    startHoax(depositor, amount);
    _deposit(BAYC_POOL, amount);
    vm.stopPrank();
  }

  function testMultiDeposit(uint256[10] memory deposits) public {
    address[10] memory depositors;
    ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);
    IERC20Minimal token = IERC20Minimal(baycPool.token());
    uint256 minDeposit = baycPool.minDeposit();

    for (uint256 i = 0; i < deposits.length; i++) {
      deposits[i] = bound(deposits[i], minDeposit, 1000 ether);
      depositors[i] = address(uint160(deposits[i]));
    }

    for (uint256 i = 0; i < deposits.length; i++) {
      uint256 tokenAmount = deposits[i].computeTokenConversion(
        baycPool.truePoolValue() + deposits[i],
        token.totalSupply()
      );

      _multiDistribTokenBalance[depositors[i]] += tokenAmount;

      startHoax(depositors[i], deposits[i]);
      _deposit(BAYC_POOL, deposits[i]);
      vm.stopPrank();

      assertEq(
        token.balanceOf(depositors[i]),
        _multiDistribTokenBalance[depositors[i]]
      );
    }
  }

  function testCollect(address depositor, uint256 amount) public {
    // 0x1276ce79477787390E86877A0CD144b85b20e134 - broken
    vm.assume(depositor != address(0));
    ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);
    vm.assume(amount > baycPool.minDeposit());
    IERC20Minimal token = IERC20Minimal(baycPool.token());
    uint256 minDeposit = baycPool.minDeposit();

    amount = bound(amount, minDeposit, 1000 ether);

    startHoax(depositor, amount);
    _deposit(BAYC_POOL, amount);
    // collect
    uint256 balance = BAYC_POOL.balance;
    uint256 tokensOwned = token.balanceOf(depositor);
    uint256 toCollect = tokensOwned / 2;
    uint256 totalSupply = token.totalSupply();
    uint256 estimatedEthCollected = toCollect.computeEthConversion(
      baycPool.truePoolValue(),
      totalSupply
    );
    _collect(BAYC_POOL, toCollect);
    vm.stopPrank();

    assertEq(token.totalSupply(), totalSupply - toCollect);
    assertEq(token.balanceOf(depositor), tokensOwned - toCollect);
    assertEq(BAYC_POOL.balance, balance - estimatedEthCollected);
  }

  function testFailCollectInvalid(address depositor, uint256 amount) public {
    vm.assume(depositor != address(0));
    ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);
    vm.assume(amount > baycPool.minDeposit());
    IERC20Minimal token = IERC20Minimal(baycPool.token());

    startHoax(depositor, amount);
    _deposit(BAYC_POOL, amount);
    _collect(BAYC_POOL, token.balanceOf(depositor) * 2);
    vm.stopPrank();
  }

  function testDryPool(uint256[10] memory deposits) public {
    address[10] memory depositors;
    ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);
    IERC20Minimal token = IERC20Minimal(baycPool.token());
    uint256 minDeposit = baycPool.minDeposit();

    for (uint256 i = 0; i < deposits.length; i++) {
      deposits[i] = bound(deposits[i], minDeposit, 1000 ether);
      depositors[i] = address(uint160(deposits[i]));

      startHoax(depositors[i], deposits[i]);
      _deposit(BAYC_POOL, deposits[i]);
      vm.stopPrank();
    }

    for (uint256 i = 0; i < depositors.length; i++) {
      uint256 tokenBalance = token.balanceOf(depositors[i]);
      if (tokenBalance == 0) {
        continue;
      }

      vm.startPrank(depositors[i]);
      _collect(BAYC_POOL, tokenBalance);
      vm.stopPrank();
    }

    assertEq(token.totalSupply(), 0);
    assertEq(BAYC_POOL.balance, 0);
    assertEq(baycPool.truePoolValue(), 0);
  }

  function testLoanOriginationLooksRare() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);
    IERC721Minimal token0 = IERC721Minimal(baycPool.token0());
    IERC721Minimal token1 = IERC721Minimal(baycPool.token1());

    uint256 depositorContribution = (baycPool.coverageRatio() *
      _borrowData.price) / 1 ether;
    uint256 borrowerContribution = _borrowData.price -
      depositorContribution +
      baycPool.minLiquidity();
    uint256 expectedRemaining = baycPool.minLiquidity();
    // uint256 expectedRemaining = borrowerContribution -
    //   (_borrowData.price - depositorContribution);

    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );
    vm.stopPrank();

    assertEq(BAYC_POOL.balance, expectedRemaining);
    assertEq(token0.balanceOf(BAYC_POOL), 1);
    assertEq(token1.totalSupply(), 1);
    assertEq(token1.balanceOf(borrower), 1);

    // check loan event emission

    // check loan struct
  }

  // function testLoanOriginationOpenSea()
  //   public
  // {
  //   address depositor = address(1);
  //   address borrower = address(2);
  //   uint256 BLOCK_NUM = 15_540_550;
  //   bytes
  //     memory MAGIC_BORROW_DATA = hex"000000000000000000000000000000000000000000000000000000000000183e000000000000000000000000000000000000000000000003fecaff854a4a00000000000000000000000000000000000000000000000000000000000000000000";
  //   bytes
  //     memory MAGIC_PURCHASE_DATA = hex"0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000003fecaff854a4a0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000975a416559f1f8b879b4f51b97e86972f8d7f87e000000000000000000000000004c00500000ad104d7dbd00e3ae0a5c00560c00000000000000000000000000bc4ca0eda7647a8ab7c2061c2e118a18a936f13d000000000000000000000000000000000000000000000000000000000000183e0000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000631f3a9300000000000000000000000000000000000000000000000000000000633337a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000009722c7fcbc5a5d0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000024000000000000000000000000000000000000000000000000000000000000003200000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000003cba73f8b6cf98000000000000000000000000000975a416559f1f8b879b4f51b97e86972f8d7f87e0000000000000000000000000000000000000000000000001991dffceea840000000000000000000000000000000a26b00c1f0df003000390027140000faa7190000000000000000000000000000000000000000000000001991dffceea84000000000000000000000000000a858ddc0445d8131dac4d1de01f834ffcba52ef10000000000000000000000000000000000000000000000000000000000000041e9879e6d9d69bcf36cbc7e5cfcb9c5a64dcd00f9d79c69a900c3d95ab5d4db7e155f62bcd74f4e48bc9de95425cb34003ed03dc5705d18aeacfb4c523d957beb1b00000000000000000000000000000000000000000000000000000000000000";

  //   vm.assume(depositor != address(0));
  //   vm.assume(borrower != address(0));
  //   BorrowData memory _borrowData = abi.decode(MAGIC_BORROW_DATA, (BorrowData));

  //   ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);
  //   IERC721Minimal token0 = IERC721Minimal(baycPool.token0());
  //   IERC721Minimal token1 = IERC721Minimal(baycPool.token1());

  //   uint256 amountToContribute = (baycPool.coverageRatio() *
  //     _borrowData.price) / 1 ether;
  //   uint256 amountToDeposit = _borrowData.price -
  //     amountToContribute +
  //     baycPool.minLiquidity();
  //   // uint256 expectedRemaining = amountToDeposit -
  //   //   (_borrowData.price - amountToContribute);
  //   uint256 expectedRemaining = baycPool.minLiquidity();

  //   vm.roll(BLOCK_NUM);
  //   startHoax(depositor, amountToDeposit);
  //   _deposit(BAYC_POOL, amountToDeposit);
  //   vm.stopPrank();

  //   vm.roll(BLOCK_NUM);
  //   startHoax(borrower, amountToContribute);
  //   _borrow(
  //     BAYC_POOL,
  //     amountToContribute,
  //     MAGIC_BORROW_DATA,
  //     MAGIC_PURCHASE_DATA
  //   );
  //   vm.stopPrank();

  //   assertEq(BAYC_POOL.balance, expectedRemaining);
  //   assertEq(token0.balanceOf(BAYC_POOL), 1);
  //   assertEq(token1.totalSupply(), 1);
  //   assertEq(token1.balanceOf(borrower), 1);
  // }

  function testFailLoanLowLiquidity() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);

    uint256 depositorContribution = baycPool.minLiquidity() / 2;
    uint256 borrowerContribution = 1 ether;

    // deposit
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    // borrow
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution);
    //vm.expectRevert(Error_InsufficientLiquidity.selector);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );
    vm.stopPrank();
  }

  function testFailLoanLowContribution() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    uint256 depositorContribution = _borrowData.price * 2;
    uint256 borrowerContribution = 0.1 ether;

    // deposit
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    // borrow
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution);
    //vm.expectRevert(Error_InsufficientContribution.selector);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );
    vm.stopPrank();
  }

  // Fail loan origination if loan exists
  function testFailLoanExistingLoan() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);

    uint256 depositorContribution = (baycPool.coverageRatio() *
      _borrowData.price) / 1 ether;
    uint256 borrowerContribution = _borrowData.price -
      depositorContribution +
      baycPool.minLiquidity();

    // deposit
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    // borrow
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );
    vm.stopPrank();

    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, borrowerContribution);
    //vm.expectRevert(Error_ExistingLoan.selector);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );
    vm.stopPrank();
  }

  function testFailLoanAssetInvalid() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    ILeverV1Pool baycPool = ILeverV1Pool(BAYC_POOL);
    IERC721Minimal token0 = IERC721Minimal(baycPool.token0());
    IERC721Minimal token1 = IERC721Minimal(baycPool.token1());

    uint256 depositorContribution = _borrowData.price;
    uint256 borrowerContribution = _borrowData.price / 2;
    uint256 expectedRemaining = baycPool.minLiquidity();

    vm.roll(MAGIC_LR_BLOCK - 500_000);
    vm.warp(1_662_063_126);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    vm.roll(MAGIC_LR_BLOCK - 500_000);
    vm.warp(1_662_063_126);
    startHoax(borrower, borrowerContribution);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );
    vm.stopPrank();
  }

  function testRepaymentPartial() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    vm.label(depositor, "alice");
    vm.label(borrower, "bob");

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);

    IERC721Minimal token0 = IERC721Minimal(baycPool.token0());
    IERC721Minimal token1 = IERC721Minimal(baycPool.token1());

    uint256 depositorContribution = (baycPool.coverageRatio() *
      _borrowData.price) / 1 ether;
    uint256 borrowerContribution = _borrowData.price -
      depositorContribution +
      baycPool.minLiquidity();
    uint256 repaymentContribution = 1 ether;

    // deposit
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    // borrow
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution + repaymentContribution);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );

    // repay
    uint256 preToken0Balance = token0.balanceOf(borrower);
    uint256 preToken1Balance = token1.balanceOf(borrower);

    Loan.Info memory _loan = baycPool.getLoan(borrower, _borrowData.tokenId);
    uint256 loanPrincipal = _loan.principal;

    vm.roll(MAGIC_LR_BLOCK + 1);

    _repay(BAYC_POOL, repaymentContribution, _borrowData.tokenId);

    // loan n nft status change
    _loan = baycPool.getLoan(borrower, _borrowData.tokenId);

    assertEq(_loan.active, true);
    assertEq(_loan.principal, loanPrincipal - repaymentContribution);
    assertEq(
      _loan.installments[0].amount,
      _loan.installments[_loan.installments.length - 1].amount -
        repaymentContribution
    );
    assertEq(token0.balanceOf(borrower), preToken0Balance);
    assertEq(token1.balanceOf(borrower), preToken1Balance);

    vm.stopPrank();
  }

  function testFailRepaymentOverflow() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    vm.label(depositor, "alice");
    vm.label(borrower, "bob");

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);

    uint256 depositorContribution = (baycPool.coverageRatio() *
      _borrowData.price) / 1 ether;
    uint256 borrowerContribution = _borrowData.price -
      depositorContribution +
      baycPool.minLiquidity();
    uint256 repaymentContribution = borrowerContribution;

    // deposit
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    // borrow
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution + repaymentContribution);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );

    // repay
    vm.roll(MAGIC_LR_BLOCK + 1);
    _repay(BAYC_POOL, repaymentContribution, _borrowData.tokenId);
    vm.stopPrank();
  }

  function testRepaymentComplete() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    vm.label(depositor, "alice");
    vm.label(borrower, "bob");

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);

    IERC721Minimal token0 = IERC721Minimal(baycPool.token0());
    IERC721Minimal token1 = IERC721Minimal(baycPool.token1());

    uint256 depositorContribution = (baycPool.coverageRatio() *
      _borrowData.price) / 1 ether;
    uint256 borrowerContribution = _borrowData.price -
      depositorContribution +
      baycPool.minLiquidity();
    uint256 repaymentContribution = _borrowData.price - borrowerContribution;

    // deposit
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    // borrow
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution + repaymentContribution);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );

    // repay
    uint256 preToken0Balance = token0.balanceOf(borrower);
    uint256 preToken1Balance = token1.balanceOf(borrower);
    uint256 preToken1TotalSupply = token1.totalSupply();

    vm.roll(MAGIC_LR_BLOCK + 1);

    _repay(BAYC_POOL, repaymentContribution, _borrowData.tokenId);

    // check
    Loan.Info memory _loan = baycPool.getLoan(borrower, _borrowData.tokenId);
    
    assertEq(_loan.active, false);
    assertEq(_loan.principal, 0);
    assertEq(token0.balanceOf(borrower), preToken0Balance + 1);
    assertEq(token1.balanceOf(borrower), preToken1Balance - 1);
    assertEq(token1.totalSupply(), preToken1TotalSupply - 1);

    vm.stopPrank();
  }

  function testInterestCharged() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    vm.label(depositor, "alice");
    vm.label(borrower, "bob");

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);

    IERC721Minimal token0 = IERC721Minimal(baycPool.token0());
    IERC721Minimal token1 = IERC721Minimal(baycPool.token1());

    uint256 depositorContribution = (baycPool.coverageRatio() *
      _borrowData.price) / 1 ether;
    uint256 borrowerContribution = _borrowData.price -
      depositorContribution +
      baycPool.minLiquidity();
    uint256 repaymentContribution = _borrowData.price - borrowerContribution;

    // deposit
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    // borrow
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution + repaymentContribution);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );
    vm.stopPrank();

    vm.roll(MAGIC_LR_BLOCK + 1);
    Loan.Charge[] memory _charges = new Loan.Charge[](1);
    Loan.Info memory _loan = baycPool.getLoan(borrower, _borrowData.tokenId);
    uint256 prePrincipal = _loan.principal;
    uint256 preInterest = _loan.interest;
    _charges[0] = Loan.Charge(
      borrower,
      _borrowData.tokenId
    );
    baycPool.charge(_charges);
    _loan = baycPool.getLoan(borrower, _borrowData.tokenId);

    assertEq(_loan.interest - preInterest, (prePrincipal * _loan.interestRate) / 1 ether);
    vm.stopPrank();
  }

  function testInterestChargedPartialRepayment() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    vm.label(depositor, "alice");
    vm.label(borrower, "bob");

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);

    IERC721Minimal token0 = IERC721Minimal(baycPool.token0());
    IERC721Minimal token1 = IERC721Minimal(baycPool.token1());

    uint256 depositorContribution = (baycPool.coverageRatio() *
      _borrowData.price) / 1 ether;
    uint256 borrowerContribution = _borrowData.price -
      depositorContribution +
      baycPool.minLiquidity();
    uint256 repaymentContribution = 1 ether;

    // deposit
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    // borrow
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );
    vm.stopPrank();

    vm.roll(MAGIC_LR_BLOCK + 1);
    Loan.Charge[] memory _charges = new Loan.Charge[](1);

    _charges[0] = Loan.Charge(
      borrower,
      _borrowData.tokenId
    );

    baycPool.charge(_charges);
    vm.stopPrank();

    Loan.Info memory _loan = baycPool.getLoan(borrower, _borrowData.tokenId);
    uint256 prePrincipal = _loan.principal;
    uint256 preInterest = _loan.interest;

    vm.roll(MAGIC_LR_BLOCK + 2);
    startHoax(borrower, repaymentContribution);
    
    _loan = baycPool.getLoan(borrower, _borrowData.tokenId);
    _repay(BAYC_POOL, repaymentContribution, _borrowData.tokenId);
    
    _loan = baycPool.getLoan(borrower, _borrowData.tokenId);

    assertEq(_loan.interest, 0);
    assertEq(_loan.principal, prePrincipal + preInterest - repaymentContribution);
    vm.stopPrank();
  }

  // function testInterestChargedMultiLoan() public {}

  function testInterestChargedCompleteCycle() public {
    address depositor = address(1);
    address borrower = address(2);

    vm.assume(depositor != address(0));
    vm.assume(borrower != address(0));

    vm.label(depositor, "alice");
    vm.label(borrower, "bob");

    BorrowData memory _borrowData = abi.decode(
      MAGIC_LR_BORROW_DATA,
      (BorrowData)
    );

    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);

    IERC721Minimal token0 = IERC721Minimal(baycPool.token0());
    IERC721Minimal token1 = IERC721Minimal(baycPool.token1());

    uint256 depositorContribution = (baycPool.coverageRatio() *
      _borrowData.price) / 1 ether;
    uint256 borrowerContribution = _borrowData.price -
      depositorContribution +
      baycPool.minLiquidity();

    // deposit
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(depositor, depositorContribution);
    _deposit(BAYC_POOL, depositorContribution);
    vm.stopPrank();

    // borrow
    vm.roll(MAGIC_LR_BLOCK);
    startHoax(borrower, borrowerContribution + 1 ether);
    _borrow(
      BAYC_POOL,
      borrowerContribution,
      MAGIC_LR_BORROW_DATA,
      MAGIC_LR_PURCHASE_DATA
    );

    // uint256 preToken0Balance = token0.balanceOf(borrower);
    // uint256 preToken1Balance = token1.balanceOf(borrower);
    // uint256 preToken1TotalSupply = token1.totalSupply();

    _repay(BAYC_POOL, 1 ether, _borrowData.tokenId);

    vm.stopPrank();

    vm.roll(MAGIC_LR_BLOCK + 1);
    Loan.Charge[] memory _charges = new Loan.Charge[](1);

    _charges[0] = Loan.Charge(
      borrower,
      _borrowData.tokenId
    );

    //Loan.Info memory _loan = baycPool.getLoan(borrower, _borrowData.tokenId);
    uint256 installmentsRemaining = baycPool.getLoan(borrower, _borrowData.tokenId).installmentsRemaining;
    vm.stopPrank();

    for (uint256 i = 0; i < installmentsRemaining; i++) {
      _charge(BAYC_POOL, _charges);
      //baycPool.charge(_charges);

      Loan.Info memory _inFlightLoan = baycPool.getLoan(borrower, _borrowData.tokenId);
      assertGt(_inFlightLoan.principal, 0);
      uint256 repaymentContribution = _inFlightLoan.installments[i].amount + _inFlightLoan.interest;

      vm.roll(MAGIC_LR_BLOCK + 2 + i);
      startHoax(borrower, repaymentContribution);
      _repay(BAYC_POOL, repaymentContribution, _borrowData.tokenId);
      vm.stopPrank();
    }

    Loan.Info memory _loan = baycPool.getLoan(borrower, _borrowData.tokenId);
    
    assertEq(_loan.active, false);
    assertEq(_loan.principal, 0);
    assertEq(token0.balanceOf(borrower), 1);
    assertEq(token1.balanceOf(borrower), 0);
    assertEq(token1.totalSupply(), 0);
  }

  // function testAssetLiquidation() public {}

  // function testAssetLiquidationPartialRepayment() public {}
}
