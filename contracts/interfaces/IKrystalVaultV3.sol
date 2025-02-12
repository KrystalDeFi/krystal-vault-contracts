// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "./IKrystalVaultV3Common.sol";

interface IKrystalVaultV3 is IKrystalVaultV3Common {
  struct VaultState {
    IUniswapV3Pool pool;
    INonfungiblePositionManager nfpm;
    IERC20 token0;
    IERC20 token1;
    uint256 currentTokenId;
    int24 currentTickLower;
    int24 currentTickUpper;
    int24 tickSpacing;
  }

  struct VaultConfig {
    bool mintCalled;
    uint8 feeBasisPoints;
    uint256 maxTotalSupply;
    address feeRecipient;
  }

  event Deposit(address indexed shareholder, uint256 shares, uint256 deposit0, uint256 deposit1);

  event PullLiquidity(uint128 shares, uint256 amount0, uint256 amount1);

  event Withdraw(address indexed sender, address indexed to, uint256 shares, uint256 amount0, uint256 amount1);

  event Exit(address indexed sender, address indexed to, uint256 shares, uint256 amount0, uint256 amount1);

  event Rebalance(
    int24 tick,
    uint256 totalAmount0,
    uint256 totalAmount1,
    uint256 feeAmount0,
    uint256 feeAmount1,
    uint256 totalSupply
  );

  event Compound(int24 tick, uint256 token0Balance, uint256 token1Balance, uint256 totalSupply);

  event AddLiquidity(int24 tickLower, int24 tickUpper, uint256 amount0, uint256 amount1);

  event FeeCollected(uint8 fee, uint256 fees0, uint256 fees1);

  event SetWhitelist(address indexed _address);

  event SetFee(uint8 newFee);

  function mintPosition(
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min
  ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

  function deposit(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address to
  ) external returns (uint256 shares);

  function pullLiquidity(
    uint128 shares,
    uint256 amount0Min,
    uint256 amount1Min
  ) external returns (uint256 amount0, uint256 amount1);

  function withdraw(
    uint256 shares,
    address to,
    uint256 amount0Min,
    uint256 amount1Min
  ) external returns (uint256 amount0, uint256 amount1);

  function exit(uint256 shares, address to, uint256 amount0Min, uint256 amount1Min) external;

  function rebalance(
    int24 _baseLower,
    int24 _baseUpper,
    uint256 decreasedAmount0Min,
    uint256 decreasedAmount1Min,
    uint256 amount0Min,
    uint256 amount1Min
  ) external;

  function compound(uint256 amount0Min, uint256 amount1Min) external;

  function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

  function getBasePosition() external view returns (uint128 liquidity, uint256 amount0, uint256 amount1);

  function currentTick() external view returns (int24 tick);

  function setFee(uint8 newFee) external;
}
