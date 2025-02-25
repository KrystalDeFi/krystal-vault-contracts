// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

interface IOptimalSwapper {
  function optimalSwap(
    address pool,
    uint256 amount0,
    uint256 amount1,
    int24 tickLower,
    int24 tickUpper,
    bytes calldata data
  ) external;

  function getOptimalSwapAmounts(
    address pool,
    uint256 amount0Desired,
    uint256 amount1Desired,
    int24 tickLower,
    int24 tickUpper,
    bytes calldata data
  ) external view returns (uint256 amount0, uint256 amount1);
}
