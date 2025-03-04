// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

import { IKrystalVaultFactory } from "./interfaces/IKrystalVaultFactory.sol";
import "./interfaces/IKrystalVaultZapper.sol";
import "./interfaces/IWETH9.sol";

contract KrystalVaultZapper is AccessControl, IKrystalVaultZapper {
  bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");
  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  uint256 public constant Q64 = 2 ** 64;

  IKrystalVaultFactory public vaultFactory;
  address public swapRouter;
  address public feeTaker;
  mapping(FeeType => uint64) private _maxFeeX64;

  constructor(address _vaultFactory, address _swapRouter, address _admin, address _withdrawer, address _feeTaker) {
    vaultFactory = IKrystalVaultFactory(_vaultFactory);
    swapRouter = _swapRouter;
    feeTaker = _feeTaker;

    _grantRole(ADMIN_ROLE, _admin);
    _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    _grantRole(WITHDRAWER_ROLE, _withdrawer);
    _grantRole(DEFAULT_ADMIN_ROLE, _withdrawer);

    _maxFeeX64[FeeType.GAS_FEE] = 5534023222112865280; // 30%
    _maxFeeX64[FeeType.LIQUIDITY_FEE] = 5534023222112865280; // 30%
    _maxFeeX64[FeeType.PERFORMANCE_FEE] = 3689348814741910528; // 20%
  }

  /// @notice Does 1 or 2 swaps from swapSourceToken to token0 and token1 and adds as much as possible liquidity to a newly created vault
  /// @param params Swap and create vault
  /// @param ownerFeeBasisPoint Owner fee in basic points
  /// @param vaultName Name of the vault
  /// @param vaultSymbol Symbol of the vault
  /// @return vault Address of the newly created vault
  function swapAndCreateVault(
    SwapAndCreateVaultParams calldata params,
    uint16 ownerFeeBasisPoint,
    string memory vaultName,
    string memory vaultSymbol
  ) external payable override returns (address vault) {
    if (params.token0 == params.token1) {
      revert SameToken();
    }
    IWETH9 weth = _getWeth9(address(params.nfpm), params.protocol);

    // validate if amount2 is enough for action
    if (
      params.swapSourceToken != params.token0 &&
      params.swapSourceToken != params.token1 &&
      params.amountIn0 + params.amountIn1 > params.amount2
    ) {
      revert AmountError();
    }
    _prepareSwap(
      weth,
      params.token0,
      params.token1,
      params.swapSourceToken,
      params.amount0,
      params.amount1,
      params.amount2
    );
    SwapAndCreateVaultParams memory _params = params;

    DeductFeesEventData memory eventData;
    if (params.protocolFeeX64 > 0) {
      uint256 feeAmount0;
      uint256 feeAmount1;
      uint256 feeAmount2;
      // since we do not have the tokenId here, we need to emit event later
      (_params.amount0, _params.amount1, _params.amount2, feeAmount0, feeAmount1, feeAmount2) = _deductFees(
        DeductFeesParams(
          params.amount0,
          params.amount1,
          params.amount2,
          params.protocolFeeX64,
          FeeType.LIQUIDITY_FEE,
          address(0),
          address(0),
          address(params.nfpm),
          0,
          params.recipient,
          address(params.token0),
          address(params.token1),
          address(params.swapSourceToken)
        ),
        false
      );

      eventData = DeductFeesEventData({
        token0: address(params.token0),
        token1: address(params.token1),
        token2: address(params.swapSourceToken),
        amount0: params.amount0,
        amount1: params.amount1,
        amount2: params.amount2,
        feeAmount0: feeAmount0,
        feeAmount1: feeAmount1,
        feeAmount2: feeAmount2,
        feeX64: params.protocolFeeX64,
        feeType: FeeType.LIQUIDITY_FEE
      });
    }
    // Implement zapIn logic
    (uint256 total0, uint256 total1) = _swapAndPrepareAmounts(
      SwapAndPrepareAmountsParams(
        weth,
        _params.token0,
        _params.token1,
        _params.amount0,
        _params.amount1,
        _params.amount2,
        _params.recipient,
        _params.deadline,
        _params.swapSourceToken,
        _params.amountIn0,
        _params.amountOut0Min,
        _params.swapData0,
        _params.amountIn1,
        _params.amountOut1Min,
        _params.swapData1
      ),
      msg.value != 0
    );

    if (total0 != 0) {
      _safeResetAndApprove(params.token0, address(vaultFactory), total0);
    }
    if (total1 != 0) {
      _safeResetAndApprove(params.token1, address(vaultFactory), total1);
    }

    vault = vaultFactory.createVault(
      IKrystalVaultFactory.CreateVaultParams({
        owner: msg.sender,
        nfpm: address(_params.nfpm),
        mintParams: INonfungiblePositionManager.MintParams(
          address(_params.token0),
          address(_params.token1),
          _params.fee,
          _params.tickLower,
          _params.tickUpper,
          total0,
          total1,
          _params.amountAddMin0,
          _params.amountAddMin1,
          address(this), // is sent to real recipient aftwards
          _params.deadline
        ),
        ownerFeeBasisPoint: ownerFeeBasisPoint,
        name: vaultName,
        symbol: vaultSymbol
      })
    );

    (, , , , uint256 currentTokenId, , , , ) = IKrystalVault(vault).state();
    emit VaultDeductFees(vault, address(params.nfpm), currentTokenId, params.recipient, eventData);
  }

  function _swapAndCreateVault(
    SwapAndCreateVaultParams memory params,
    uint16 ownerFeeBasisPoint,
    string memory vaultName,
    string memory vaultSymbol,
    bool unwrap
  ) internal returns (address vault) {
  }

  /// @notice Does 1 or 2 swaps from swapSourceToken to token0 and token1 and adds as much as possible liquidity to an existing vault
  /// @param params Swap and add to vault
  /// Send left-over to recipient
  function swapAndDeposit(SwapAndDepositParams memory params) external payable returns (uint256 shares) {
    (, INonfungiblePositionManager nfpm, IERC20 token0, IERC20 token1, uint256 currentTokenId, , , , ) = params
      .vault
      .state();
    IWETH9 weth = _getWeth9(address(nfpm), params.protocol);

    // validate if amount2 is enough for action
    if (
      params.swapSourceToken != token0 &&
      params.swapSourceToken != token1 &&
      params.amountIn0 + params.amountIn1 > params.amount2
    ) {
      revert AmountError();
    }

    _prepareSwap(
      weth,
      IERC20(token0),
      IERC20(token1),
      params.swapSourceToken,
      params.amount0,
      params.amount1,
      params.amount2
    );
    SwapAndDepositParams memory _params = params;
    if (params.protocolFeeX64 > 0) {
      (_params.amount0, _params.amount1, _params.amount2, , , ) = _deductFees(
        DeductFeesParams(
          params.amount0,
          params.amount1,
          params.amount2,
          params.protocolFeeX64,
          FeeType.LIQUIDITY_FEE,
          address(vaultFactory),
          address(params.vault),
          address(nfpm),
          currentTokenId,
          params.recipient,
          address(token0),
          address(token1),
          address(params.swapSourceToken)
        ),
        true
      );
    }

    (uint256 total0, uint256 total1) = _swapAndPrepareAmounts(
      SwapAndPrepareAmountsParams(
        _getWeth9(address(nfpm), params.protocol),
        token0,
        token1,
        params.amount0,
        params.amount1,
        params.amount2,
        params.recipient,
        params.deadline,
        params.swapSourceToken,
        params.amountIn0,
        params.amountOut0Min,
        params.swapData0,
        params.amountIn1,
        params.amountOut1Min,
        params.swapData1
      ),
      msg.value != 0
    );

    if (total0 != 0) {
      _safeResetAndApprove(token0, address(params.vault), total0);
    }
    if (total1 != 0) {
      _safeResetAndApprove(token1, address(params.vault), total1);
    }

    shares = params.vault.deposit(total0, total1, params.amountAddMin0, params.amountAddMin1, msg.sender);
  }

  function withdrawAndSwap(
    IKrystalVault vault,
    uint256 shares,
    address to,
    uint256 amount0Min,
    uint256 amount1Min,
    bytes calldata swapData
  ) external {
    // Implement withdrawAndSwap logic
    require(shares > 0, AmountError());
    IERC20(address(vault)).transferFrom(msg.sender, address(this), shares);

    (uint256 amount0, uint256 amount1) = vault.withdraw(shares, address(this), amount0Min, amount1Min);
  }

  struct SwapAndPrepareAmountsParams {
    IWETH9 weth;
    IERC20 token0;
    IERC20 token1;
    uint256 amount0;
    uint256 amount1;
    uint256 amount2;
    address recipient;
    uint256 deadline;
    IERC20 swapSourceToken;
    uint256 amountIn0;
    uint256 amountOut0Min;
    bytes swapData0;
    uint256 amountIn1;
    uint256 amountOut1Min;
    bytes swapData1;
  }

  function exitAndSwap() external {
    // Implement exitAndSwap logic
  }

  // swaps available tokens and prepares max amounts to be added to nfpm
  function _swapAndPrepareAmounts(
    SwapAndPrepareAmountsParams memory params,
    bool unwrap
  ) internal returns (uint256 total0, uint256 total1) {
    if (params.swapSourceToken == params.token0) {
      if (params.amount0 < params.amountIn1) {
        revert AmountError();
      }
      (uint256 amountInDelta, uint256 amountOutDelta) = _swap(
        params.token0,
        params.token1,
        params.amountIn1,
        params.amountOut1Min,
        params.swapData1
      );
      total0 = params.amount0 - amountInDelta;
      total1 = params.amount1 + amountOutDelta;
    } else if (params.swapSourceToken == params.token1) {
      if (params.amount1 < params.amountIn0) {
        revert AmountError();
      }
      (uint256 amountInDelta, uint256 amountOutDelta) = _swap(
        params.token1,
        params.token0,
        params.amountIn0,
        params.amountOut0Min,
        params.swapData0
      );
      total1 = params.amount1 - amountInDelta;
      total0 = params.amount0 + amountOutDelta;
    } else if (address(params.swapSourceToken) != address(0)) {
      (uint256 amountInDelta0, uint256 amountOutDelta0) = _swap(
        params.swapSourceToken,
        params.token0,
        params.amountIn0,
        params.amountOut0Min,
        params.swapData0
      );
      (uint256 amountInDelta1, uint256 amountOutDelta1) = _swap(
        params.swapSourceToken,
        params.token1,
        params.amountIn1,
        params.amountOut1Min,
        params.swapData1
      );
      total0 = params.amount0 + amountOutDelta0;
      total1 = params.amount1 + amountOutDelta1;

      if (params.amount2 < amountInDelta0 + amountInDelta1) {
        revert AmountError();
      }
      // return third token leftover if any
      uint256 leftOver = params.amount2 - amountInDelta0 - amountInDelta1;

      if (leftOver != 0) {
        // IWETH9 weth = _getWeth9(address(params.nfpm), params.protocol);
        _transferToken(params.weth, params.recipient, params.swapSourceToken, leftOver, unwrap);
      }
    } else {
      total0 = params.amount0;
      total1 = params.amount1;
    }
  }

  // general swap function which uses external router with off-chain calculated swap instructions
  // does slippage check with amountOutMin param
  // returns token amounts deltas after swap
  function _swap(
    IERC20 tokenIn,
    IERC20 tokenOut,
    uint256 amountIn,
    uint256 amountOutMin,
    bytes memory swapData
  ) internal returns (uint256 amountInDelta, uint256 amountOutDelta) {
    if (amountIn != 0 && swapData.length != 0 && address(tokenOut) != address(0)) {
      uint256 balanceInBefore = tokenIn.balanceOf(address(this));
      uint256 balanceOutBefore = tokenOut.balanceOf(address(this));

      // approve needed amount
      _safeApprove(tokenIn, swapRouter, amountIn);
      // execute swap
      (bool success, bytes memory data) = swapRouter.call(swapData);
      if (!success) {
        assembly {
          revert(add(32, data), mload(data))
        }
      }

      // reset approval
      _safeApprove(tokenIn, swapRouter, 0);

      uint256 balanceInAfter = tokenIn.balanceOf(address(this));
      uint256 balanceOutAfter = tokenOut.balanceOf(address(this));

      amountInDelta = balanceInBefore - balanceInAfter;
      amountOutDelta = balanceOutAfter - balanceOutBefore;

      // amountMin slippage check
      if (amountOutDelta < amountOutMin) {
        revert SlippageError();
      }

      // event for any swap with exact swapped value
      emit Swap(address(tokenIn), address(tokenOut), amountInDelta, amountOutDelta);
    }
  }

  /// @dev some tokens require allowance == 0 to approve new amount
  /// but some tokens does not allow approve amount = 0
  /// we try to set allowance = 0 before approve new amount. if it revert means that
  /// the token not allow to approve 0, which means the following line code will work properly
  function _safeResetAndApprove(IERC20 token, address _spender, uint256 _value) internal {
    /// @dev omitted approve(0) result because it might fail and does not break the flow
    (bool success, ) = address(token).call(abi.encodeWithSelector(token.approve.selector, _spender, 0));
    require(success, ResetApproveFailed());

    /// @dev value for approval after reset must greater than 0
    require(_value > 0, InvalidApproval());
    _safeApprove(token, _spender, _value);
  }

  function _safeApprove(IERC20 token, address _spender, uint256 _value) internal {
    (bool success, bytes memory returnData) = address(token).call(
      abi.encodeWithSelector(token.approve.selector, _spender, _value)
    );
    if (_value == 0) {
      // some token does not allow approve(0) so we skip check for this case
      return;
    }
    require(success && (returnData.length == 0 || abi.decode(returnData, (bool))), "SafeERC20: approve failed");
  }

  // transfers token (or unwraps WETH and sends ETH)
  function _transferToken(IWETH9 weth, address to, IERC20 token, uint256 amount, bool unwrap) internal {
    if (address(weth) == address(token) && unwrap) {
      weth.withdraw(amount);
      (bool sent, ) = to.call{ value: amount }("");
      if (!sent) {
        revert EtherSendFailed();
      }
    } else {
      SafeERC20.safeTransfer(token, to, amount);
    }
  }

  function _getWeth9(address nfpm, Protocol /*protocol*/) internal view returns (IWETH9 weth) {
    weth = IWETH9(INonfungiblePositionManager(nfpm).WETH9());
  }

  // checks if required amounts are provided and are exact - wraps any provided ETH as WETH
  // if less or more provided reverts
  function _prepareSwap(
    IWETH9 weth,
    IERC20 token0,
    IERC20 token1,
    IERC20 otherToken,
    uint256 amount0,
    uint256 amount1,
    uint256 amountOther
  ) internal {
    uint256 amountAdded0;
    uint256 amountAdded1;
    uint256 amountAddedOther;

    // wrap ether sent
    if (msg.value != 0) {
      weth.deposit{ value: msg.value }();

      if (address(weth) == address(token0)) {
        amountAdded0 = msg.value;
        if (amountAdded0 > amount0) {
          revert TooMuchEtherSent();
        }
      } else if (address(weth) == address(token1)) {
        amountAdded1 = msg.value;
        if (amountAdded1 > amount1) {
          revert TooMuchEtherSent();
        }
      } else if (address(weth) == address(otherToken)) {
        amountAddedOther = msg.value;
        if (amountAddedOther > amountOther) {
          revert TooMuchEtherSent();
        }
      } else {
        revert NoEtherToken();
      }
    }

    // get missing tokens (fails if not enough provided)
    if (amount0 > amountAdded0) {
      uint256 balanceBefore = token0.balanceOf(address(this));
      SafeERC20.safeTransferFrom(token0, msg.sender, address(this), amount0 - amountAdded0);
      uint256 balanceAfter = token0.balanceOf(address(this));
      if (balanceAfter - balanceBefore != amount0 - amountAdded0) {
        revert TransferError(); // reverts for fee-on-transfer tokens
      }
    }
    if (amount1 > amountAdded1) {
      uint256 balanceBefore = token1.balanceOf(address(this));
      SafeERC20.safeTransferFrom(token1, msg.sender, address(this), amount1 - amountAdded1);
      uint256 balanceAfter = token1.balanceOf(address(this));
      if (balanceAfter - balanceBefore != amount1 - amountAdded1) {
        revert TransferError(); // reverts for fee-on-transfer tokens
      }
    }
    if (
      amountOther > amountAddedOther &&
      address(otherToken) != address(0) &&
      token0 != otherToken &&
      token1 != otherToken
    ) {
      uint256 balanceBefore = otherToken.balanceOf(address(this));
      SafeERC20.safeTransferFrom(otherToken, msg.sender, address(this), amountOther - amountAddedOther);
      uint256 balanceAfter = otherToken.balanceOf(address(this));
      if (balanceAfter - balanceBefore != amountOther - amountAddedOther) {
        revert TransferError(); // reverts for fee-on-transfer tokens
      }
    }
  }

  /**
   * @notice calculate fee
   * @param emitEvent: whether to emit event or not. Since swap and mint have not had token id yet.
   * we need to emit event latter
   */
  function _deductFees(
    DeductFeesParams memory params,
    bool emitEvent
  )
    internal
    returns (
      uint256 amount0Left,
      uint256 amount1Left,
      uint256 amount2Left,
      uint256 feeAmount0,
      uint256 feeAmount1,
      uint256 feeAmount2
    )
  {
    if (params.feeX64 > _maxFeeX64[params.feeType]) {
      revert TooMuchFee();
    }

    // to save gas, we always need to check if fee exists before deductFees
    if (params.feeX64 == 0) {
      revert NoFees();
    }

    if (params.amount0 > 0) {
      feeAmount0 = FullMath.mulDiv(params.amount0, params.feeX64, Q64);
      amount0Left = params.amount0 - feeAmount0;
      if (feeAmount0 > 0) {
        SafeERC20.safeTransfer(IERC20(params.token0), feeTaker, feeAmount0);
      }
    }
    if (params.amount1 > 0) {
      feeAmount1 = FullMath.mulDiv(params.amount1, params.feeX64, Q64);
      amount1Left = params.amount1 - feeAmount1;
      if (feeAmount1 > 0) {
        SafeERC20.safeTransfer(IERC20(params.token1), feeTaker, feeAmount1);
      }
    }
    if (params.amount2 > 0) {
      feeAmount2 = FullMath.mulDiv(params.amount2, params.feeX64, Q64);
      amount2Left = params.amount2 - feeAmount2;
      if (feeAmount2 > 0) {
        SafeERC20.safeTransfer(IERC20(params.token2), feeTaker, feeAmount2);
      }
    }

    if (emitEvent) {
      emit VaultDeductFees(
        address(params.vaultFactory),
        address(params.nfpm),
        params.tokenId,
        params.userAddress,
        DeductFeesEventData(
          params.token0,
          params.token1,
          params.token2,
          params.amount0,
          params.amount1,
          params.amount2,
          feeAmount0,
          feeAmount1,
          feeAmount2,
          params.feeX64,
          params.feeType
        )
      );
    }
  }

  struct ReturnLeftoverTokensParams {
    IWETH9 weth;
    address to;
    IERC20 token0;
    IERC20 token1;
    uint256 total0;
    uint256 total1;
    uint256 added0;
    uint256 added1;
    bool unwrap;
  }
  // returns leftover token balances
  function _returnLeftoverTokens(ReturnLeftoverTokensParams memory params) internal {
    uint256 left0 = params.total0 - params.added0;
    uint256 left1 = params.total1 - params.added1;

    // return leftovers
    if (left0 != 0) {
      _transferToken(params.weth, params.to, params.token0, left0, params.unwrap);
    }
    if (left1 != 0) {
      _transferToken(params.weth, params.to, params.token1, left1, params.unwrap);
    }
  }
}
