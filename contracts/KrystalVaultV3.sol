// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20PermitUpgradeable.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

import "./interfaces/IKrystalVaultV3.sol";
import "./interfaces/IOptimalSwapper.sol";

/// @title KrystalVaultV3
/// @notice A Uniswap V2-like interface with fungible liquidity to Uniswap V3
/// which allows for arbitrary liquidity provision: one-sided, lop-sided, and balanced
contract KrystalVaultV3 is AccessControlUpgradeable, ERC20PermitUpgradeable, ReentrancyGuard, IKrystalVaultV3 {
  bytes32 public constant ADMIN_ROLE_HASH = keccak256("ADMIN_ROLE");

  uint160 internal constant MAX_SQRT_RATIO_LESS_ONE = 1461446703485210103287273052203988822378723970342 - 1;
  uint160 internal constant XOR_SQRT_RATIO = (4295128739 + 1) ^ (1461446703485210103287273052203988822378723970342 - 1);

  using SafeERC20 for IERC20;

  address public vaultFactory;

  VaultState public state;
  VaultConfig public config;
  IOptimalSwapper public optimalSwapper;

  constructor() {}

  /// @param _nfpm Uniswap V3 nonfungible position manager address
  /// @param _pool Uniswap V3 pool address
  /// @param _owner Owner of the KrystalVaultV3
  /// @param name Name of the KrystalVaultV3
  /// @param symbol Symbol of the KrystalVaultV3
  function initialize(
    address _nfpm,
    address _pool,
    address _owner,
    string memory name,
    string memory symbol,
    uint16 platformFeeBasisPoint,
    address platformFeeRecipient,
    uint16 ownerFeeBasisPoint,
    address _optimalSwapper
  ) public initializer {
    require(_nfpm != address(0), ZeroAddress());
    require(_pool != address(0), ZeroAddress());
    require(_owner != address(0), ZeroAddress());

    __ERC20_init(name, symbol);
    __ERC20Permit_init(name);
    __AccessControl_init();

    _grantRole(DEFAULT_ADMIN_ROLE, _owner);
    _grantRole(ADMIN_ROLE_HASH, _owner);

    vaultFactory = _msgSender();

    optimalSwapper = IOptimalSwapper(_optimalSwapper);

    // platformFeeBasisPoint is in basis points (1% = 100 basis points)
    config = VaultConfig({
      platformFeeBasisPoint: platformFeeBasisPoint,
      platformFeeRecipient: platformFeeRecipient,
      ownerFeeBasisPoint: ownerFeeBasisPoint,
      ownerFeeRecipient: _owner
    });

    state = VaultState({
      pool: IUniswapV3Pool(_pool),
      nfpm: INonfungiblePositionManager(_nfpm),
      token0: IERC20(IUniswapV3Pool(_pool).token0()),
      token1: IERC20(IUniswapV3Pool(_pool).token1()),
      currentTokenId: 0,
      currentTickLower: 0,
      currentTickUpper: 0,
      tickSpacing: IUniswapV3Pool(_pool).tickSpacing(),
      fee: IUniswapV3Pool(_pool).fee()
    });
  }

  modifier onlyVaultFactory() {
    require(vaultFactory == _msgSender(), Unauthorized());
    _;
  }

  /// @notice Mint a new position
  /// @param owner Address of the owner of the position
  /// @param tickLower The lower tick of the base position
  /// @param tickUpper The upper tick of the base position
  /// @param amount0Min Minimum amount of token0 to deposit
  /// @param amount1Min Minimum amount of token1 to deposit
  function mintPosition(
    address owner,
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0Min,
    uint256 amount1Min
  ) external override onlyVaultFactory returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
    require(state.currentTokenId == 0, InvalidPosition());

    uint256 amount0Desired = state.token0.balanceOf(address(this));
    uint256 amount1Desired = state.token1.balanceOf(address(this));

    (uint160 sqrtPrice, , , , , , ) = state.pool.slot0();
    uint256 priceX96 = FullMath.mulDiv(sqrtPrice, sqrtPrice, FixedPoint96.Q96);

    uint256 shares = amount1Desired + (FullMath.mulDiv(amount0Desired, priceX96, FixedPoint96.Q96));

    INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
      token0: address(state.token0),
      token1: address(state.token1),
      fee: state.fee,
      tickLower: tickLower,
      tickUpper: tickUpper,
      amount0Desired: amount0Desired,
      amount1Desired: amount1Desired,
      amount0Min: amount0Min,
      amount1Min: amount1Min,
      recipient: address(this),
      deadline: block.timestamp
    });
    (tokenId, liquidity, amount0, amount1) = _mintLiquidity(params);

    state.currentTickLower = tickLower;
    state.currentTickUpper = tickUpper;

    _mint(owner, shares);

    emit VaultDeposit(owner, shares, amount0, amount1);
  }

  /// @notice Deposit tokens
  /// @param amount0Desired Desired amount of token0 to deposit
  /// @param amount1Desired Desired amount of token1 to deposit
  /// @param amount0Min Minimum amount of token0 to deposit
  /// @param amount1Min Minimum amount of token1 to deposit
  /// @param to Address to which liquidity tokens are sent
  /// @return shares Quantity of liquidity tokens minted as a result of deposit
  function deposit(
    uint256 amount0Desired,
    uint256 amount1Desired,
    uint256 amount0Min,
    uint256 amount1Min,
    address to
  ) external override nonReentrant returns (uint256 shares) {
    require(amount0Desired > 0 || amount1Desired > 0, ZeroAmount());
    require(state.currentTokenId != 0, InvalidPosition());

    if (to == address(0)) {
      to = _msgSender();
    }

    /// update fees
    _collectFees();
    /// optimally swap tokens
    _optimalSwap(state.currentTickLower, state.currentTickUpper);

    (uint160 sqrtPrice, , , , , , ) = state.pool.slot0();
    uint256 priceX96 = FullMath.mulDiv(sqrtPrice, sqrtPrice, FixedPoint96.Q96);

    (uint256 total0, uint256 total1) = getTotalAmounts();
    uint256 total = totalSupply();

    shares =
      ((amount1Desired + FullMath.mulDiv(amount0Desired, priceX96, FixedPoint96.Q96)) * total) /
      (total1 + FullMath.mulDiv(total0, priceX96, FixedPoint96.Q96));

    if (amount0Desired > 0) {
      state.token0.safeTransferFrom(_msgSender(), address(this), amount0Desired);
    }
    if (amount1Desired > 0) {
      state.token1.safeTransferFrom(_msgSender(), address(this), amount1Desired);
    }

    INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
      .IncreaseLiquidityParams({
        tokenId: state.currentTokenId,
        amount0Desired: state.token0.balanceOf(address(this)),
        amount1Desired: state.token1.balanceOf(address(this)),
        amount0Min: amount0Min,
        amount1Min: amount1Min,
        deadline: block.timestamp
      });
    (, uint256 amount0Added, uint256 amount1Added) = state.nfpm.increaseLiquidity(params);
    _mint(to, shares);

    emit VaultDeposit(to, shares, amount0Added, amount1Added);
    return shares;
  }

  /// @notice Withdraw liquidity tokens and receive the tokens
  /// @param shares Number of liquidity tokens to redeem as pool assets
  /// @param to Address to which redeemed pool assets are sent
  /// @param amount0Min Minimum amount of token0 to receive
  /// @param amount1Min Minimum amount of token1 to receive
  /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
  /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
  function withdraw(
    uint256 shares,
    address to,
    uint256 amount0Min,
    uint256 amount1Min
  ) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
    require(shares > 0, InvalidShares());
    require(to != address(0), ZeroAddress());

    uint256 base0;
    uint256 base1;
    if (state.currentTokenId != 0) {
      /// update fees
      _collectFees();

      /// Withdraw liquidity from Uniswap pool
      (base0, base1) = _decreaseLiquidityAndCollectFees(_liquidityForShares(shares), to, false, amount0Min, amount1Min);
    }

    // Push tokens proportional to unused balances
    uint256 unusedAmount0 = FullMath.mulDiv(state.token0.balanceOf(address(this)), shares, totalSupply());
    uint256 unusedAmount1 = FullMath.mulDiv(state.token1.balanceOf(address(this)), shares, totalSupply());

    if (unusedAmount0 > 0) state.token0.safeTransfer(to, unusedAmount0);
    if (unusedAmount1 > 0) state.token1.safeTransfer(to, unusedAmount1);

    amount0 = base0 + unusedAmount0;
    amount1 = base1 + unusedAmount1;

    _burn(_msgSender(), shares);

    emit VaultWithdraw(_msgSender(), to, shares, amount0, amount1);

    return (amount0, amount1);
  }

  /// @notice Exit the position and redeem all tokens to balance
  /// @param to Address to which redeemed pool assets are sent
  /// @param amount0Min Minimum amount of token0 to receive
  /// @param amount1Min Minimum amount of token1 to receive
  function exit(
    address to,
    uint256 amount0Min,
    uint256 amount1Min
  ) external override onlyRole(DEFAULT_ADMIN_ROLE) nonReentrant {
    uint256 shares = IERC20(address(this)).balanceOf(_msgSender());

    require(shares > 0, InvalidShares());
    require(to != address(0), ZeroAddress());

    /// update fees
    _collectFees();

    (uint128 liquidity, , ) = _position();

    /// Withdraw liquidity from Uniswap pool
    _decreaseLiquidityAndCollectFees(liquidity, address(this), true, amount0Min, amount1Min);

    // Push tokens proportional to unused balances
    uint256 totalAmount0 = FullMath.mulDiv(state.token0.balanceOf(address(this)), shares, totalSupply());
    uint256 totalAmount1 = FullMath.mulDiv(state.token1.balanceOf(address(this)), shares, totalSupply());

    if (totalAmount0 > 0) state.token0.safeTransfer(to, totalAmount0);
    if (totalAmount1 > 0) state.token1.safeTransfer(to, totalAmount1);

    _burn(_msgSender(), shares);
    uint256 tokenId = state.currentTokenId;

    state.nfpm.burn(state.currentTokenId);

    state.currentTokenId = 0;
    state.currentTickLower = 0;
    state.currentTickUpper = 0;

    emit VaultExit(_msgSender(), to, shares, totalAmount0, totalAmount1, tokenId);
  }

  /// @notice Rebalance position to new range
  /// @param _newTickLower The lower tick of the base position
  /// @param _newTickUpper The upper tick of the base position
  /// @param  decreasedAmount0Min min amount0 returned for shares of liq
  /// @param  decreasedAmount1Min min amount1 returned for shares of liq
  /// @param  amount0Min min amount0 returned for shares of liq
  /// @param  amount1Min min amount1 returned for shares of liq
  function rebalance(
    int24 _newTickLower,
    int24 _newTickUpper,
    uint256 decreasedAmount0Min,
    uint256 decreasedAmount1Min,
    uint256 amount0Min,
    uint256 amount1Min
  ) external override nonReentrant onlyRole(ADMIN_ROLE_HASH) {
    require(
      _newTickLower < _newTickUpper && _newTickLower % state.tickSpacing == 0 && _newTickUpper % state.tickSpacing == 0,
      InvalidPriceRange()
    );
    require(_newTickLower != state.currentTickLower || _newTickUpper != state.currentTickUpper, InvalidPriceRange());

    /// update fees
    _collectFees();

    /// Withdraw all liquidity and collect all fees from Uniswap pool
    (uint128 baseLiquidity, uint256 feesBase0, uint256 feesBase1) = _position();

    _decreaseLiquidityAndCollectFees(baseLiquidity, address(this), true, decreasedAmount0Min, decreasedAmount1Min);

    emit VaultRebalance(
      currentTick(),
      state.token0.balanceOf(address(this)),
      state.token1.balanceOf(address(this)),
      feesBase0,
      feesBase1,
      totalSupply()
    );

    state.currentTickLower = _newTickLower;
    state.currentTickUpper = _newTickUpper;
    // optimally swap tokens
    _optimalSwap(_newTickLower, _newTickUpper);

    _mintLiquidity(
      INonfungiblePositionManager.MintParams({
        token0: address(state.token0),
        token1: address(state.token1),
        fee: state.fee,
        tickLower: state.currentTickLower,
        tickUpper: state.currentTickUpper,
        amount0Desired: state.token0.balanceOf(address(this)),
        amount1Desired: state.token1.balanceOf(address(this)),
        amount0Min: amount0Min,
        amount1Min: amount1Min,
        recipient: address(this),
        deadline: block.timestamp
      })
    );
  }

  /// @notice Compound fees
  /// @param amount0Min Minimum amount of token0 to receive
  /// @param amount1Min Minimum amount of token1 to receive
  function compound(uint256 amount0Min, uint256 amount1Min) external override onlyRole(ADMIN_ROLE_HASH) {
    // update fees for compounding
    _collectFees();
    _optimalSwap(state.currentTickLower, state.currentTickUpper);

    // add liquidity
    INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
      .IncreaseLiquidityParams({
        tokenId: state.currentTokenId,
        amount0Desired: state.token0.balanceOf(address(this)),
        amount1Desired: state.token1.balanceOf(address(this)),
        amount0Min: amount0Min,
        amount1Min: amount1Min,
        deadline: block.timestamp
      });
    (, uint256 amount0Added, uint256 amount1Added) = state.nfpm.increaseLiquidity(params);

    emit Compound(currentTick(), amount0Added, amount1Added, totalSupply());
  }

  /// @notice Collect fees
  function _collectFees() internal returns (uint128 liquidity) {
    (liquidity, , ) = _position();

    if (liquidity > 0) {
      (uint256 owed0, uint256 owed1) = state.nfpm.collect(
        INonfungiblePositionManager.CollectParams({
          tokenId: state.currentTokenId,
          recipient: address(this),
          amount0Max: type(uint128).max,
          amount1Max: type(uint128).max
        })
      );

      uint256 feeAmount0 = (owed0 * config.platformFeeBasisPoint) / 10000;
      uint256 feeAmount1 = (owed1 * config.platformFeeBasisPoint) / 10000;

      if (feeAmount0 > 0 && state.token0.balanceOf(address(this)) > 0)
        state.token0.safeTransfer(config.platformFeeRecipient, feeAmount0);
      if (feeAmount1 > 0 && state.token1.balanceOf(address(this)) > 0)
        state.token1.safeTransfer(config.platformFeeRecipient, feeAmount1);

      emit FeeCollected(1, feeAmount0, feeAmount1);

      feeAmount0 = (owed0 * config.ownerFeeBasisPoint) / 10000;
      feeAmount1 = (owed1 * config.ownerFeeBasisPoint) / 10000;
      if (feeAmount0 > 0 && state.token0.balanceOf(address(this)) > 0)
        state.token0.safeTransfer(config.ownerFeeRecipient, feeAmount0);
      if (feeAmount1 > 0 && state.token1.balanceOf(address(this)) > 0)
        state.token1.safeTransfer(config.ownerFeeRecipient, feeAmount1);

      emit FeeCollected(2, feeAmount0, feeAmount1);
    }

    return liquidity;
  }

  /// @notice Create position
  /// @param params Mint parameters
  /// @return tokenId The ID of the token that represents the minted position
  /// @return liquidity The amount of liquidity for this position
  /// @return amount0 The amount of token0
  /// @return amount1 The amount of token1
  function _mintLiquidity(
    INonfungiblePositionManager.MintParams memory params
  ) internal returns (uint256 tokenId, uint128 liquidity, uint256 amount0, uint256 amount1) {
    params.recipient = address(this);

    state.token0.approve(address(state.nfpm), type(uint256).max);
    state.token1.approve(address(state.nfpm), type(uint256).max);

    (tokenId, liquidity, amount0, amount1) = state.nfpm.mint(params);

    state.currentTokenId = tokenId;
    emit VaultPositionMint(tokenId);

    return (tokenId, liquidity, amount0, amount1);
  }

  /// @notice Decrease liquidity from the sender and collect tokens owed for the liquidity
  /// @param liquidity The amount of liquidity to burn
  /// @param to The address which should receive the fees collected
  /// @param collectAll If true, collect all tokens owed in the pool, else collect the owed tokens of the burn
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function _decreaseLiquidityAndCollectFees(
    uint128 liquidity,
    address to,
    bool collectAll,
    uint256 amount0Min,
    uint256 amount1Min
  ) internal returns (uint256 amount0, uint256 amount1) {
    if (liquidity > 0) {
      /// Burn liquidity
      (uint256 owed0, uint256 owed1) = state.nfpm.decreaseLiquidity(
        INonfungiblePositionManager.DecreaseLiquidityParams({
          tokenId: state.currentTokenId,
          liquidity: liquidity,
          amount0Min: type(uint256).min,
          amount1Min: type(uint256).min,
          deadline: block.timestamp
        })
      );

      require(owed0 >= amount0Min && owed1 >= amount1Min, InvalidAmount());

      // Collect amount owed
      uint128 collect0 = collectAll ? type(uint128).max : _uint128Safe(owed0);
      uint128 collect1 = collectAll ? type(uint128).max : _uint128Safe(owed1);

      if (collect0 > 0 || collect1 > 0) {
        (amount0, amount1) = state.nfpm.collect(
          INonfungiblePositionManager.CollectParams({
            tokenId: state.currentTokenId,
            recipient: to,
            amount0Max: collect0,
            amount1Max: collect1
          })
        );
      }
    }

    return (amount0, amount1);
  }

  /// @notice Get the liquidity amount for given liquidity tokens
  /// @param shares Shares of position
  /// @return The amount of liquidity token for shares
  function _liquidityForShares(uint256 shares) internal view returns (uint128) {
    (uint128 position, , ) = _position();
    uint256 totalShares = (position * shares) / totalSupply();
    return _uint128Safe(totalShares);
  }

  /// @notice Get the info of the given position
  /// @return liquidity The amount of liquidity of the position
  /// @return tokensOwed0 Amount of token0 owed
  /// @return tokensOwed1 Amount of token1 owed
  function _position() internal view returns (uint128 liquidity, uint128 tokensOwed0, uint128 tokensOwed1) {
    (, , , , , , , liquidity, , , tokensOwed0, tokensOwed1) = state.nfpm.positions(state.currentTokenId);

    return (liquidity, tokensOwed0, tokensOwed1);
  }

  /// @notice Get the total amounts of token0 and token1 in the KrystalVaultV3
  /// @return total0 Quantity of token0 in both positions and unused in the KrystalVaultV3
  /// @return total1 Quantity of token1 in both positions and unused in the KrystalVaultV3
  function getTotalAmounts() public view override returns (uint256 total0, uint256 total1) {
    (, uint256 base0, uint256 base1) = getBasePosition();
    total0 = state.token0.balanceOf(address(this)) + base0;
    total1 = state.token1.balanceOf(address(this)) + base1;

    return (total0, total1);
  }

  /// @notice Get the base position info
  /// @return liquidity Amount of total liquidity in the base position
  /// @return amount0 Estimated amount of token0 that could be collected by
  /// burning the base position
  /// @return amount1 Estimated amount of token1 that could be collected by
  /// burning the base position
  function getBasePosition() public view override returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
    (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position();
    (amount0, amount1) = _amountsForLiquidity(state.currentTickLower, state.currentTickUpper, positionLiquidity);
    amount0 = amount0 + tokensOwed0;
    amount1 = amount1 + tokensOwed1;
    liquidity = positionLiquidity;

    return (liquidity, amount0, amount1);
  }

  /// @notice Get the amounts of the given numbers of liquidity tokens
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @param liquidity The amount of liquidity tokens
  /// @return Amount of token0 and token1
  function _amountsForLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint128 liquidity
  ) internal view returns (uint256, uint256) {
    (uint160 sqrtRatioX96, , , , , , ) = state.pool.slot0();
    return
      LiquidityAmounts.getAmountsForLiquidity(
        sqrtRatioX96,
        TickMath.getSqrtRatioAtTick(tickLower),
        TickMath.getSqrtRatioAtTick(tickUpper),
        liquidity
      );
  }

  /// @notice Get the current price tick of the Uniswap pool
  /// @return tick Uniswap pool's current price tick
  function currentTick() public view override returns (int24 tick) {
    (, tick, , , , , ) = state.pool.slot0();

    return tick;
  }

  /// @dev Swap tokens to the optimal ratio to add liquidity in the same pool
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  function _optimalSwap(int24 tickLower, int24 tickUpper) internal {
    // swap tokens to the optimal ratio to add liquidity in the same pool
    uint256 amount0Desired = IERC20(state.token0).balanceOf(address(this));
    uint256 amount1Desired = IERC20(state.token1).balanceOf(address(this));
    state.token0.approve(address(optimalSwapper), type(uint256).max);
    state.token1.approve(address(optimalSwapper), type(uint256).max);

    optimalSwapper.optimalSwap(address(state.pool), amount0Desired, amount1Desired, tickLower, tickUpper, "");
  }

  /// @notice grant admin role to the address
  /// @param _address The address to which the admin role is granted
  function grantAdminRole(address _address) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    grantRole(ADMIN_ROLE_HASH, _address);
  }

  /// @notice revoke admin role from the address
  /// @param _address The address from which the admin role is revoked
  function revokeAdminRole(address _address) external override onlyRole(DEFAULT_ADMIN_ROLE) {
    revokeRole(ADMIN_ROLE_HASH, _address);
  }

  function _uint128Safe(uint256 x) internal pure returns (uint128) {
    assert(x <= type(uint128).max);

    return uint128(x);
  }
}
