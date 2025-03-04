// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import { IKrystalVault } from "./IKrystalVault.sol";

interface IKrystalVaultZapper {
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
    FeeType feeType;
  }

  struct DeductFeesParams {
    uint256 amount0;
    uint256 amount1;
    uint256 amount2;
    uint64 feeX64;
    FeeType feeType;
    // readonly params for emitting events
    address vaultFactory;
    address vault;
    address nfpm;
    uint256 tokenId;
    address userAddress;
    address token0;
    address token1;
    address token2;
  }

  struct SwapAndCreateVaultParams {
    Protocol protocol;
    INonfungiblePositionManager nfpm;
    IERC20 token0;
    IERC20 token1;
    uint24 fee;
    int24 tickLower;
    int24 tickUpper;
    uint64 protocolFeeX64;
    // how much is provided of token0 and token1
    uint256 amount0;
    uint256 amount1;
    uint256 amount2;
    address recipient; // recipient of tokens
    uint256 deadline;
    // source token for swaps (maybe either address(0), token0, token1 or another token)
    // if swapSourceToken is another token than token0 or token1 -> amountIn0 + amountIn1 of swapSourceToken are expected to be available
    IERC20 swapSourceToken;
    // if swapSourceToken needs to be swapped to token0 - set values
    uint256 amountIn0;
    uint256 amountOut0Min;
    bytes swapData0;
    // if swapSourceToken needs to be swapped to token1 - set values
    uint256 amountIn1;
    uint256 amountOut1Min;
    bytes swapData1;
    // min amount to be added after swap
    uint256 amountAddMin0;
    uint256 amountAddMin1;
  }

  error AmountError();

  error SlippageError();

  error EtherSendFailed();

  error NotSupportedProtocol();

  error TransferError();

  error ResetApproveFailed();

  error NoEtherToken();

  error TooMuchEtherSent();

  error TooMuchFee();

  error NoFees();

  error SameToken();

  error InvalidApproval();

  event Swap(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

  event VaultDeductFees(
    address indexed vault,
    address indexed nfpm,
    uint256 indexed tokenId,
    address userAddress,
    DeductFeesEventData data
  );

  enum FeeType {
    GAS_FEE,
    LIQUIDITY_FEE,
    PERFORMANCE_FEE
  }

  enum Protocol {
    UNI_V3,
    ALGEBRA_V1
  }

  function swapAndCreateVault(
    SwapAndCreateVaultParams memory params,
    uint16 ownerFeeBasisPoint,
    string memory vaultName,
    string memory vaultSymbol
  ) external payable returns (address);

  /// @notice Params for swapAndIncreaseLiquidity() function
  struct SwapAndDepositParams {
    Protocol protocol;
    IKrystalVault vault;
    uint256 amount0;
    uint256 amount1;
    uint256 amount2;
    address recipient; // recipient of leftover tokens
    uint256 deadline;
    // source token for swaps (maybe either address(0), token0, token1 or another token)
    // if swapSourceToken is another token than token0 or token1 -> amountIn0 + amountIn1 of swapSourceToken are expected to be available
    IERC20 swapSourceToken;
    // if swapSourceToken needs to be swapped to token0 - set values
    uint256 amountIn0;
    uint256 amountOut0Min;
    bytes swapData0;
    // if swapSourceToken needs to be swapped to token1 - set values
    uint256 amountIn1;
    uint256 amountOut1Min;
    bytes swapData1;
    // min amount to be added after swap
    uint256 amountAddMin0;
    uint256 amountAddMin1;
    uint64 protocolFeeX64;
  }

  function swapAndDeposit(SwapAndDepositParams memory params) external payable returns (uint256 shares);

  struct SwapOutParams {
    address token0;
    address token1;
    address targetToken;
    bool unwrap;
  }

  function withdrawAndSwap(
    IKrystalVault vault,
    uint256 shares,
    address to,
    uint256 amount0Min,
    uint256 amount1Min,
    bytes calldata swapData
  ) external;
}
