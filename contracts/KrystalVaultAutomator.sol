// SPDX-License-Identifier: BUSL-1.1
// Modified from V3Automation

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

import "./interfaces/IKrystalVaultAutomator.sol";
import "./CustomEIP712.sol";

contract KrystalVaultAutomator is IKrystalVaultAutomator, CustomEIP712, AccessControl, Pausable {
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  mapping(bytes32 => bool) private _cancelledOrder;

  // Keep the naming and version of V3Automation
  constructor(address admin) CustomEIP712("V3AutomationOrder", "4.0") {
    _grantRole(DEFAULT_ADMIN_ROLE, admin);
    _grantRole(OPERATOR_ROLE, admin);
  }

  /// @notice Execute a rebalance on a KrystalVault
  /// @param params ExecuteRebalanceParams
  function executeRebalance(ExecuteRebalanceParams calldata params) external onlyRole(OPERATOR_ROLE) whenNotPaused {
    _validateOrder(params.abiEncodedUserOrder, params.orderSignature, params.vault.getVaultOwner());
    params.vault.rebalance(
      params.newTickLower,
      params.newTickUpper,
      params.decreaseAmount0Min,
      params.decreaseAmount1Min,
      params.amount0Min,
      params.amount1Min,
      params.automatorFee
    );
  }

  /// @notice Execute exit on a KrystalVault
  /// @param vault KrystalVault to exit from
  /// @param amount0Min Minimum amount of token0 to receive
  /// @param amount1Min Minimum amount of token1 to receive
  /// @param abiEncodedUserOrder ABI encoded user order
  /// @param orderSignature Signature of the order
  function executeExit(
    IKrystalVault vault,
    uint256 amount0Min,
    uint256 amount1Min,
    uint16 automatorFee,
    bytes calldata abiEncodedUserOrder,
    bytes calldata orderSignature
  ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
    address vaultOwner = vault.getVaultOwner();
    _validateOrder(abiEncodedUserOrder, orderSignature, vaultOwner);
    vault.exit(vaultOwner, amount0Min, amount1Min, automatorFee);
  }

  /// @notice Execute compound on a KrystalVault
  /// @param vault KrystalVault to compound
  /// @param amount0Min Minimum amount of token0 to receive
  /// @param amount1Min Minimum amount of token1 to receive
  /// @param abiEncodedUserOrder ABI encoded user order
  /// @param orderSignature Signature of the order
  function executeCompound(
    IKrystalVault vault,
    uint256 amount0Min,
    uint256 amount1Min,
    uint16 automatorFee,
    bytes calldata abiEncodedUserOrder,
    bytes calldata orderSignature
  ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
    _validateOrder(abiEncodedUserOrder, orderSignature, vault.getVaultOwner());
    vault.compound(amount0Min, amount1Min, automatorFee);
  }

  /// @dev Validate the order
  /// @param abiEncodedUserOrder ABI encoded user order
  /// @param orderSignature Signature of the order
  /// @param actor Actor of the order
  function _validateOrder(bytes memory abiEncodedUserOrder, bytes memory orderSignature, address actor) internal view {
    address userAddress = _recover(abiEncodedUserOrder, orderSignature);
    require(userAddress == actor, InvalidSignature());
    require(!_cancelledOrder[keccak256(orderSignature)], OrderCancelled());
  }

  /// @notice Cancel an order
  /// @param abiEncodedUserOrder ABI encoded user order
  /// @param orderSignature Signature of the order
  function cancelOrder(bytes calldata abiEncodedUserOrder, bytes calldata orderSignature) external {
    _validateOrder(abiEncodedUserOrder, orderSignature, msg.sender);
    _cancelledOrder[keccak256(orderSignature)] = true;
    emit CancelOrder(msg.sender, abiEncodedUserOrder, orderSignature);
  }

  /// @notice Check if an order is cancelled
  /// @param orderSignature Signature of the order
  /// @return true if the order is cancelled
  function isOrderCancelled(bytes calldata orderSignature) external view returns (bool) {
    return _cancelledOrder[keccak256(orderSignature)];
  }

  /// @notice Grant operator role
  /// @param operator Operator address
  function grantOperator(address operator) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(OPERATOR_ROLE, operator);
  }

  /// @notice Revoke operator role
  /// @param operator Operator address
  function revokeOperator(address operator) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(OPERATOR_ROLE, operator);
  }

  receive() external payable {}
}
