# Solidity API

## CustomEIP712

### DOMAIN_SEPARATOR

```solidity
bytes32 DOMAIN_SEPARATOR
```

### constructor

```solidity
constructor(string name, string version) internal
```

### _recover

```solidity
function _recover(bytes order, bytes signature) internal view returns (address)
```

### _hashTypedDataV4

```solidity
function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32)
```

### toTypedDataHash

```solidity
function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 digest)
```

_Returns the keccak256 digest of an EIP-712 typed data (EIP-191 version `0x01`).

The digest is calculated from a `domainSeparator` and a `structHash`, by prefixing them with
`\x19\x01` and hashing the result. It corresponds to the hash signed by the
https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`] JSON-RPC method as part of EIP-712.

See {ECDSA-recover}._

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

### getVaultOwner

```solidity
function getVaultOwner() external view returns (address)
```

## KrystalVaultAutomator

### OPERATOR_ROLE

```solidity
bytes32 OPERATOR_ROLE
```

### constructor

```solidity
constructor(address admin) public
```

### executeRebalance

```solidity
function executeRebalance(struct IKrystalVaultAutomator.ExecuteRebalanceParams params) external
```

### executeExit

```solidity
function executeExit(contract IKrystalVault vault, uint256 amount0Min, uint256 amount1Min, bytes abiEncodedUserOrder, bytes orderSignature) external
```

### executeCompound

```solidity
function executeCompound(contract IKrystalVault vault, uint256 amount0Min, uint256 amount1Min, bytes abiEncodedUserOrder, bytes orderSignature) external
```

### _validateOrder

```solidity
function _validateOrder(bytes abiEncodedUserOrder, bytes orderSignature, address actor) internal view
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

### receive

```solidity
receive() external payable
```

## KrystalVaultFactory

### uniswapV3Factory

```solidity
contract IUniswapV3Factory uniswapV3Factory
```

### krystalVaultImplementation

```solidity
address krystalVaultImplementation
```

### krystalVaultAutomator

```solidity
address krystalVaultAutomator
```

### vaultsByAddress

```solidity
mapping(address => struct IKrystalVaultFactory.Vault[]) vaultsByAddress
```

### allVaults

```solidity
address[] allVaults
```

### platformFeeRecipient

```solidity
address platformFeeRecipient
```

### platformFeeBasisPoint

```solidity
uint16 platformFeeBasisPoint
```

### optimalSwapper

```solidity
address optimalSwapper
```

### constructor

```solidity
constructor(address uniswapV3FactoryAddress, address krystalVaultImplementationAddress, address krystalVaultAutomatorAddress, address optimalSwapperAddress, address platformFeeRecipientAddress, uint16 _platformFeeBasisPoint) public
```

### createVault

```solidity
function createVault(address nfpm, struct INonfungiblePositionManager.MintParams params, uint16 _ownerFeeBasisPoint, string name, string symbol) external returns (address krystalVault)
```

Create a KrystalVault

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| nfpm | address | Address of INonfungiblePositionManager |
| params | struct INonfungiblePositionManager.MintParams | MintParams of INonfungiblePositionManager |
| _ownerFeeBasisPoint | uint16 |  |
| name | string | Name of the KrystalVault |
| symbol | string | Symbol of the KrystalVault |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| krystalVault | address | Address of KrystalVault created |

### pause

```solidity
function pause() public
```

### unpause

```solidity
function unpause() public
```

### setKrystalVaultImplementation

```solidity
function setKrystalVaultImplementation(address _krystalVaultImplementation) public
```

### setKrystalVaultAutomator

```solidity
function setKrystalVaultAutomator(address _krystalVaultAutomator) public
```

### setPlatformFeeRecipient

```solidity
function setPlatformFeeRecipient(address _platformFeeRecipient) public
```

### setPlatformFeeBasisPoint

```solidity
function setPlatformFeeBasisPoint(uint16 _platformFeeBasisPoint) public
```

### multicall

```solidity
function multicall(bytes[] data) public payable returns (bytes[] results)
```

Call multiple functions in the current contract and return the data from all of them if they all succeed

_The `msg.value` should not be trusted for any method callable from multicall._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| data | bytes[] | The encoded function data for each of the calls to make to this contract |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| results | bytes[] | The results from each of the calls passed in via data |

## PoolOptimalSwapper

### MAX_SQRT_RATIO_LESS_ONE

```solidity
uint160 MAX_SQRT_RATIO_LESS_ONE
```

### XOR_SQRT_RATIO

```solidity
uint160 XOR_SQRT_RATIO
```

