// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../src/LeverV1ERC20Essential.sol";
import "forge-std/Test.sol";

contract LeverV1ERC20EssentialTest is Test {
    LeverV1ERC20Essential private leverToken;

    function setUp() public {
        leverToken = new LeverV1ERC20Essential("Lever Fi LP Test", "LF-LP-T");
    }

    function testMint() public {
        leverToken.mintTo(0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051, 100 ether);
        assertEq(
            leverToken.balanceOf(0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051),
            100 ether
        );
    }

    function testBurn() public {
        leverToken.burnFrom(0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051, 100 ether);
        assertEq(
            leverToken.balanceOf(0xbA842b7DA417Ba762D75e8F99e11c2980a8F8051),
            0
        );
    }
}
