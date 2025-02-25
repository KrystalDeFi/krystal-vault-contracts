# Solidity API

## IWETH9

### deposit

```solidity
function deposit() external payable
```

Deposit ether to get wrapped ether

### withdraw

```solidity
function withdraw(uint256) external
```

Withdraw wrapped ether to get ether

## KrysalVaultZapper

### WITHDRAWER_ROLE

```solidity
bytes32 WITHDRAWER_ROLE
```

### ADMIN_ROLE

```solidity
bytes32 ADMIN_ROLE
```

### vaultFactory

```solidity
contract IKrystalVaultFactory vaultFactory
```

### swapRouter

```solidity
address swapRouter
```

### feeTaker

```solidity
address feeTaker
```

### constructor

```solidity
constructor(address _vaultFactory, address _swapRouter, address _admin, address _withdrawer, address _feeTaker) public
```

### swapAndCreateVault

```solidity
function swapAndCreateVault(struct IKrystalVaultZapper.SwapAndCreateVaultParams params, uint16 ownerFeeBasisPoint, string vaultName, string vaultSymbol, bool unwrap) external returns (address vault)
```

Does 1 or 2 swaps from swapSourceToken to token0 and token1 and adds as much as possible liquidity to a newly created vault

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IKrystalVaultZapper.SwapAndCreateVaultParams | Swap and create vault |
| ownerFeeBasisPoint | uint16 | Owner fee in basic points |
| vaultName | string | Name of the vault |
| vaultSymbol | string | Symbol of the vault |
| unwrap | bool |  |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| vault | address | Address of the newly created vault |

### swapAndDeposit

```solidity
function swapAndDeposit(struct IKrystalVaultZapper.SwapAndDepositParams params) external
```

Does 1 or 2 swaps from swapSourceToken to token0 and token1 and adds as much as possible liquidity to an existing vault

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct IKrystalVaultZapper.SwapAndDepositParams | Swap and add to vault Send left-over to recipient |

### withdrawAndSwap

```solidity
function withdrawAndSwap() external
```

### _swapAndPrepareAmounts

```solidity
function _swapAndPrepareAmounts(struct IKrystalVaultZapper.SwapAndCreateVaultParams params, bool unwrap) internal returns (uint256 total0, uint256 total1)
```

### _swap

```solidity
function _swap(contract IERC20 tokenIn, contract IERC20 tokenOut, uint256 amountIn, uint256 amountOutMin, bytes swapData) internal returns (uint256 amountInDelta, uint256 amountOutDelta)
```

### _safeResetAndApprove

```solidity
function _safeResetAndApprove(contract IERC20 token, address _spender, uint256 _value) internal
```

_some tokens require allowance == 0 to approve new amount
but some tokens does not allow approve amount = 0
we try to set allowance = 0 before approve new amount. if it revert means that
the token not allow to approve 0, which means the following line code will work properly_

### _safeApprove

```solidity
function _safeApprove(contract IERC20 token, address _spender, uint256 _value) internal
```

### _transferToken

```solidity
function _transferToken(contract IWETH9 weth, address to, contract IERC20 token, uint256 amount, bool unwrap) internal
```

### _getWeth9

```solidity
function _getWeth9(address nfpm, enum IKrystalVaultZapper.Protocol) internal view returns (contract IWETH9 weth)
```

### _prepareSwap

```solidity
function _prepareSwap(contract IWETH9 weth, contract IERC20 token0, contract IERC20 token1, contract IERC20 otherToken, uint256 amount0, uint256 amount1, uint256 amountOther) internal
```

### DeductFeesEventData

```solidity
struct DeductFeesEventData {
  address token0;
  address token1;
  address token2;
  uint256 amount0;
  uint256 amount1;
  uint256 amount2;
  uint256 feeAmount0;
  uint256 feeAmount1;
  uint256 feeAmount2;
  uint64 feeX64;
  enum KrysalVaultZapper.FeeType feeType;
}
```

### DeductFees

```solidity
event DeductFees(address nfpm, uint256 tokenId, address userAddress, struct KrysalVaultZapper.DeductFeesEventData data)
```

### FeeType

```solidity
enum FeeType {
  GAS_FEE,
  LIQUIDITY_FEE,
  PERFORMANCE_FEE
}
```

### DeductFeesParams

```solidity
struct DeductFeesParams {
  uint256 amount0;
  uint256 amount1;
  uint256 amount2;
  uint64 feeX64;
  enum KrysalVaultZapper.FeeType feeType;
  address nfpm;
  uint256 tokenId;
  address userAddress;
  address token0;
  address token1;
  address token2;
}
```

### _deductFees

```solidity
function _deductFees(struct KrysalVaultZapper.DeductFeesParams params, bool emitEvent) internal returns (uint256 amount0Left, uint256 amount1Left, uint256 amount2Left, uint256 feeAmount0, uint256 feeAmount1, uint256 feeAmount2)
```

calculate fee

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| params | struct KrysalVaultZapper.DeductFeesParams |  |
| emitEvent | bool |  |

