// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "./IKrystalVaultCommon.sol";

interface IKrystalVault is IKrystalVaultCommon {
  struct VaultState {
    IUniswapV3Pool pool;
    INonfungiblePositionManager nfpm;
    IERC20 token0;
    IERC20 token1;
    uint256 currentTokenId;
    int24 currentTickLower;
    int24 currentTickUpper;
    int24 tickSpacing;
    uint24 fee;
  }

  event VaultPositionMint(address indexed nfpm, uint256 indexed tokenId);

  event VaultDeposit(address indexed shareholder, uint256 shares, uint256 deposit0, uint256 deposit1);

  event VaultWithdraw(address indexed sender, address indexed to, uint256 shares, uint256 amount0, uint256 amount1);

  event VaultExit(
    address indexed sender,
    address indexed to,
    uint256 shares,
    uint256 amount0,
    uint256 amount1,
    uint256 tokenId
  );

  event VaultRebalance(
    address indexed nfpm,
    uint256 indexed oldTokenId,
    uint256 newTokenId,
    uint256 liquidity,
    uint256 amount0Added,
    uint256 amount1Added
  );

  event VaultCompound(int24 tick, uint256 token0Balance, uint256 token1Balance, uint256 totalSupply);

  enum FeeType {
    PLATFORM,
    OWNER,
    AUTOMATOR
  }

  event FeeCollected(address indexed recipient, FeeType feeType, uint256 fees0, uint256 fees1);

  function mintPosition(
    address owner,
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0Min,
    uint256 amount1Min
  ) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);

  function deposit(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address to
  ) external payable returns (uint256 shares);

  function withdraw(
    uint256 shares,
    address to,
    uint256 amount0Min,
    uint256 amount1Min
  ) external returns (uint256 amount0, uint256 amount1);

  function exit(address to, uint256 amount0Min, uint256 amount1Min, uint16 automatorFee) external;

  function rebalance(
    int24 _baseLower,
    int24 _baseUpper,
    uint256 decreasedAmount0Min,
    uint256 decreasedAmount1Min,
    uint256 amount0Min,
    uint256 amount1Min,
    uint16 automatorFee
  ) external;

  function compound(uint256 amount0Min, uint256 amount1Min, uint16 automatorFee) external;

  function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

  function getBasePosition() external view returns (uint128 liquidity, uint256 amount0, uint256 amount1);

  function currentTick() external view returns (int24 tick);

  function grantAdminRole(address _address) external;

  function revokeAdminRole(address _address) external;

  function getVaultOwner() external view returns (address);

  function state() external view returns (
    IUniswapV3Pool pool,
    INonfungiblePositionManager nfpm,
    IERC20 token0,
    IERC20 token1,
    uint256 currentTokenId,
    int24 currentTickLower,
    int24 currentTickUpper,
    int24 tickSpacing,
    uint24 fee
  );
}
