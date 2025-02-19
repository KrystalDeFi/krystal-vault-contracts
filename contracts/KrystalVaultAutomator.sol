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

  function executeRebalance(ExecuteRebalanceParams calldata params) external onlyRole(OPERATOR_ROLE) whenNotPaused {
    _validateOrder(params.abiEncodedUserOrder, params.orderSignature, params.vault.getVaultOwner());
    params.vault.rebalance(
      params.newTickLower,
      params.newTickUpper,
      params.decreaseAmount0Min,
      params.decreaseAmount1Min,
      params.amount0Min,
      params.amount1Min
    );
  }

  function executeExit(
    IKrystalVault vault,
    uint256 amount0Min,
    uint256 amount1Min,
    bytes calldata abiEncodedUserOrder,
    bytes calldata orderSignature
  ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
    address vaultOwner = vault.getVaultOwner();
    _validateOrder(abiEncodedUserOrder, orderSignature, vaultOwner);
    vault.exit(vaultOwner, amount0Min, amount1Min);
  }

  function executeCompound(
    IKrystalVault vault,
    uint256 amount0Min,
    uint256 amount1Min,
    bytes calldata abiEncodedUserOrder,
    bytes calldata orderSignature
  ) external onlyRole(OPERATOR_ROLE) whenNotPaused {
    _validateOrder(abiEncodedUserOrder, orderSignature, vault.getVaultOwner());
    vault.compound(amount0Min, amount1Min);
  }

  function _validateOrder(bytes memory abiEncodedUserOrder, bytes memory orderSignature, address actor) internal view {
    address userAddress = _recover(abiEncodedUserOrder, orderSignature);
    require(userAddress == actor, InvalidSignature());
    require(!_cancelledOrder[keccak256(orderSignature)], OrderCancelled());
  }

  function cancelOrder(bytes calldata abiEncodedUserOrder, bytes calldata orderSignature) external {
    _validateOrder(abiEncodedUserOrder, orderSignature, msg.sender);
    _cancelledOrder[keccak256(orderSignature)] = true;
    emit CancelOrder(msg.sender, abiEncodedUserOrder, orderSignature);
  }

  function isOrderCancelled(bytes calldata orderSignature) external view returns (bool) {
    return _cancelledOrder[keccak256(orderSignature)];
  }

  function grantOperator(address operator) external onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(OPERATOR_ROLE, operator);
  }

  function revokeOperator(address operator) external onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(OPERATOR_ROLE, operator);
  }

  receive() external payable {}
}
