// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @title math for handling eth and token conversions
/// @notice methods are used for estimating how many liquidity tokens
/// someone should be rewarded for contribution and vice versa
library ConversionMath {
  /// @notice convert eth to liquidity tokens
  /// @param w eth contributed
  /// @param x true eth value of pool post contribution
  /// @param y total supply of token
  /// @return z tokens
  function computeTokenConversion(
    uint256 w,
    uint256 x,
    uint256 y
  ) internal pure returns (uint256 z) {
    require(w > 0, "LT");
    if (y == 0) {
      z = w;
    } else {
      // uint8 or assign to z
      uint256 ratio = (w * 1 ether) / x;
      z = (ratio * y) / (1 ether - ratio);
    }
  }

  /// @notice convert liquidity token to eth
  /// @param w tokens requested to convert
  /// @param x true eth value of pool
  /// @param y total supply of token
  /// @return z eth
  function computeEthConversion(
    uint256 w,
    uint256 x,
    uint256 y
  ) internal pure returns (uint256 z) {
    require(w > 0 && y > 0, "LT");
    z = (((w * 1 ether) / y) * x) / 1 ether;
  }

  function computeTokenConversion(
    int256 w,
    int256 x,
    int256 y
  ) internal pure returns (int256 z) {
    require(w >= x, "LT");
    if (y == 0) {
      z = w;
    } else {
      // uint8 or assign to z
      int256 ratio = (w * 1 ether) / x;
      z = (ratio * y) / (1 ether - ratio);
    }
  }

  function computeEthConversion(
    int256 w,
    int256 x,
    int256 y
  ) internal pure returns (int256 z) {
    require(z > 0, "LT");
    z = (((w * 1 ether) / y) * x) / 1 ether;
  }
}
