// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

import "./IKrystalVault.sol";

interface IKrystalVaultAutomator {
  error InvalidOperator();

  error InvalidSignature();

  error OrderCancelled();

  event CancelOrder(address user, bytes order, bytes signature);

  struct ExecuteRebalanceParams {
    IKrystalVault vault;
    int24 newTickLower;
    int24 newTickUpper;
    uint256 decreaseAmount0Min;
    uint256 decreaseAmount1Min;
    uint256 amount0Min;
    uint256 amount1Min;
    bytes abiEncodedUserOrder;
    bytes orderSignature;
  }

  function executeRebalance(ExecuteRebalanceParams calldata params) external;

  function executeExit(
    IKrystalVault vault,
    uint256 amount0Min,
    uint256 amount1Min,
    bytes calldata abiEncodedUserOrder,
    bytes calldata orderSignature
  ) external;

  function executeCompound(
    IKrystalVault vault,
    uint256 amount0Min,
    uint256 amount1Min,
    bytes calldata abiEncodedUserOrder,
    bytes calldata orderSignature
  ) external;

  function cancelOrder(bytes calldata abiEncodedUserOrder, bytes calldata orderSignature) external;

  function isOrderCancelled(bytes calldata orderSignature) external view returns (bool);

  function grantOperator(address operator) external;

  function revokeOperator(address operator) external;
}
