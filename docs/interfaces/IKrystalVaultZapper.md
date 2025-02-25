# Solidity API

## IKrystalVaultZapper

### AmountError

```solidity
error AmountError()
```

### SlippageError

```solidity
error SlippageError()
```

### EtherSendFailed

```solidity
error EtherSendFailed()
```

### NotSupportedProtocol

```solidity
error NotSupportedProtocol()
```

### TransferError

```solidity
error TransferError()
```

### NoEtherToken

```solidity
error NoEtherToken()
```

### TooMuchEtherSent

```solidity
error TooMuchEtherSent()
```

### TooMuchFee

```solidity
error TooMuchFee()
```

### NoFees

```solidity
error NoFees()
```

### Swap

```solidity
event Swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut)
```

### Protocol

protocol to provide lp

```solidity
enum Protocol {
  UNI_V3,
  ALGEBRA_V1
}
```

### SwapAndCreateVaultParams

```solidity
struct SwapAndCreateVaultParams {
  enum IKrystalVaultZapper.Protocol protocol;
  contract INonfungiblePositionManager nfpm;
  contract IERC20 token0;
  contract IERC20 token1;
  uint24 fee;
  int24 tickLower;
  int24 tickUpper;
  uint64 protocolFeeX64;
  uint256 amount0;
  uint256 amount1;
  uint256 amount2;
  address recipient;
  uint256 deadline;
  contract IERC20 swapSourceToken;
  uint256 amountIn0;
  uint256 amountOut0Min;
  bytes swapData0;
  uint256 amountIn1;
  uint256 amountOut1Min;
  bytes swapData1;
  uint256 amountAddMin0;
  uint256 amountAddMin1;
}
```

### swapAndCreateVault

```solidity
function swapAndCreateVault(struct IKrystalVaultZapper.SwapAndCreateVaultParams params, uint16 ownerFeeBasisPoint, string vaultName, string vaultSymbol, bool unwrap) external returns (address)
```

### SwapAndDepositParams

Params for swapAndIncreaseLiquidity() function

```solidity
struct SwapAndDepositParams {
  enum IKrystalVaultZapper.Protocol protocol;
  contract IKrystalVault vault;
  uint256 amount0;
  uint256 amount1;
  uint256 amount2;
  address recipient;
  uint256 deadline;
  contract IERC20 swapSourceToken;
  uint256 amountIn0;
  uint256 amountOut0Min;
  bytes swapData0;
  uint256 amountIn1;
  uint256 amountOut1Min;
  bytes swapData1;
  uint256 amountAddMin0;
  uint256 amountAddMin1;
  uint64 protocolFeeX64;
}
```

### swapAndDeposit

```solidity
function swapAndDeposit(struct IKrystalVaultZapper.SwapAndDepositParams params) external
```

