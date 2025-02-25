# Solidity API

## IKrystalVault

### VaultState

```solidity
struct VaultState {
  contract IUniswapV3Pool pool;
  contract INonfungiblePositionManager nfpm;
  contract IERC20 token0;
  contract IERC20 token1;
  uint256 currentTokenId;
  int24 currentTickLower;
  int24 currentTickUpper;
  int24 tickSpacing;
  uint24 fee;
}
```

### VaultPositionMint

```solidity
event VaultPositionMint(address nfpm, uint256 tokenId)
```

### VaultDeposit

```solidity
event VaultDeposit(address shareholder, uint256 shares, uint256 deposit0, uint256 deposit1)
```

### VaultWithdraw

```solidity
event VaultWithdraw(address sender, address to, uint256 shares, uint256 amount0, uint256 amount1)
```

### VaultExit

```solidity
event VaultExit(address sender, address to, uint256 shares, uint256 amount0, uint256 amount1, uint256 tokenId)
```

### VaultRebalance

```solidity
event VaultRebalance(address nfpm, uint256 oldTokenId, uint256 newTokenId, uint256 liquidity, uint256 amount0Added, uint256 amount1Added)
```

### VaultCompound

```solidity
event VaultCompound(int24 tick, uint256 token0Balance, uint256 token1Balance, uint256 totalSupply)
```

### FeeType

```solidity
enum FeeType {
  PLATFORM,
  OWNER,
  AUTOMATOR
}
```

### FeeCollected

```solidity
event FeeCollected(address recipient, enum IKrystalVault.FeeType feeType, uint256 fees0, uint256 fees1)
```

### initialize

```solidity
function initialize(address _nfpm, address _pool, address _owner, struct IKrystalVaultCommon.VaultConfig _config, string name, string symbol, address _optimalSwapper, address _vaultAutomator) external
```

### mintPosition

```solidity
function mintPosition(address owner, int24 tickLower, int24 tickUpper, uint256 amount0Min, uint256 amount1Min) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

### deposit

```solidity
function deposit(uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min, address to) external payable returns (uint256 shares)
```

### withdraw

```solidity
function withdraw(uint256 shares, address to, uint256 amount0Min, uint256 amount1Min) external returns (uint256 amount0, uint256 amount1)
```

### exit

```solidity
function exit(address to, uint256 amount0Min, uint256 amount1Min, uint16 automatorFee) external
```

### rebalance

```solidity
function rebalance(int24 _baseLower, int24 _baseUpper, uint256 decreasedAmount0Min, uint256 decreasedAmount1Min, uint256 amount0Min, uint256 amount1Min, uint16 automatorFee) external
```

### compound

```solidity
function compound(uint256 amount0Min, uint256 amount1Min, uint16 automatorFee) external
```

### getTotalAmounts

```solidity
function getTotalAmounts() external view returns (uint256 total0, uint256 total1)
```

### getBasePosition

```solidity
function getBasePosition() external view returns (uint128 liquidity, uint256 amount0, uint256 amount1)
```

### currentTick

```solidity
function currentTick() external view returns (int24 tick)
```

### grantAdminRole

```solidity
function grantAdminRole(address _address) external
```

### revokeAdminRole

```solidity
function revokeAdminRole(address _address) external
```

### getVaultOwner

```solidity
function getVaultOwner() external view returns (address)
```

### state

```solidity
function state() external view returns (contract IUniswapV3Pool pool, contract INonfungiblePositionManager nfpm, contract IERC20 token0, contract IERC20 token1, uint256 currentTokenId, int24 currentTickLower, int24 currentTickUpper, int24 tickSpacing, uint24 fee)
```

