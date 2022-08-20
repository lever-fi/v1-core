// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "contracts/tokens/ERC721Minimal.sol";
import "contracts/LeverV1Factory.sol";
import "contracts/LeverV1Pool.sol";

error Error_InsufficientBalance();
error DuplicatePool();
error Unauthorized();

contract LeverV1PoolTest is Test {
  using stdStorage for StdStorage;

  address constant OS_EXCHANGE = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
  address constant LR_EXCHANGE = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
  address constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
  address constant DOODLE = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
  address constant MOONBIRD = 0x23581767a106ae21c074b2276D25e5C3e136a68b;

  LeverV1Factory public FACTORY;
  address payable public BAYC_POOL;
  address payable public DOODLE_POOL;

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

  function calcDistribution(
    ERC20 token,
    uint256 currentBalance,
    uint256 contribution
  ) view internal returns (uint256 amount) {
    uint256 aPost = currentBalance + contribution;
    uint256 totalSupply = token.totalSupply();

    if (totalSupply == 0) {
      amount = contribution;
    } else {
      uint256 split = (contribution * 1 ether) / aPost;
      amount = (split * totalSupply) / (1 ether - split);
    }
  }

  function setUp() public {
    FACTORY = new LeverV1Factory();
    BAYC_POOL = deployPool(BAYC);
    DOODLE_POOL = deployPool(DOODLE);
  }

  function testDeployNewPool() public {
    deployPool(MOONBIRD);
    assertEq(FACTORY.poolExists(MOONBIRD), true);
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

  function testPoolDepositAndTokenMint(address depositor, uint256 amount) public {
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    uint256 minDeposit = baycPool.minDeposit();

    amount = bound(amount, minDeposit, 1000 ether);
    vm.assume(depositor != address(0));

    startHoax(depositor, amount);
    deposit(baycPool, amount);
    vm.stopPrank();

    assertEq(poolToken.totalSupply(), amount);
    assertEq(poolToken.balanceOf(depositor), amount);
  }

  function testInsufficientDepositAmount(uint256 amount) public {
    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    vm.assume(amount < baycPool.minDeposit());

    vm.expectRevert(Error_InsufficientBalance.selector);
    deposit(baycPool, amount);
  }

  function testMultiPoolDepositAndTokenDistribution(
    uint256[100] memory amounts,
    address[100] memory depositors
  ) public {
    // uint256[3] memory amounts = [uint256(90 ether), uint256(5 ether), uint256(94 ether)];
    // address[3] memory depositors = [
    //   0x46340b20830761efd32832A74d7169B29FEB9758,
    //   0xad259A73b6B0B04fEc294996064Adf7A719D26E8,
    //   0x56Eddb7aa87536c09CCc2793473599fD21A8b17F
    // ];

    LeverV1Pool baycPool = LeverV1Pool(BAYC_POOL);
    ERC20 poolToken = ERC20(baycPool.poolToken());
    uint256 minDeposit = baycPool.minDeposit();
    uint256 tokenSupplyTracker = 0;

    for (uint256 i = 0; i < amounts.length; i++) {
      amounts[i] = bound(amounts[i], minDeposit, 1000 ether);
      depositors[i] = address(uint160(amounts[i]));
      //vm.assume(depositors[i] != address(0));
    }

    for (uint256 i = 0; i < amounts.length; i++) {
      uint256 liquidityTokensOwned = calcDistribution(
        poolToken,
        BAYC_POOL.balance,
        amounts[i]
      );
      tokenSupplyTracker += liquidityTokensOwned;

      startHoax(depositors[i], amounts[i] + 0.1 ether);
      deposit(baycPool, amounts[i]);
      vm.stopPrank();

      assertEq(poolToken.balanceOf(depositors[i]), liquidityTokensOwned);
    }
  }

  function testPoolCollectAndTokenDistribution() public {}

  function testPoolDryAndTokenDistribution() public {}

  function testPoolCollectInvalidCollectionAmount() public {}
}
