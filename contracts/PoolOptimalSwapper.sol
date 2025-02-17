// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

import { OptimalSwap, V3PoolCallee } from "./libraries/OptimalSwap.sol";
import { TernaryLib } from "@aperture_finance/uni-v3-lib/src/TernaryLib.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "./interfaces/IOptimalSwapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol";

contract PoolOptimalSwapper is IOptimalSwapper, IUniswapV3SwapCallback {
  using TernaryLib for bool;
  using SafeERC20 for IERC20;

  uint160 internal constant MAX_SQRT_RATIO_LESS_ONE = 1461446703485210103287273052203988822378723970342 - 1;
  uint160 internal constant XOR_SQRT_RATIO = (4295128739 + 1) ^ (1461446703485210103287273052203988822378723970342 - 1);

  address private currentPool;
  /// @notice Callback function required by Uniswap V3 to finalize swaps
  function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata) external override {
    require(msg.sender == currentPool, "Incorrect pool");

    if (amount0Delta > 0) {
      IERC20(IUniswapV3Pool(currentPool).token0()).transfer(msg.sender, uint256(amount0Delta));
    } else if (amount1Delta > 0) {
      IERC20(IUniswapV3Pool(currentPool).token1()).transfer(msg.sender, uint256(amount1Delta));
    }
  }

  /// @dev Make a direct `exactIn` pool swap
  /// @param amountIn The amount of token to be swapped
  /// @param zeroForOne The direction of the swap, true for token0 to token1, false for token1 to token0
  /// @return amountOut The amount of token received after swap
  function _poolSwap(address pool, uint256 amountIn, bool zeroForOne) internal returns (uint256 amountOut) {
    if (amountIn != 0) {
      currentPool = pool;
      uint160 sqrtPriceLimitX96;
      // Equivalent to `sqrtPriceLimitX96 = zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1`
      assembly {
        sqrtPriceLimitX96 := xor(MAX_SQRT_RATIO_LESS_ONE, mul(XOR_SQRT_RATIO, zeroForOne))
      }
      (int256 amount0Delta, int256 amount1Delta) = V3PoolCallee.wrap(pool).swap(
        address(this),
        zeroForOne,
        int256(amountIn),
        sqrtPriceLimitX96,
        ""
      );
      unchecked {
        amountOut = 0 - zeroForOne.ternary(uint256(amount1Delta), uint256(amount0Delta));
      }
    }
  }

  function optimalSwap(
    address pool,
    uint256 amount0Desired,
    uint256 amount1Desired,
    int24 tickLower,
    int24 tickUpper,
    bytes calldata data
  ) external override {
    IERC20 token0 = IERC20(IUniswapV3Pool(pool).token0());
    IERC20 token1 = IERC20(IUniswapV3Pool(pool).token1());
    token0.transferFrom(msg.sender, address(this), amount0Desired);
    token1.transferFrom(msg.sender, address(this), amount1Desired);

    amount0Desired = IERC20(token0).balanceOf(address(this));
    amount1Desired = IERC20(token1).balanceOf(address(this));
    uint256 amountIn;
    uint256 amountOut;
    bool zeroForOne;
    {
      (amountIn, , zeroForOne, ) = OptimalSwap.getOptimalSwap(
        V3PoolCallee.wrap(pool),
        tickLower,
        tickUpper,
        amount0Desired,
        amount1Desired
      );
      amountOut = _poolSwap(pool, amountIn, zeroForOne);
    }

    token0.transfer(msg.sender, token0.balanceOf(address(this)));
    token1.transfer(msg.sender, token1.balanceOf(address(this)));
  }
}
