// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/drafts/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3MintCallback.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";
import "@uniswap/v3-periphery/contracts/libraries/LiquidityAmounts.sol";

import "./interfaces/IKrystalVaultV3.sol";

/// @title KrystalVaultV3
/// @notice A Uniswap V2-like interface with fungible liquidity to Uniswap V3
/// which allows for arbitrary liquidity provision: one-sided, lop-sided, and balanced
contract KrystalVaultV3 is Ownable, ERC20Permit, ReentrancyGuard, IUniswapV3MintCallback, IKrystalVaultV3 {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  IUniswapV3Pool public override pool;
  IERC20 public override token0;
  IERC20 public override token1;

  bool public directDeposit; /// enter uni on deposit (avoid if client uses public rpc)
  bool public mintCalled;
  uint8 public fee = 5;
  int24 public tickSpacing;

  int24 public override baseLower;
  int24 public override baseUpper;

  int24 public limitLower;
  int24 public limitUpper;

  uint256 public maxTotalSupply;

  address public whitelistedAddress;
  address public feeRecipient;

  /// @param _pool Uniswap V3 pool for which liquidity is managed
  /// @param _owner Owner of the KrystalVaultV3
  constructor(
    address _pool,
    address _owner,
    string memory name,
    string memory symbol
  ) ERC20Permit(name) ERC20(name, symbol) {
    require(_pool != address(0), "pool should be non-zero");
    require(_owner != address(0), "owner should be non-zero");

    pool = IUniswapV3Pool(_pool);
    token0 = IERC20(pool.token0());
    token1 = IERC20(pool.token1());

    require(address(token0) != address(0), "token0 should be non-zero");
    require(address(token1) != address(0), "token1 should be non-zero");

    tickSpacing = pool.tickSpacing();
    maxTotalSupply = 0;

    transferOwnership(_owner);
  }

  /// @notice Deposit tokens
  /// @param deposit0 Amount of token0 transferred from sender to KrystalVaultV3
  /// @param deposit1 Amount of token1 transferred from sender to KrystalVaultV3
  /// @param to Address to which liquidity tokens are minted
  /// @param from Address from which asset tokens are transferred
  /// @param inMin min spend for directDeposit is true
  /// @return shares Quantity of liquidity tokens minted as a result of deposit
  function deposit(
    uint256 deposit0,
    uint256 deposit1,
    address to,
    address from,
    uint256[4] memory inMin
  ) external override nonReentrant returns (uint256 shares) {
    require(deposit0 > 0 || deposit1 > 0, "deposit amount should not be zero");
    require(to != address(0) && to != address(this), "to");
    require(msg.sender == whitelistedAddress, "Unauthorized");

    /// update fees
    zeroBurn();

    (uint160 sqrtPrice, , , , , , ) = pool.slot0();
    uint256 priceX96 = FullMath.mulDiv(sqrtPrice, sqrtPrice, FixedPoint96.Q96);

    (uint256 pool0, uint256 pool1) = getTotalAmounts();

    shares = deposit1.add(deposit0.mul(priceX96).div(FixedPoint96.Q96));

    if (deposit0 > 0) {
      token0.safeTransferFrom(from, address(this), deposit0);
    }
    if (deposit1 > 0) {
      token1.safeTransferFrom(from, address(this), deposit1);
    }

    uint256 total = totalSupply();

    if (total != 0) {
      uint256 pool0PricedInToken1 = pool0.mul(priceX96).div(FixedPoint96.Q96);
      shares = shares.mul(total).div(pool0PricedInToken1.add(pool1));
      if (directDeposit) {
        uint128 liquidity = _liquidityForAmounts(
          baseLower,
          baseUpper,
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(baseLower, baseUpper, liquidity, address(this), inMin[0], inMin[1]);
        liquidity = _liquidityForAmounts(
          limitLower,
          limitUpper,
          token0.balanceOf(address(this)),
          token1.balanceOf(address(this))
        );
        _mintLiquidity(limitLower, limitUpper, liquidity, address(this), inMin[2], inMin[3]);
      }
    }

    _mint(to, shares);

    require(maxTotalSupply == 0 || total <= maxTotalSupply, "maxTotalSupply exceeded");

    emit Deposit(from, to, shares, deposit0, deposit1);

    return shares;
  }

  function _zeroBurn(int24 tickLower, int24 tickUpper) internal returns (uint128 liquidity) {
    (liquidity, , ) = _position(tickLower, tickUpper);

    if (liquidity > 0) {
      pool.burn(tickLower, tickUpper, 0);
      (uint256 owed0, uint256 owed1) = pool.collect(
        address(this),
        tickLower,
        tickUpper,
        type(uint128).max,
        type(uint128).max
      );

      emit ZeroBurn(fee, owed0, owed1);

      if (owed0.div(fee) > 0 && token0.balanceOf(address(this)) > 0) token0.safeTransfer(feeRecipient, owed0.div(fee));
      if (owed1.div(fee) > 0 && token1.balanceOf(address(this)) > 0) token1.safeTransfer(feeRecipient, owed1.div(fee));
    }

    return liquidity;
  }

  /// @notice Update fees of the positions
  /// @return baseLiquidity Fee of base position
  /// @return limitLiquidity Fee of limit position
  function zeroBurn() internal returns (uint128 baseLiquidity, uint128 limitLiquidity) {
    baseLiquidity = _zeroBurn(baseLower, baseUpper);
    limitLiquidity = _zeroBurn(limitLower, limitUpper);

    return (baseLiquidity, limitLiquidity);
  }

  /// @notice Pull liquidity tokens from liquidity and receive the tokens
  /// @param shares Number of liquidity tokens to pull from liquidity
  /// @param tickLower lower tick
  /// @param tickUpper upper tick
  /// @param amountMin min outs
  /// @return amount0 amount of token0 received from base position
  /// @return amount1 amount of token1 received from base position
  function pullLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint128 shares,
    uint256[2] memory amountMin
  ) external override onlyOwner returns (uint256 amount0, uint256 amount1) {
    _zeroBurn(tickLower, tickUpper);

    (amount0, amount1) = _burnLiquidity(
      tickLower,
      tickUpper,
      _liquidityForShares(tickLower, tickUpper, shares),
      address(this),
      false,
      amountMin[0],
      amountMin[1]
    );

    emit PullLiquidity(tickLower, tickUpper, shares, amount0, amount1);

    return (amount0, amount1);
  }

  /// @param shares Number of liquidity tokens to redeem as pool assets
  /// @param to Address to which redeemed pool assets are sent
  /// @param from Address from which liquidity tokens are sent
  /// @param minAmounts min amount0,1 returned for shares of liq
  /// @return amount0 Amount of token0 redeemed by the submitted liquidity tokens
  /// @return amount1 Amount of token1 redeemed by the submitted liquidity tokens
  function withdraw(
    uint256 shares,
    address to,
    address from,
    uint256[4] memory minAmounts
  ) external override nonReentrant returns (uint256 amount0, uint256 amount1) {
    require(shares > 0, "shares");
    require(to != address(0), "to");

    /// update fees
    zeroBurn();

    /// Withdraw liquidity from Uniswap pool
    (uint256 base0, uint256 base1) = _burnLiquidity(
      baseLower,
      baseUpper,
      _liquidityForShares(baseLower, baseUpper, shares),
      to,
      false,
      minAmounts[0],
      minAmounts[1]
    );
    (uint256 limit0, uint256 limit1) = _burnLiquidity(
      limitLower,
      limitUpper,
      _liquidityForShares(limitLower, limitUpper, shares),
      to,
      false,
      minAmounts[2],
      minAmounts[3]
    );

    // Push tokens proportional to unused balances
    uint256 unusedAmount0 = token0.balanceOf(address(this)).mul(shares).div(totalSupply());
    uint256 unusedAmount1 = token1.balanceOf(address(this)).mul(shares).div(totalSupply());

    if (unusedAmount0 > 0) token0.safeTransfer(to, unusedAmount0);
    if (unusedAmount1 > 0) token1.safeTransfer(to, unusedAmount1);

    amount0 = base0.add(limit0).add(unusedAmount0);
    amount1 = base1.add(limit1).add(unusedAmount1);

    require(from == msg.sender, "own");

    _burn(from, shares);

    emit Withdraw(from, to, shares, amount0, amount1);

    return (amount0, amount1);
  }

  /// @param _baseLower The lower tick of the base position
  /// @param _baseUpper The upper tick of the base position
  /// @param _limitLower The lower tick of the limit position
  /// @param _limitUpper The upper tick of the limit position
  /// @param  inMin min spend
  /// @param  outMin min amount0,1 returned for shares of liq
  /// @param _feeRecipient Address of recipient of 10% of earned fees since last rebalance
  function rebalance(
    int24 _baseLower,
    int24 _baseUpper,
    int24 _limitLower,
    int24 _limitUpper,
    address _feeRecipient,
    uint256[4] memory inMin,
    uint256[4] memory outMin
  ) external override nonReentrant onlyOwner {
    require(
      _baseLower < _baseUpper && _baseLower % tickSpacing == 0 && _baseUpper % tickSpacing == 0,
      "invalid price range"
    );
    require(
      _limitLower < _limitUpper && _limitLower % tickSpacing == 0 && _limitUpper % tickSpacing == 0,
      "invalid limit range"
    );
    require(_limitUpper != _baseUpper || _limitLower != _baseLower, "invalid limit condition");
    require(_feeRecipient != address(0), "feeRecipient should be non-zero");

    feeRecipient = _feeRecipient;

    /// update fees
    zeroBurn();

    /// Withdraw all liquidity and collect all fees from Uniswap pool
    (uint128 baseLiquidity, uint256 feesLimit0, uint256 feesLimit1) = _position(baseLower, baseUpper);
    (uint128 limitLiquidity, uint256 feesBase0, uint256 feesBase1) = _position(limitLower, limitUpper);

    _burnLiquidity(baseLower, baseUpper, baseLiquidity, address(this), true, outMin[0], outMin[1]);
    _burnLiquidity(limitLower, limitUpper, limitLiquidity, address(this), true, outMin[2], outMin[3]);

    emit Rebalance(
      currentTick(),
      token0.balanceOf(address(this)),
      token1.balanceOf(address(this)),
      feesBase0.add(feesLimit0),
      feesBase1.add(feesLimit1),
      totalSupply()
    );

    baseLower = _baseLower;
    baseUpper = _baseUpper;
    baseLiquidity = _liquidityForAmounts(
      baseLower,
      baseUpper,
      token0.balanceOf(address(this)),
      token1.balanceOf(address(this))
    );
    _mintLiquidity(baseLower, baseUpper, baseLiquidity, address(this), inMin[0], inMin[1]);

    limitLower = _limitLower;
    limitUpper = _limitUpper;
    limitLiquidity = _liquidityForAmounts(
      limitLower,
      limitUpper,
      token0.balanceOf(address(this)),
      token1.balanceOf(address(this))
    );
    _mintLiquidity(limitLower, limitUpper, limitLiquidity, address(this), inMin[2], inMin[3]);
  }

  /// @notice Compound pending fees
  /// @param inMin min spend
  function compound(uint256[4] memory inMin) external override onlyOwner {
    // update fees for compounding
    zeroBurn();

    uint128 liquidity = _liquidityForAmounts(
      baseLower,
      baseUpper,
      token0.balanceOf(address(this)),
      token1.balanceOf(address(this))
    );
    _mintLiquidity(baseLower, baseUpper, liquidity, address(this), inMin[0], inMin[1]);

    liquidity = _liquidityForAmounts(
      limitLower,
      limitUpper,
      token0.balanceOf(address(this)),
      token1.balanceOf(address(this))
    );
    _mintLiquidity(limitLower, limitUpper, liquidity, address(this), inMin[2], inMin[3]);

    emit Compound(currentTick(), token0.balanceOf(address(this)), token1.balanceOf(address(this)), totalSupply());
  }

  /// @notice Add Liquidity
  function addLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0,
    uint256 amount1,
    uint256[2] memory inMin
  ) public override onlyOwner {
    _zeroBurn(tickLower, tickUpper);

    uint128 liquidity = _liquidityForAmounts(tickLower, tickUpper, amount0, amount1);

    _mintLiquidity(tickLower, tickUpper, liquidity, address(this), inMin[0], inMin[1]);

    emit AddLiquidity(tickLower, tickUpper, amount0, amount1);
  }

  /// @notice Adds the liquidity for the given position
  /// @param tickLower The lower tick of the position in which to add liquidity
  /// @param tickUpper The upper tick of the position in which to add liquidity
  /// @param liquidity The amount of liquidity to mint
  /// @param payer Payer Data
  /// @param amount0Min Minimum amount of token0 that should be paid
  /// @param amount1Min Minimum amount of token1 that should be paid
  function _mintLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint128 liquidity,
    address payer,
    uint256 amount0Min,
    uint256 amount1Min
  ) internal {
    if (liquidity > 0) {
      mintCalled = true;
      (uint256 amount0, uint256 amount1) = pool.mint(address(this), tickLower, tickUpper, liquidity, abi.encode(payer));

      require(amount0 >= amount0Min && amount1 >= amount1Min, "invalid amounts");
    }
  }

  /// @notice Burn liquidity from the sender and collect tokens owed for the liquidity
  /// @param tickLower The lower tick of the position for which to burn liquidity
  /// @param tickUpper The upper tick of the position for which to burn liquidity
  /// @param liquidity The amount of liquidity to burn
  /// @param to The address which should receive the fees collected
  /// @param collectAll If true, collect all tokens owed in the pool, else collect the owed tokens of the burn
  /// @return amount0 The amount of fees collected in token0
  /// @return amount1 The amount of fees collected in token1
  function _burnLiquidity(
    int24 tickLower,
    int24 tickUpper,
    uint128 liquidity,
    address to,
    bool collectAll,
    uint256 amount0Min,
    uint256 amount1Min
  ) internal returns (uint256 amount0, uint256 amount1) {
    if (liquidity > 0) {
      /// Burn liquidity
      (uint256 owed0, uint256 owed1) = pool.burn(tickLower, tickUpper, liquidity);

      require(owed0 >= amount0Min && owed1 >= amount1Min, "invalid amounts");

      // Collect amount owed
      uint128 collect0 = collectAll ? type(uint128).max : _uint128Safe(owed0);
      uint128 collect1 = collectAll ? type(uint128).max : _uint128Safe(owed1);

      if (collect0 > 0 || collect1 > 0) {
        (amount0, amount1) = pool.collect(to, tickLower, tickUpper, collect0, collect1);
      }
    }

    return (amount0, amount1);
  }

  /// @notice Get the liquidity amount for given liquidity tokens
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @param shares Shares of position
  /// @return The amount of liquidity toekn for shares
  function _liquidityForShares(int24 tickLower, int24 tickUpper, uint256 shares) internal view returns (uint128) {
    (uint128 position, , ) = _position(tickLower, tickUpper);
    return _uint128Safe(uint256(position).mul(shares).div(totalSupply()));
  }

  /// @notice Get the info of the given position
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @return liquidity The amount of liquidity of the position
  /// @return tokensOwed0 Amount of token0 owed
  /// @return tokensOwed1 Amount of token1 owed
  function _position(
    int24 tickLower,
    int24 tickUpper
  ) internal view returns (uint128 liquidity, uint128 tokensOwed0, uint128 tokensOwed1) {
    bytes32 positionKey = keccak256(abi.encodePacked(address(this), tickLower, tickUpper));
    (liquidity, , , tokensOwed0, tokensOwed1) = pool.positions(positionKey);

    return (liquidity, tokensOwed0, tokensOwed1);
  }

  /// @notice Callback function of uniswapV3Pool mint
  function uniswapV3MintCallback(uint256 amount0, uint256 amount1, bytes calldata data) external override {
    require(msg.sender == address(pool), "sender should be pool");
    require(mintCalled == true, "mintCalled is false");

    mintCalled = false;

    if (amount0 > 0) token0.safeTransfer(msg.sender, amount0);
    if (amount1 > 0) token1.safeTransfer(msg.sender, amount1);
  }

  /// @return total0 Quantity of token0 in both positions and unused in the KrystalVaultV3
  /// @return total1 Quantity of token1 in both positions and unused in the KrystalVaultV3
  function getTotalAmounts() public view override returns (uint256 total0, uint256 total1) {
    (, uint256 base0, uint256 base1) = getBasePosition();
    (, uint256 limit0, uint256 limit1) = getLimitPosition();
    total0 = token0.balanceOf(address(this)).add(base0).add(limit0);
    total1 = token1.balanceOf(address(this)).add(base1).add(limit1);

    return (total0, total1);
  }

  /// @return liquidity Amount of total liquidity in the base position
  /// @return amount0 Estimated amount of token0 that could be collected by
  /// burning the base position
  /// @return amount1 Estimated amount of token1 that could be collected by
  /// burning the base position
  function getBasePosition() public view override returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
    (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(baseLower, baseUpper);
    (amount0, amount1) = _amountsForLiquidity(baseLower, baseUpper, positionLiquidity);
    amount0 = amount0.add(uint256(tokensOwed0));
    amount1 = amount1.add(uint256(tokensOwed1));
    liquidity = positionLiquidity;

    return (liquidity, amount0, amount1);
  }

  /// @return liquidity Amount of total liquidity in the limit position
  /// @return amount0 Estimated amount of token0 that could be collected by
  /// burning the limit position
  /// @return amount1 Estimated amount of token1 that could be collected by
  /// burning the limit position
  function getLimitPosition() public view override returns (uint128 liquidity, uint256 amount0, uint256 amount1) {
    (uint128 positionLiquidity, uint128 tokensOwed0, uint128 tokensOwed1) = _position(limitLower, limitUpper);
    (amount0, amount1) = _amountsForLiquidity(limitLower, limitUpper, positionLiquidity);
    amount0 = amount0.add(uint256(tokensOwed0));
    amount1 = amount1.add(uint256(tokensOwed1));
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
    (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
    return
      LiquidityAmounts.getAmountsForLiquidity(
        sqrtRatioX96,
        TickMath.getSqrtRatioAtTick(tickLower),
        TickMath.getSqrtRatioAtTick(tickUpper),
        liquidity
      );
  }

  /// @notice Get the liquidity amount of the given numbers of token0 and token1
  /// @param tickLower The lower tick of the position
  /// @param tickUpper The upper tick of the position
  /// @param amount0 The amount of token0
  /// @param amount0 The amount of token1
  /// @return Amount of liquidity tokens
  function _liquidityForAmounts(
    int24 tickLower,
    int24 tickUpper,
    uint256 amount0,
    uint256 amount1
  ) internal view returns (uint128) {
    (uint160 sqrtRatioX96, , , , , , ) = pool.slot0();
    return
      LiquidityAmounts.getLiquidityForAmounts(
        sqrtRatioX96,
        TickMath.getSqrtRatioAtTick(tickLower),
        TickMath.getSqrtRatioAtTick(tickUpper),
        amount0,
        amount1
      );
  }

  /// @return tick Uniswap pool's current price tick
  function currentTick() public view override returns (int24 tick) {
    (, tick, , , , , ) = pool.slot0();

    return tick;
  }

  function _uint128Safe(uint256 x) internal pure returns (uint128) {
    assert(x <= type(uint128).max);

    return uint128(x);
  }

  /// @param _address address to whitelist
  function setWhitelist(address _address) external override onlyOwner {
    whitelistedAddress = _address;

    emit SetWhitelist(_address);
  }

  /// @notice set fee
  function setFee(uint8 newFee) external override onlyOwner {
    fee = newFee;

    emit SetFee(fee);
  }

  /// @notice Toggle Direct Deposit
  function toggleDirectDeposit() external override onlyOwner {
    directDeposit = !directDeposit;

    emit ToggleDirectDeposit(directDeposit);
  }
}
