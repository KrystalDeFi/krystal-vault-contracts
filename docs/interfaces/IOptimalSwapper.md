# Solidity API

## IOptimalSwapper

### optimalSwap

```solidity
function optimalSwap(address pool, uint256 amount0, uint256 amount1, int24 tickLower, int24 tickUpper, bytes data) external
```

### getOptimalSwapAmounts

```solidity
function getOptimalSwapAmounts(address pool, uint256 amount0Desired, uint256 amount1Desired, int24 tickLower, int24 tickUpper, bytes data) external view returns (uint256 amount0, uint256 amount1)
```
