# Solidity API

## IKrystalVaultAutomator

### InvalidOperator

```solidity
error InvalidOperator()
```

### InvalidSignature

```solidity
error InvalidSignature()
```

### OrderCancelled

```solidity
error OrderCancelled()
```

### CancelOrder

```solidity
event CancelOrder(address user, bytes order, bytes signature)
```

### ExecuteRebalanceParams

```solidity
struct ExecuteRebalanceParams {
  contract IKrystalVault vault;
  int24 newTickLower;
  int24 newTickUpper;
  uint256 decreaseAmount0Min;
  uint256 decreaseAmount1Min;
  uint256 amount0Min;
  uint256 amount1Min;
  uint16 automatorFee;
  bytes abiEncodedUserOrder;
  bytes orderSignature;
}
```

### executeRebalance

```solidity
function executeRebalance(struct IKrystalVaultAutomator.ExecuteRebalanceParams params) external
```

### executeExit

```solidity
function executeExit(contract IKrystalVault vault, uint256 amount0Min, uint256 amount1Min, uint16 automatorFee, bytes abiEncodedUserOrder, bytes orderSignature) external
```

### executeCompound

```solidity
function executeCompound(contract IKrystalVault vault, uint256 amount0Min, uint256 amount1Min, uint16 automatorFee, bytes abiEncodedUserOrder, bytes orderSignature) external
```

### cancelOrder

```solidity
function cancelOrder(bytes abiEncodedUserOrder, bytes orderSignature) external
```

### isOrderCancelled

```solidity
function isOrderCancelled(bytes orderSignature) external view returns (bool)
```

### grantOperator

```solidity
function grantOperator(address operator) external
```

### revokeOperator

```solidity
function revokeOperator(address operator) external
```

