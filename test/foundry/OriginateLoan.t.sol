// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

import "contracts/LeverV1Factory.sol";
import "contracts/LeverV1Pool.sol";

contract ContractTest is Test {
  address constant OS_EXCHANGE = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
  address constant LR_EXCHANGE = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
  address constant BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
  address constant DOODLE = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;

  LeverV1Factory public FACTORY;
  address public BAYC_POOL;
  address public DOODLE_POOL;

  receive() external payable {}

  function setUp() public {
    FACTORY = new LeverV1Factory();
  }

  function testDeployBaycPool() public {
    BAYC_POOL = FACTORY.deployPool(
      BAYC,
      0.4 ether,
      0.045 ether,
      86400,
      /* daily */
      0.15 ether,
      2419200,
      /* 4wks */
      1 ether,
      0.05 ether,
      604800 /*weekly*/
    );

    assertEq(FACTORY.poolExists(BAYC), true);
  }
}
