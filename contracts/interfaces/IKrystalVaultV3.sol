// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

interface IKrystalVaultV3 {
  event Deposit(address indexed from, address indexed to, uint256 shares, uint256 deposit0, uint256 deposit1);

  event PullLiquidity(int24 tickLower, int24 tickUpper, uint128 shares, uint256 amount0, uint256 amount1);

  event Withdraw(address indexed sender, address indexed to, uint256 shares, uint256 amount0, uint256 amount1);

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

  event ZeroBurn(uint8 fee, uint256 fees0, uint256 fees1);

  event SetWhitelist(address indexed _address);

  event SetFee(uint8 newFee);

  event ToggleDirectDeposit(bool directDeposit);

  function deposit(
    uint256 deposit0,
    uint256 deposit1,
    address to,
    address from,
    uint256[4] memory inMin
  ) external returns (uint256 shares);

  function pullLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint128 shares,
    uint256[2] memory amountMin
  ) external returns (uint256 amount0, uint256 amount1);

  function withdraw(
    uint256 shares,
    address to,
    address from,
    uint256[4] memory minAmounts
  ) external returns (uint256 amount0, uint256 amount1);

  function rebalance(
    int24 _baseLower,
    int24 _baseUpper,
    int24 _limitLower,
    int24 _limitUpper,
    address _feeRecipient,
    uint256[4] memory inMin,
    uint256[4] memory outMin
  ) external;

  function compound(uint256[4] memory inMin) external;

  function addLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0,
    uint256 amount1,
    uint256[2] memory inMin
  ) external;

  function getTotalAmounts() external view returns (uint256 total0, uint256 total1);

  function getBasePosition() external view returns (uint128 liquidity, uint256 amount0, uint256 amount1);

  function getLimitPosition() external view returns (uint128 liquidity, uint256 amount0, uint256 amount1);

  function currentTick() external view returns (int24 tick);

  function setWhitelist(address _address) external;

  function setFee(uint8 newFee) external;

  function toggleDirectDeposit() external;

  function token0() external view returns (IERC20);

  function token1() external view returns (IERC20);

  function baseLower() external view returns (int24);

  function baseUpper() external view returns (int24);

  function deposit0Max() external view returns (uint256);

  function deposit1Max() external view returns (uint256);

  function pool() external view returns (IUniswapV3Pool);
}
