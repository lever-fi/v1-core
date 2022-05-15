// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/LeverV1Pool.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "forge-std/Test.sol";

contract Collection is ERC721 {
    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}
}

contract LeverV1PoolTest is Test {
    ERC721 private collection;
    LeverV1Pool private leverPool;

    function setUp() public {
        collection = new Collection("Lever Ape Test Club", "LNFT");
        leverPool = new LeverV1Pool(
            0x0000000000000000000000000000000000000000,
            address(collection),
            0,
            0,
            0
        );
    }

    function testDeposit() public {
        leverPool.deposit{value: 1 ether}();
        assertEq(address(leverPool).balance, 1 ether);
    }
}
