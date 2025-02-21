# Solidity API

## KrystalVault

A Uniswap V2-like interface with fungible liquidity to Uniswap V3
which allows for arbitrary liquidity provision: one-sided, lop-sided, and balanced

### ADMIN_ROLE_HASH

```solidity
bytes32 ADMIN_ROLE_HASH
```

### MAX_SQRT_RATIO_LESS_ONE

```solidity
uint160 MAX_SQRT_RATIO_LESS_ONE
```

### XOR_SQRT_RATIO

```solidity
uint160 XOR_SQRT_RATIO
```

### vaultFactory

```solidity
address vaultFactory
```

### vaultOwner

```solidity
address vaultOwner
```

### state

```solidity
struct IKrystalVault.VaultState state
```

### config

```solidity
struct IKrystalVaultCommon.VaultConfig config
```

### optimalSwapper

```solidity
contract IOptimalSwapper optimalSwapper
```

### constructor

```solidity
constructor() public
```

### initialize

```solidity
function initialize(address _nfpm, address _pool, address _owner, struct IKrystalVaultCommon.VaultConfig _config, string name, string symbol, address _optimalSwapper, address _vaultAutomator) public
```

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _nfpm | address | Uniswap V3 nonfungible position manager address |
| _pool | address | Uniswap V3 pool address |
| _owner | address | Owner of the KrystalVault |
| _config | struct IKrystalVaultCommon.VaultConfig | Configuration of the KrystalVault |
| name | string | Name of the KrystalVault |
| symbol | string | Symbol of the KrystalVault |
| _optimalSwapper | address | Address of the optimal swapper |
| _vaultAutomator | address | Address of the vault automator |

### onlyVaultFactory

```solidity
modifier onlyVaultFactory()
```

### mintPosition

```solidity
function mintPosition(address owner, int24 tickLower, int24 tickUpper, uint256 amount0Min, uint256 amount1Min) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

Mint a new position

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| owner | address | Address of the owner of the position |
| tickLower | int24 | The lower tick of the base position |
| tickUpper | int24 | The upper tick of the base position |
| amount0Min | uint256 | Minimum amount of token0 to deposit |
| amount1Min | uint256 | Minimum amount of token1 to deposit |

### deposit

```solidity
function deposit(uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min, address to) external returns (uint256 shares)
```

Deposit tokens

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0Desired | uint256 | Desired amount of token0 to deposit |
| amount1Desired | uint256 | Desired amount of token1 to deposit |
| amount0Min | uint256 | Minimum amount of token0 to deposit |
| amount1Min | uint256 | Minimum amount of token1 to deposit |
| to | address | Address to which liquidity tokens are sent |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | Quantity of liquidity tokens minted as a result of deposit |

### withdraw

```solidity
function withdraw(uint256 shares, address to, uint256 amount0Min, uint256 amount1Min) external returns (uint256 amount0, uint256 amount1)
```

Withdraw liquidity tokens and receive the tokens

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | Number of liquidity tokens to redeem as pool assets |
| to | address | Address to which redeemed pool assets are sent |
| amount0Min | uint256 | Minimum amount of token0 to receive |
| amount1Min | uint256 | Minimum amount of token1 to receive |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | Amount of token0 redeemed by the submitted liquidity tokens |
| amount1 | uint256 | Amount of token1 redeemed by the submitted liquidity tokens |

### exit

```solidity
function exit(address to, uint256 amount0Min, uint256 amount1Min) external
```

Exit the position and redeem all tokens to balance

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Address to which redeemed pool assets are sent |
| amount0Min | uint256 | Minimum amount of token0 to receive |
| amount1Min | uint256 | Minimum amount of token1 to receive |

### rebalance

```solidity
function rebalance(int24 _newTickLower, int24 _newTickUpper, uint256 decreasedAmount0Min, uint256 decreasedAmount1Min, uint256 amount0Min, uint256 amount1Min) external
```

Rebalance position to new range

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newTickLower | int24 | The lower tick of the base position |
| _newTickUpper | int24 | The upper tick of the base position |
| decreasedAmount0Min | uint256 | min amount0 returned for shares of liq |
| decreasedAmount1Min | uint256 | min amount1 returned for shares of liq |
| amount0Min | uint256 | min amount0 returned for shares of liq |
| amount1Min | uint256 | min amount1 returned for shares of liq |

### compound

```solidity
function compound(uint256 amount0Min, uint256 amount1Min) external
```

Compound fees

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0Min | uint256 | Minimum amount of token0 to receive |
| amount1Min | uint256 | Minimum amount of token1 to receive |

### _collectFees

```solidity
function _collectFees() internal returns (uint128 liquidity)
```

Collect fees

### _mintLiquidity

```solidity
function _mintLiquidity(struct INonfungiblePositionManager.MintParams params) internal returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