### uniswapV3SwapCallback

```solidity
function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes) external
```

Callback function required by Uniswap V3 to finalize swaps

### _poolSwap

```solidity
function _poolSwap(address pool, uint256 amountIn, bool zeroForOne) internal returns (uint256 amountOut)
```

_Make a direct `exactIn` pool swap_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | address |  |
| amountIn | uint256 | The amount of token to be swapped |
| zeroForOne | bool | The direction of the swap, true for token0 to token1, false for token1 to token0 |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountOut | uint256 | The amount of token received after swap |

### optimalSwap

```solidity
function optimalSwap(address pool, uint256 amount0Desired, uint256 amount1Desired, int24 tickLower, int24 tickUpper, bytes data) external
```

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

### ChangeRange

```solidity
event ChangeRange(address nfpm, uint256 oldTokenId, uint256 newTokenId, uint256 liquidity, uint256 amount0Added, uint256 amount1Added)
```

### Compound

```solidity
event Compound(int24 tick, uint256 token0Balance, uint256 token1Balance, uint256 totalSupply)
```

### FeeCollected

```solidity
event FeeCollected(address recipient, uint8 feeType, uint256 fees0, uint256 fees1)
```

### mintPosition

```solidity
function mintPosition(address owner, int24 tickLower, int24 tickUpper, uint256 amount0Min, uint256 amount1Min) external returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1)
```

### deposit

```solidity
function deposit(uint256 amount0Desired, uint256 amount1Desired, uint256 amount0Min, uint256 amount1Min, address to) external returns (uint256 shares)
```

### withdraw

```solidity
function withdraw(uint256 shares, address to, uint256 amount0Min, uint256 amount1Min) external returns (uint256 amount0, uint256 amount1)
```

### exit

```solidity
function exit(address to, uint256 amount0Min, uint256 amount1Min) external
```

### rebalance

```solidity
function rebalance(int24 _baseLower, int24 _baseUpper, uint256 decreasedAmount0Min, uint256 decreasedAmount1Min, uint256 amount0Min, uint256 amount1Min) external
```

### compound

```solidity
function compound(uint256 amount0Min, uint256 amount1Min) external
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
function executeExit(contract IKrystalVault vault, uint256 amount0Min, uint256 amount1Min, bytes abiEncodedUserOrder, bytes orderSignature) external
```

### executeCompound

