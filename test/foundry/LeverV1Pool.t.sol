// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "@rari-capital/solmate/src/tokens/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
//import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "contracts/tokens/ERC721Minimal.sol";
import "contracts/LeverV1Factory.sol";
import "contracts/LeverV1Pool.sol";

error Error_InsufficientBalance();
error Error_InsufficientLiquidity();
error Error_InsufficientContribution();
error Error_ExistingLoan();
error DuplicatePool();
error Unauthorized();

contract LeverV1PoolTest is Test {
  using stdStorage for StdStorage;

  address constant OS_EXCHANGE = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
  address constant LR_EXCHANGE = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
  address constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
  address constant DOODLE = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
  address constant MOONBIRD = 0x23581767a106ae21c074b2276D25e5C3e136a68b;

  bytes constant MAGIC_ASSET_DATA =
    hex"0000000000000000000000000000000000000000000000000000000000000aca000000000000000000000000000000000000000000000004b4978c1d27e800000000000000000000000000000000000000000000000000000000000000000001";
  bytes constant MAGIC_PURCHASE_DATA =
    hex"0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000100000000000000000000000060a207e5b8babbed0528475094e585bbfe57c828000000000000000000000000bc4ca0eda7647a8ab7c2061c2e118a18a936f13d000000000000000000000000000000000000000000000004b4978c1d27e800000000000000000000000000000000000000000000000000000000000000000aca000000000000000000000000000000000000000000000000000000000000000100000000000000000000000056244bb70cbd3ea9dc8007399f61dfc065190031000000000000000000000000c02aaa39b223fe8d0a0e5c4f27ead9083c756cc200000000000000000000000000000000000000000000000000000000000000c0000000000000000000000000000000000000000000000000000000006307c5d900000000000000000000000000000000000000000000000000000000632f52cd000000000000000000000000000000000000000000000000000000000000254e0000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000001c36397c547b56c466da97fd23ddd9a2d98aa9229c96fef9511005df5b126ec431178162731a1cc087584fa721bbecc01f59eaafb688887401a251e5fa05fad1680000000000000000000000000000000000000000000000000000000000000000";

  LeverV1Factory public FACTORY;
  address payable public BAYC_POOL;
  address payable public DOODLE_POOL;

  mapping(address => uint256) _multiDistribTokenBalance;

  receive() external payable {}

  function deployPool(address collection)
    internal
    returns (address payable pool)
  {
    pool = payable(
      FACTORY.deployPool(
        collection,
        0.4 ether,
        0.045 ether,
        /* daily */
        86400,
        0.15 ether,
        /* 4wks */
        2419200,
        1 ether,
        0.05 ether,
        /*weekly*/
        604800
      )
    );
  }

  function deposit(LeverV1Pool pool, uint256 amount) internal {
    pool.deposit{ value: amount }();
  }

  function collect(LeverV1Pool pool, uint256 amount) internal {
    pool.collect(amount);
  }

  function borrow(
    LeverV1Pool pool,
    uint256 amount,
    bytes memory assetData,
    bytes memory purchaseData
  ) internal {
    pool.borrow{ value: amount }(assetData, purchaseData);
  }
  
  function repay(
    LeverV1Pool pool,
    uint256 amount,
    uint256 tokenId
  ) internal {
    pool.repay{ value: amount }(tokenId);
  }

  function ethToLiquidityToken(
    ERC20 token,
    uint256 currentBalance,
    uint256 contribution
  ) internal view returns (uint256 amount) {
    uint256 aPost = currentBalance + contribution;
    uint256 totalSupply = token.totalSupply();

    if (totalSupply == 0) {
      amount = contribution;
    } else {
      uint256 split = (contribution * 1 ether) / aPost;
      amount = (split * totalSupply) / (1 ether - split);
    }
  }

  function liquidityTokenToEth(
    ERC20 token,
    uint256 poolValue,
    uint256 amountRequested
  ) internal view returns (uint256 amount) {
    uint256 totalSupply = token.totalSupply();
    amount =
      (((amountRequested * 1 ether) / totalSupply) * poolValue) /
      1 ether;
  }

  function setUp() public {
    FACTORY = new LeverV1Factory();
    BAYC_POOL = deployPool(BAYC);
    DOODLE_POOL = deployPool(DOODLE);
  }

  function testDeployNewPool() public {
    deployPool(MOONBIRD);
    assertEq(FACTORY.collectionExists(MOONBIRD), true);
  }

  function testDeployDuplicatePool() public {
    vm.expectRevert(DuplicatePool.selector);
    deployPool(BAYC);
  }

  function testDeployPoolAsNotOwner() public {
    vm.expectRevert(Unauthorized.selector);
    vm.prank(address(0));
    deployPool(MOONBIRD);
  }

  function testPoolDepositAndTokenDistribution(
    address depositor,
    uint256 amount
  ) public {
    vm.assume(depositor != address(0));
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    uint256 minDeposit = baycPool.minDeposit();

    amount = bound(amount, minDeposit, 1000 ether);

    startHoax(depositor, amount);
    deposit(baycPool, amount);
    vm.stopPrank();

    assertEq(poolToken.totalSupply(), amount);
    assertEq(poolToken.balanceOf(depositor), amount);
  }

  function testInsufficientDepositAmount(address depositor, uint256 amount)
    public
  {
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    vm.assume(amount < baycPool.minDeposit());
    vm.assume(depositor != address(0));

    startHoax(depositor, amount);
    vm.expectRevert(Error_InsufficientBalance.selector);
    deposit(baycPool, amount);
    vm.stopPrank();
  }

  function testPoolMultiDepositAndTokenDistribution(
    uint256[10] memory amounts,
    address[10] memory depositors
  ) public {
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    uint256 minDeposit = baycPool.minDeposit();

    for (uint256 i = 0; i < amounts.length; i++) {
      amounts[i] = bound(amounts[i], minDeposit, 1000 ether);
      depositors[i] = address(uint160(amounts[i]));
    }

    for (uint256 i = 0; i < amounts.length; i++) {
      uint256 liquidityTokensOwned = ethToLiquidityToken(
        poolToken,
        BAYC_POOL.balance,
        amounts[i]
      );

      _multiDistribTokenBalance[depositors[i]] += liquidityTokensOwned;

      startHoax(depositors[i], amounts[i] + 0.1 ether);
      deposit(baycPool, amounts[i]);
      vm.stopPrank();

      assertEq(
        poolToken.balanceOf(depositors[i]),
        _multiDistribTokenBalance[depositors[i]]
      );
    }
  }

  function testPoolCollectAndTokenDistribution(
    address depositor,
    uint256 amount
  ) public {
    // 0x1276ce79477787390E86877A0CD144b85b20e134 - broken address
    vm.assume(depositor != address(0));
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    uint256 minDeposit = baycPool.minDeposit();

    amount = bound(amount, minDeposit, 1000 ether);

    startHoax(depositor, amount);
    // deposit
    uint256 liquidityTokensOwned = ethToLiquidityToken(
      poolToken,
      BAYC_POOL.balance,
      amount
    );
    deposit(baycPool, amount);
    uint256 preTotalSupply = poolToken.totalSupply();
    uint256 depositorTokenBalance = poolToken.balanceOf(depositor);
    assertEq(preTotalSupply, liquidityTokensOwned);
    assertEq(depositorTokenBalance, liquidityTokensOwned);
    // collect
    uint256 preBalance = BAYC_POOL.balance;
    uint256 amountToCollect = depositorTokenBalance / 2;
    uint256 ethToCollect = liquidityTokenToEth(
      poolToken,
      baycPool.truePoolValue(),
      amountToCollect
    );
    console.log(preBalance);
    console.log(amountToCollect);
    console.log(ethToCollect);
    collect(baycPool, amountToCollect);
    vm.stopPrank();
    uint256 postBalance = BAYC_POOL.balance;
    assertEq(poolToken.totalSupply(), preTotalSupply - amountToCollect);
    assertEq(
      poolToken.balanceOf(depositor),
      depositorTokenBalance - amountToCollect
    );
    assertEq(preBalance - ethToCollect, postBalance);
  }

  function testPoolCollectInvalidCollectionAmount(
    address depositor,
    uint256 amount
  ) public {
    vm.assume(depositor != address(0));
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    uint256 minDeposit = baycPool.minDeposit();

    amount = bound(amount, minDeposit, 1000 ether);

    startHoax(depositor, amount);
    // deposit
    deposit(baycPool, amount);
    uint256 depositorTokenBalance = poolToken.balanceOf(depositor);
    // collect
    uint256 amountToCollect = depositorTokenBalance * 2;
    vm.expectRevert(Error_InsufficientBalance.selector);
    collect(baycPool, amountToCollect);
    vm.stopPrank();
  }

  function testPoolDryAndTokenDistribution(
    uint256[10] memory amounts,
    address[10] memory depositors
  ) public {
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    uint256 minDeposit = baycPool.minDeposit();

    for (uint256 i = 0; i < amounts.length; i++) {
      amounts[i] = bound(amounts[i], minDeposit, 1000 ether);
      depositors[i] = address(uint160(amounts[i]));
    }

    // deposits
    for (uint256 i = 0; i < amounts.length; i++) {
      uint256 liquidityTokensOwned = ethToLiquidityToken(
        poolToken,
        BAYC_POOL.balance,
        amounts[i]
      );

      _multiDistribTokenBalance[depositors[i]] += liquidityTokensOwned;

      startHoax(depositors[i], amounts[i] + 0.1 ether);
      deposit(baycPool, amounts[i]);
      vm.stopPrank();

      assertEq(
        poolToken.balanceOf(depositors[i]),
        _multiDistribTokenBalance[depositors[i]]
      );
    }

    // collection
    for (uint256 i = 0; i < depositors.length; i++) {
      if (_multiDistribTokenBalance[depositors[i]] == 0) {
        continue;
      }
      uint256 prePoolBalance = BAYC_POOL.balance;
      uint256 amountToCollect = poolToken.balanceOf(depositors[i]);
      _multiDistribTokenBalance[depositors[i]] = 0;
      uint256 ethToCollect = liquidityTokenToEth(
        poolToken,
        baycPool.truePoolValue(),
        amountToCollect
      );
      vm.startPrank(depositors[i]);
      collect(baycPool, amountToCollect);
      vm.stopPrank();

      assertEq(poolToken.balanceOf(depositors[i]), 0);
      assertEq(prePoolBalance - ethToCollect, BAYC_POOL.balance);
    }
  }

  function testLoanOriginationWithValidParams(
    address lender, 
    address borrower
  ) public {
    BorrowAssetData memory _assetData = abi.decode(
      MAGIC_ASSET_DATA,
      (BorrowAssetData)
    );

    //vm.warp(1661311696);
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    ERC721Minimal originalCollection = ERC721Minimal(
      baycPool.originalCollection()
    );
    ERC721Minimal syntheticCollection = ERC721Minimal(
      baycPool.syntheticCollection()
    );

    uint256 lenderContribution = _assetData.price * 2;
    uint256 borrowerContribution = (baycPool.collateralCoverageRatio() *
      _assetData.price) /
      1 ether +
      1 ether;

    vm.assume(lender != address(0));
    vm.assume(borrower != address(0));

    // deposit
    vm.roll(15_411_340);
    startHoax(lender, lenderContribution);
    deposit(baycPool, lenderContribution);
    vm.stopPrank();
    assertEq(BAYC_POOL.balance, lenderContribution);
    assertEq(poolToken.balanceOf(lender), lenderContribution);

    // borrow
    vm.roll(15_411_340);
    startHoax(borrower, borrowerContribution);
    //baycPool.borrow{ value: 50 ether }(MAGIC_ASSET_DATA, MAGIC_PURCHASE_DATA);
    borrow(
      baycPool,
      borrowerContribution,
      MAGIC_ASSET_DATA,
      MAGIC_PURCHASE_DATA
    );
    vm.stopPrank();
    uint256 expectedRemaining = lenderContribution -
      (_assetData.price - borrowerContribution);
    assertEq(BAYC_POOL.balance, expectedRemaining);

    // check synthetic asset count + ownership
    assertEq(originalCollection.balanceOf(BAYC_POOL), 1);
    assertEq(syntheticCollection.totalSupply(), 1);
    assertEq(syntheticCollection.balanceOf(borrower), 1);

    // check loan event emission

    // check loan struct
  }

  function testLoanOriginationWithInsufficientLiquidity(
    address lender,
    address borrower
  ) public {
    //vm.warp(1661311696);
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());

    uint256 lenderContribution = baycPool.minLiquidity() / 2;
    uint256 borrowerContribution = 1 ether;

    vm.assume(lender != address(0));
    vm.assume(borrower != address(0));

    // deposit
    vm.roll(15_411_340);
    startHoax(lender, lenderContribution);
    deposit(baycPool, lenderContribution);
    vm.stopPrank();
    assertEq(BAYC_POOL.balance, lenderContribution);
    assertEq(poolToken.balanceOf(lender), lenderContribution);

    // borrow
    vm.roll(15_411_340);
    startHoax(borrower, borrowerContribution);
    vm.expectRevert(Error_InsufficientLiquidity.selector);
    borrow(
      baycPool,
      borrowerContribution,
      MAGIC_ASSET_DATA,
      MAGIC_PURCHASE_DATA
    );
    vm.stopPrank();
  }

  function testLoanOriginationWithInsufficientContribution(
    address lender,
    address borrower
  ) public {
    BorrowAssetData memory _assetData = abi.decode(
      MAGIC_ASSET_DATA,
      (BorrowAssetData)
    );

    //vm.warp(1661311696);
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());

    uint256 lenderContribution = _assetData.price * 2;
    uint256 borrowerContribution = 0 ether;

    vm.assume(lender != address(0));
    vm.assume(borrower != address(0));

    // deposit
    vm.roll(15_411_340);
    startHoax(lender, lenderContribution);
    deposit(baycPool, lenderContribution);
    vm.stopPrank();
    assertEq(BAYC_POOL.balance, lenderContribution);
    assertEq(poolToken.balanceOf(lender), lenderContribution);

    // borrow
    vm.roll(15_411_340);
    startHoax(borrower, borrowerContribution);
    vm.expectRevert(Error_InsufficientContribution.selector);
    borrow(
      baycPool,
      borrowerContribution,
      MAGIC_ASSET_DATA,
      MAGIC_PURCHASE_DATA
    );
    vm.stopPrank();
  }

  function testLoanOriginationOnActiveLoan(
    address lender, 
    address borrower
  ) public {
    BorrowAssetData memory _assetData = abi.decode(
      MAGIC_ASSET_DATA,
      (BorrowAssetData)
    );

    //vm.warp(1661311696);
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());

    uint256 lenderContribution = _assetData.price * 2;
    uint256 borrowerContribution = (baycPool.collateralCoverageRatio() *
      _assetData.price) /
      1 ether +
      1 ether;

    vm.assume(lender != address(0));
    vm.assume(borrower != address(0));

    // deposit
    vm.roll(15_411_340);
    startHoax(lender, lenderContribution);
    deposit(baycPool, lenderContribution);
    vm.stopPrank();
    assertEq(BAYC_POOL.balance, lenderContribution);
    assertEq(poolToken.balanceOf(lender), lenderContribution);

    // borrow
    vm.roll(15_411_340);
    startHoax(borrower, borrowerContribution);
    borrow(baycPool, borrowerContribution, MAGIC_ASSET_DATA, MAGIC_PURCHASE_DATA);
    vm.stopPrank();

    vm.roll(15_411_340);
    startHoax(lender, borrowerContribution);
    vm.expectRevert(Error_ExistingLoan.selector);
    borrow(baycPool, borrowerContribution, MAGIC_ASSET_DATA, MAGIC_PURCHASE_DATA);
    vm.stopPrank();
  }

  // function testLoanOriginationOnInvalidAsset(address lender, address borrower) public {
  //   BorrowAssetData memory _assetData = abi.decode(
  //     MAGIC_ASSET_DATA,
  //     (BorrowAssetData)
  //   );

  //   //vm.warp(1661311696);
  //   LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
  //   ERC20 poolToken = ERC20(baycPool.poolToken());

  //   uint256 lenderContribution = _assetData.price * 2;
  //   uint256 borrowerContribution = (baycPool.collateralCoverageRatio() *
  //     _assetData.price) /
  //     1 ether +
  //     1 ether;

  //   vm.assume(lender != address(0));
  //   vm.assume(borrower != address(0));

  //   // deposit
  //   vm.roll(15_200_000);
  //   startHoax(lender, lenderContribution);
  //   deposit(baycPool, lenderContribution);
  //   vm.stopPrank();
  //   assertEq(BAYC_POOL.balance, lenderContribution);
  //   assertEq(poolToken.balanceOf(lender), lenderContribution);

  //   // borrow
  //   vm.roll(15_200_000);
  //   startHoax(borrower, borrowerContribution);
  //   borrow(baycPool, borrowerContribution, MAGIC_ASSET_DATA, MAGIC_PURCHASE_DATA);
  //   vm.stopPrank();
  // }

  function testPartialLoanRepayment(
    // address lender, 
    // address borrower
  ) public {
    address lender = 0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051;
    address borrower = 0x09b1769771a78D147CaFc5cCC971a94bDA5C342a;
    vm.label(lender, 'alice');
    vm.label(borrower, 'bob');
    BorrowAssetData memory _assetData = abi.decode(
      MAGIC_ASSET_DATA,
      (BorrowAssetData)
    );

    //vm.warp(1661311696);
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    ERC721Minimal originalCollection = ERC721Minimal(
      baycPool.originalCollection()
    );
    ERC721Minimal syntheticCollection = ERC721Minimal(
      baycPool.syntheticCollection()
    );

    uint256 lenderContribution = _assetData.price * 2;
    uint256 borrowerContribution = (baycPool.collateralCoverageRatio() *
      _assetData.price) /
      1 ether +
      1 ether;
    uint256 repaymentContribution = 1 ether;

    vm.assume(lender != address(0));
    vm.assume(borrower != address(0));

    // deposit
    vm.roll(15_411_340);
    startHoax(lender, lenderContribution);
    deposit(baycPool, lenderContribution);
    vm.stopPrank();
    assertEq(BAYC_POOL.balance, lenderContribution);
    assertEq(poolToken.balanceOf(lender), lenderContribution);

    // borrow
    vm.roll(15_411_340);
    startHoax(borrower, borrowerContribution + repaymentContribution);
    borrow(
      baycPool,
      borrowerContribution,
      MAGIC_ASSET_DATA,
      MAGIC_PURCHASE_DATA
    );

    // repay
    uint256 preBorrowerOriginalBalance = originalCollection.balanceOf(borrower);
    uint256 preBorrowerSyntheticBalance = syntheticCollection.balanceOf(borrower);
    Loan memory _loan = baycPool.getTokenLoanStatus(_assetData.tokenId);
    uint256 loanPrincipal = _loan.principal;

    repay(baycPool, repaymentContribution, _assetData.tokenId);
    vm.stopPrank();

    // loan n nft status change
    _loan = baycPool.getTokenLoanStatus(_assetData.tokenId);
    assertEq(_loan.active, true);
    assertEq(_loan.principal, loanPrincipal - repaymentContribution);
    assertEq(_loan.installments[0].amount, _loan.installments[_loan.installments.length - 1].amount - repaymentContribution);
    assertEq(originalCollection.balanceOf(borrower), preBorrowerOriginalBalance);
    assertEq(syntheticCollection.balanceOf(borrower), preBorrowerSyntheticBalance);
  }

  function testOverflowLoanRepayment() public {}

  function testCompleteLoanRepayment(
    address lender, 
    address borrower
  ) public {
    vm.label(lender, 'alice');
    vm.label(borrower, 'bob');
    BorrowAssetData memory _assetData = abi.decode(
      MAGIC_ASSET_DATA,
      (BorrowAssetData)
    );

    //vm.warp(1661311696);
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    ERC721Minimal originalCollection = ERC721Minimal(
      baycPool.originalCollection()
    );
    ERC721Minimal syntheticCollection = ERC721Minimal(
      baycPool.syntheticCollection()
    );

    uint256 lenderContribution = _assetData.price * 2;
    uint256 borrowerContribution = (baycPool.collateralCoverageRatio() *
      _assetData.price) /
      1 ether +
      1 ether;
    uint256 repaymentContribution = _assetData.price - borrowerContribution;

    vm.assume(lender != address(0));
    vm.assume(borrower != address(0));

    // deposit
    vm.roll(15_411_340);
    startHoax(lender, lenderContribution);
    deposit(baycPool, lenderContribution);
    vm.stopPrank();
    assertEq(BAYC_POOL.balance, lenderContribution);
    assertEq(poolToken.balanceOf(lender), lenderContribution);

    // borrow
    vm.roll(15_411_340);
    startHoax(borrower, borrowerContribution + repaymentContribution);
    borrow(
      baycPool,
      borrowerContribution,
      MAGIC_ASSET_DATA,
      MAGIC_PURCHASE_DATA
    );

    // repay
    uint256 preBorrowerOriginalBalance = originalCollection.balanceOf(borrower);
    uint256 preBorrowerSyntheticBalance = syntheticCollection.balanceOf(borrower);
    uint256 syntheticTotalSupply = syntheticCollection.totalSupply();
    repay(baycPool, repaymentContribution, _assetData.tokenId);
    vm.stopPrank();

    // loan n nft status change
    Loan memory _loan = baycPool.getTokenLoanStatus(_assetData.tokenId);
    assertEq(_loan.active, false);
    assertEq(_loan.principal, 0);
    assertEq(originalCollection.balanceOf(borrower), preBorrowerOriginalBalance + 1);
    assertEq(syntheticCollection.balanceOf(borrower), preBorrowerSyntheticBalance - 1);
    assertEq(syntheticCollection.totalSupply(), syntheticTotalSupply - 1);
  }

  function testInterestChargedLoanRepayment() public {}

  function testInterestChargedCompleteLoanRepayment() public {}

  function testAssetLiquidation() public {}

  function testAssetLiquidationWithSomeRepayment() public {}
}