Create position

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct INonfungiblePositionManager.MintParams | Mint parameters |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tokenId | uint256 | The ID of the token that represents the minted position |
| liquidity | uint128 | The amount of liquidity for this position |
| amount0 | uint256 | The amount of token0 |
| amount1 | uint256 | The amount of token1 |

### _decreaseLiquidityAndCollectFees

```solidity
function _decreaseLiquidityAndCollectFees(uint128 liquidity, address to, bool collectAll, uint256 amount0Min, uint256 amount1Min) internal returns (uint256 amount0, uint256 amount1)
```

Decrease liquidity from the sender and collect tokens owed for the liquidity

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidity | uint128 | The amount of liquidity to burn |
| to | address | The address which should receive the fees collected |
| collectAll | bool | If true, collect all tokens owed in the pool, else collect the owed tokens of the burn |
| amount0Min | uint256 |  |
| amount1Min | uint256 |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0 | uint256 | The amount of fees collected in token0 |
| amount1 | uint256 | The amount of fees collected in token1 |

### _liquidityForShares

```solidity
function _liquidityForShares(uint256 shares) internal view returns (uint128)
```

Get the liquidity amount for given liquidity tokens

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| shares | uint256 | Shares of position |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint128 | The amount of liquidity token for shares |

### _position

```solidity
function _position() internal view returns (uint128 liquidity, uint128 tokensOwed0, uint128 tokensOwed1)
```

Get the info of the given position

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidity | uint128 | The amount of liquidity of the position |
| tokensOwed0 | uint128 | Amount of token0 owed |
| tokensOwed1 | uint128 | Amount of token1 owed |

### getTotalAmounts

```solidity
function getTotalAmounts() public view returns (uint256 total0, uint256 total1)
```

Get the total amounts of token0 and token1 in the KrystalVault

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| total0 | uint256 | Quantity of token0 in both positions and unused in the KrystalVault |
| total1 | uint256 | Quantity of token1 in both positions and unused in the KrystalVault |

### getBasePosition

```solidity
function getBasePosition() public view returns (uint128 liquidity, uint256 amount0, uint256 amount1)
```

Get the base position info

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| liquidity | uint128 | Amount of total liquidity in the base position |
| amount0 | uint256 | Estimated amount of token0 that could be collected by burning the base position |
| amount1 | uint256 | Estimated amount of token1 that could be collected by burning the base position |

### _amountsForLiquidity

```solidity
function _amountsForLiquidity(int24 tickLower, int24 tickUpper, uint128 liquidity) internal view returns (uint256, uint256)
```

Get the amounts of the given numbers of liquidity tokens

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickLower | int24 | The lower tick of the position |
| tickUpper | int24 | The upper tick of the position |
| liquidity | uint128 | The amount of liquidity tokens |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | Amount of token0 and token1 |
| [1] | uint256 |  |

### currentTick

```solidity
function currentTick() public view returns (int24 tick)
```

Get the current price tick of the Uniswap pool

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| tick | int24 | Uniswap pool's current price tick |

### _optimalSwap

```solidity
function _optimalSwap(int24 tickLower, int24 tickUpper) internal
```

_Swap tokens to the optimal ratio to add liquidity in the same pool_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| tickLower | int24 | The lower tick of the position |
| tickUpper | int24 | The upper tick of the position |

### grantAdminRole

```solidity
function grantAdminRole(address _address) external
```

grant admin role to the address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to which the admin role is granted |

### revokeAdminRole

```solidity
function revokeAdminRole(address _address) external
```

revoke admin role from the address

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address from which the admin role is revoked |

### _uint128Safe

```solidity
function _uint128Safe(uint256 x) internal pure returns (uint128)
```

_Safely convert a uint256 to a uint128_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| x | uint256 | The uint256 to be converted |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint128 | The uint128 value |

### getVaultOwner

```solidity
function getVaultOwner() external view returns (address)
```

Get the owner of the KrystalVault

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | address | The address of the owner |

