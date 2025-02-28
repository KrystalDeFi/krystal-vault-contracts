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

### SameToken

```solidity
error SameToken()
```

### Swap

```solidity
event Swap(address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut)
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
  enum IKrystalVaultZapper.FeeType feeType;
}
```

### VaultDeductFees

```solidity
event VaultDeductFees(address vault, address nfpm, uint256 tokenId, address userAddress, struct IKrystalVaultZapper.DeductFeesEventData data)
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
  enum IKrystalVaultZapper.FeeType feeType;
  address vaultFactory;
  address vault;
  address nfpm;
  uint256 tokenId;
  address userAddress;
  address token0;
  address token1;
  address token2;
}
```

### Protocol

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
function swapAndCreateVault(struct IKrystalVaultZapper.SwapAndCreateVaultParams params, uint16 ownerFeeBasisPoint, string vaultName, string vaultSymbol) external payable returns (address)
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
function swapAndDeposit(struct IKrystalVaultZapper.SwapAndDepositParams params) external payable
```