```solidity
function executeCompound(contract IKrystalVault vault, uint256 amount0Min, uint256 amount1Min, bytes abiEncodedUserOrder, bytes orderSignature) external
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

## IKrystalVaultCommon

### VaultConfig

```solidity
struct VaultConfig {
  uint16 platformFeeBasisPoint;
  address platformFeeRecipient;
  uint16 ownerFeeBasisPoint;
}
```

### ZeroAddress

```solidity
error ZeroAddress()
```

### ZeroAmount

```solidity
error ZeroAmount()
```

### IdenticalAddresses

```solidity
error IdenticalAddresses()
```

### ExceededSupply

```solidity
error ExceededSupply()
```

### Unauthorized

```solidity
error Unauthorized()
```

### PoolNotFound

```solidity
error PoolNotFound()
```

### InvalidFee

```solidity
error InvalidFee()
```

### InvalidAddress

```solidity
error InvalidAddress()
```

### InvalidShares

```solidity
error InvalidShares()
```

### InvalidSender

```solidity
error InvalidSender()
```

### InvalidPriceRange

```solidity
error InvalidPriceRange()
```

### InvalidAmount

```solidity
error InvalidAmount()
```

### InvalidOwner

```solidity
error InvalidOwner()
```

### InvalidPosition

```solidity
error InvalidPosition()
```

### InvalidOwnerFee

```solidity
error InvalidOwnerFee()
```

## IKrystalVaultFactory

### Vault

```solidity
struct Vault {
  address owner;
  address krystalVault;
  address nfpm;
  struct INonfungiblePositionManager.MintParams params;
}
```

### VaultCreated

```solidity
event VaultCreated(address owner, address krystalVault, address nfpm, struct INonfungiblePositionManager.MintParams params, uint256 vaultsLength)
```

### createVault

```solidity
function createVault(address nfpm, struct INonfungiblePositionManager.MintParams params, uint16 ownerFeeBasisPoint, string name, string symbol) external returns (address krystalVault)
```

## IOptimalSwapper

### optimalSwap

```solidity
function optimalSwap(address pool, uint256 amount0, uint256 amount1, int24 tickLower, int24 tickUpper, bytes data) external
```

## OptimalSwap

Optimal library for optimal double-sided Uniswap v3 liquidity provision using closed form solution

### MAX_FEE_PIPS

```solidity
uint256 MAX_FEE_PIPS
```

### Invalid_Pool

```solidity
error Invalid_Pool()
```

### Invalid_Tick_Range

```solidity
error Invalid_Tick_Range()
```

### Math_Overflow

```solidity
error Math_Overflow()
```

### SwapState

```solidity
struct SwapState {
  uint128 liquidity;
  uint256 sqrtPriceX96;
  int24 tick;
  uint256 amount0Desired;
  uint256 amount1Desired;
  uint256 sqrtRatioLowerX96;
  uint256 sqrtRatioUpperX96;
  uint256 feePips;
  int24 tickSpacing;
}
```

### getOptimalSwap

```solidity
function getOptimalSwap(V3PoolCallee pool, int24 tickLower, int24 tickUpper, uint256 amount0Desired, uint256 amount1Desired) internal view returns (uint256 amountIn, uint256 amountOut, bool zeroForOne, uint160 sqrtPriceX96)
```

Get swap amount, output amount, swap direction for double-sided optimal deposit

_Given the elegant analytic solution and custom optimizations to Uniswap libraries,
the amount of gas is at the order of 10k depending on the swap amount and the number of ticks crossed,
an order of magnitude less than that achieved by binary search, which can be calculated on-chain._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pool | V3PoolCallee | Uniswap v3 pool |
| tickLower | int24 | The lower tick of the position in which to add liquidity |
| tickUpper | int24 | The upper tick of the position in which to add liquidity |
| amount0Desired | uint256 | The desired amount of token0 to be spent |
| amount1Desired | uint256 | The desired amount of token1 to be spent |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| amountIn | uint256 | The optimal swap amount |
| amountOut | uint256 | Expected output amount |
| zeroForOne | bool | The direction of the swap, true for token0 to token1, false for token1 to token0 |
| sqrtPriceX96 | uint160 | The sqrt(price) after the swap |

### isZeroForOne

```solidity
function isZeroForOne(uint256 amount0Desired, uint256 amount1Desired, uint256 sqrtPriceX96, uint256 sqrtRatioLowerX96, uint256 sqrtRatioUpperX96) internal pure returns (bool)
```

_Swap direction to achieve optimal deposit_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| amount0Desired | uint256 | The desired amount of token0 to be spent |
| amount1Desired | uint256 | The desired amount of token1 to be spent |
| sqrtPriceX96 | uint256 | sqrt(price) at the last tick of optimal swap |
| sqrtRatioLowerX96 | uint256 | The lower sqrt(price) of the position in which to add liquidity |
| sqrtRatioUpperX96 | uint256 | The upper sqrt(price) of the position in which to add liquidity |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bool | The direction of the swap, true for token0 to token1, false for token1 to token0 |

## StructHash

### _hash

```solidity
function _hash(bytes abiEncodedUserOrder) internal pure returns (bytes32)
```

### RebalanceAutoCompound_TYPEHASH

```solidity
bytes32 RebalanceAutoCompound_TYPEHASH
```

### RebalanceAutoCompound

```solidity
struct RebalanceAutoCompound {
  struct StructHash.RebalanceAutoCompoundAction action;
}
```

### _hash

```solidity
function _hash(struct StructHash.RebalanceAutoCompound obj) internal pure returns (bytes32)
```

### RebalanceAutoCompoundAction_TYPEHASH

```solidity
bytes32 RebalanceAutoCompoundAction_TYPEHASH
```

### RebalanceAutoCompoundAction

```solidity
struct RebalanceAutoCompoundAction {
  int256 maxGasProportionX64;
  int256 feeToPrincipalRatioThresholdX64;
}
```

### _hash

```solidity
function _hash(struct StructHash.RebalanceAutoCompoundAction obj) internal pure returns (bytes32)
```

### TickOffsetCondition_TYPEHASH

```solidity
bytes32 TickOffsetCondition_TYPEHASH
```

### TickOffsetCondition

```solidity
struct TickOffsetCondition {
  uint32 gteTickOffset;
  uint32 lteTickOffset;
}
```

### _hash

```solidity
function _hash(struct StructHash.TickOffsetCondition obj) internal pure returns (bytes32)
```

### PriceOffsetCondition_TYPEHASH

```solidity
bytes32 PriceOffsetCondition_TYPEHASH
```

### PriceOffsetCondition

```solidity
struct PriceOffsetCondition {
  uint32 baseToken;
  uint256 gteOffsetSqrtPriceX96;
  uint256 lteOffsetSqrtPriceX96;
}
```

### _hash

```solidity
function _hash(struct StructHash.PriceOffsetCondition obj) internal pure returns (bytes32)
```

### TokenRatioCondition_TYPEHASH

```solidity
bytes32 TokenRatioCondition_TYPEHASH
```

### TokenRatioCondition

```solidity
struct TokenRatioCondition {
  int256 lteToken0RatioX64;
  int256 gteToken0RatioX64;
}
```

### _hash

```solidity
function _hash(struct StructHash.TokenRatioCondition obj) internal pure returns (bytes32)
```

### Condition_TYPEHASH

```solidity
bytes32 Condition_TYPEHASH
```

### Condition

```solidity
struct Condition {
  string _type;
  int160 sqrtPriceX96;
  int64 timeBuffer;
  struct StructHash.TickOffsetCondition tickOffsetCondition;
  struct StructHash.PriceOffsetCondition priceOffsetCondition;
  struct StructHash.TokenRatioCondition tokenRatioCondition;
}
```

### _hash

```solidity
function _hash(struct StructHash.Condition obj) internal pure returns (bytes32)
```

### TickOffsetAction_TYPEHASH

```solidity
bytes32 TickOffsetAction_TYPEHASH
```

### TickOffsetAction

```solidity
struct TickOffsetAction {
  uint32 tickLowerOffset;
  uint32 tickUpperOffset;
}
```

### _hash

```solidity
function _hash(struct StructHash.TickOffsetAction obj) internal pure returns (bytes32)
```

### PriceOffsetAction_TYPEHASH

```solidity
bytes32 PriceOffsetAction_TYPEHASH
```

### PriceOffsetAction

```solidity
struct PriceOffsetAction {
  uint32 baseToken;
  int160 lowerOffsetSqrtPriceX96;
  int160 upperOffsetSqrtPriceX96;
}
```

### _hash

```solidity
function _hash(struct StructHash.PriceOffsetAction obj) internal pure returns (bytes32)
```

### TokenRatioAction_TYPEHASH

```solidity
bytes32 TokenRatioAction_TYPEHASH
```

### TokenRatioAction

```solidity
struct TokenRatioAction {
  uint32 tickWidth;
  int256 token0RatioX64;
}
```

### _hash

```solidity
function _hash(struct StructHash.TokenRatioAction obj) internal pure returns (bytes32)
```

### RebalanceAction_TYPEHASH

```solidity
bytes32 RebalanceAction_TYPEHASH
```

### RebalanceAction

```solidity
struct RebalanceAction {
  int256 maxGasProportionX64;
  int256 swapSlippageX64;
  int256 liquiditySlippageX64;
  string _type;
  struct StructHash.TickOffsetAction tickOffsetAction;
  struct StructHash.PriceOffsetAction priceOffsetAction;
  struct StructHash.TokenRatioAction tokenRatioAction;
}
```

### _hash

```solidity
function _hash(struct StructHash.RebalanceAction obj) internal pure returns (bytes32)
```

### RebalanceConfig_TYPEHASH

```solidity
bytes32 RebalanceConfig_TYPEHASH
```

### RebalanceConfig

```solidity
struct RebalanceConfig {
  struct StructHash.Condition rebalanceCondition;
  struct StructHash.RebalanceAction rebalanceAction;
  struct StructHash.RebalanceAutoCompound autoCompound;
  bool recurring;
}
```

### _hash

```solidity
function _hash(struct StructHash.RebalanceConfig obj) internal pure returns (bytes32)
```

### RangeOrderCondition_TYPEHASH

```solidity
bytes32 RangeOrderCondition_TYPEHASH
```

### RangeOrderCondition

```solidity
struct RangeOrderCondition {
  bool zeroToOne;
  int32 gteTickAbsolute;
  int32 lteTickAbsolute;
}
```

### _hash

```solidity
function _hash(struct StructHash.RangeOrderCondition obj) internal pure returns (bytes32)
```

### RangeOrderAction_TYPEHASH

```solidity
bytes32 RangeOrderAction_TYPEHASH
```

### RangeOrderAction

```solidity
struct RangeOrderAction {
  int256 maxGasProportionX64;
  int256 swapSlippageX64;
  int256 withdrawSlippageX64;
}
```

### _hash

```solidity
function _hash(struct StructHash.RangeOrderAction obj) internal pure returns (bytes32)
```

### RangeOrderConfig_TYPEHASH

```solidity
bytes32 RangeOrderConfig_TYPEHASH
```

### RangeOrderConfig

```solidity
struct RangeOrderConfig {
  struct StructHash.RangeOrderCondition condition;
  struct StructHash.RangeOrderAction action;
}
```

### _hash

```solidity
function _hash(struct StructHash.RangeOrderConfig obj) internal pure returns (bytes32)
```

### FeeBasedCondition_TYPEHASH

```solidity
bytes32 FeeBasedCondition_TYPEHASH
```

### FeeBasedCondition

```solidity
struct FeeBasedCondition {
  int256 minFeeEarnedUsdX64;
}
```

### _hash

```solidity
function _hash(struct StructHash.FeeBasedCondition obj) internal pure returns (bytes32)
```

### TimeBasedCondition_TYPEHASH

```solidity
bytes32 TimeBasedCondition_TYPEHASH
```

### TimeBasedCondition

```solidity
struct TimeBasedCondition {
  int256 intervalInSecond;
}
```

### _hash

```solidity
function _hash(struct StructHash.TimeBasedCondition obj) internal pure returns (bytes32)
```

### AutoCompoundCondition_TYPEHASH

```solidity
bytes32 AutoCompoundCondition_TYPEHASH
```

### AutoCompoundCondition

```solidity
struct AutoCompoundCondition {
  string _type;
  struct StructHash.FeeBasedCondition feeBasedCondition;
  struct StructHash.TimeBasedCondition timeBasedCondition;
}
```

### _hash

```solidity
function _hash(struct StructHash.AutoCompoundCondition obj) internal pure returns (bytes32)
```

### AutoCompoundAction_TYPEHASH

```solidity
bytes32 AutoCompoundAction_TYPEHASH
```

### AutoCompoundAction

```solidity
struct AutoCompoundAction {
  int256 maxGasProportionX64;
  int256 poolSlippageX64;
  int256 swapSlippageX64;
}
```

### _hash

```solidity
function _hash(struct StructHash.AutoCompoundAction obj) internal pure returns (bytes32)
```

### AutoCompoundConfig_TYPEHASH

```solidity
bytes32 AutoCompoundConfig_TYPEHASH
```

### AutoCompoundConfig

```solidity
struct AutoCompoundConfig {
  struct StructHash.AutoCompoundCondition condition;
  struct StructHash.AutoCompoundAction action;
}
```

### _hash

```solidity
function _hash(struct StructHash.AutoCompoundConfig obj) internal pure returns (bytes32)
```

### AutoExitConfig_TYPEHASH

```solidity
bytes32 AutoExitConfig_TYPEHASH
```

### AutoExitConfig

```solidity
struct AutoExitConfig {
  struct StructHash.Condition condition;
  struct StructHash.AutoExitAction action;
}
```

### _hash

```solidity
function _hash(struct StructHash.AutoExitConfig obj) internal pure returns (bytes32)
```

### AutoExitAction_TYPEHASH

```solidity
bytes32 AutoExitAction_TYPEHASH
```

### AutoExitAction

```solidity
struct AutoExitAction {
  int256 maxGasProportionX64;
  int256 swapSlippageX64;
  int256 liquiditySlippageX64;
  address tokenOutAddress;
}
```

### _hash

```solidity
function _hash(struct StructHash.AutoExitAction obj) internal pure returns (bytes32)
```

### OrderConfig_TYPEHASH

```solidity
bytes32 OrderConfig_TYPEHASH
```

### OrderConfig

```solidity
struct OrderConfig {
  struct StructHash.RebalanceConfig rebalanceConfig;
  struct StructHash.RangeOrderConfig rangeOrderConfig;
  struct StructHash.AutoCompoundConfig autoCompoundConfig;
  struct StructHash.AutoExitConfig autoExitConfig;
}
```

### _hash

```solidity
function _hash(struct StructHash.OrderConfig obj) internal pure returns (bytes32)
```

### Order_TYPEHASH

```solidity
bytes32 Order_TYPEHASH
```

### Order

```solidity
struct Order {
  int64 chainId;
  address nfpmAddress;
  uint256 tokenId;
  string orderType;
  struct StructHash.OrderConfig config;
  int64 signatureTime;
}
```

### _hash

```solidity
function _hash(struct StructHash.Order obj) internal pure returns (bytes32)
```

## StructHashEncoder

### encode

```solidity
function encode(struct StructHash.Order order) external pure returns (bytes b)
```

## TestERC20

### constructor

```solidity
constructor(uint256 amountToMint) public
```

