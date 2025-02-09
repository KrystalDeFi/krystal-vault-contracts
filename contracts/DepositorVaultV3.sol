/// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

import "./interfaces/IKrystalVaultV3.sol";
import "./interfaces/IDepositorVaultV3.sol";

/// @title DepositorVaultV3
/// @notice Proxy contract for KrystalVaultV3 vaults management
contract DepositorVaultV3 is AccessControl, Pausable, ReentrancyGuard, IDepositorVaultV3 {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SignedSafeMath for int256;

  bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
  bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

  mapping(address => VaultConfig) public vaultConfigs;
  mapping(address => mapping(address => bool)) public whitelistDepositList;

  bool public twapCheck = true;
  uint32 public twapInterval = 3600;
  uint256 public depositDelta = 10_010;
  uint256 public deltaScale = 10_000; /// must be a power of 10
  uint256 public priceThreshold = 10_000;
  uint256 public constant MAX_UINT = type(uint256).max;
  uint256 public constant PRECISION = 1e36;

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(ADMIN_ROLE, msg.sender);
    _setupRole(OPERATOR_ROLE, msg.sender);
  }

  modifier onlyAdmin() {
    require(hasRole(ADMIN_ROLE, msg.sender), "Unauthorized");
    _;
  }

  modifier onlyOperator() {
    require(hasRole(OPERATOR_ROLE, msg.sender), "Unauthorized");
    _;
  }

  modifier onlyExistedConfig(address pos) {
    VaultConfig storage p = vaultConfigs[pos];
    require(p.version != 0, "config not found");
    _;
  }

  modifier onlySupplyAvailable(address pos) {
    if (vaultConfigs[pos].maxTotalSupply != 0) {
      require(IERC20(pos).totalSupply() <= vaultConfigs[pos].maxTotalSupply, "exceeds max supply");
    }
    _;
  }

  modifier onlyValidDeposit(
    uint256 deposit0,
    uint256 deposit1,
    address from,
    address to,
    address pos
  ) {
    require(to != address(0), "to should be non-zero");
    require(
      IKrystalVaultV3(pos).currentTick() >= IKrystalVaultV3(pos).baseLower() &&
        IKrystalVaultV3(pos).currentTick() < IKrystalVaultV3(pos).baseUpper(),
      "price out of base range"
    );

    VaultConfig storage p = vaultConfigs[pos];

    if (twapCheck || p.twapOverride) {
      /// check twap
      checkPriceChange(
        pos,
        (p.twapOverride ? p.twapInterval : twapInterval),
        (p.twapOverride ? p.priceThreshold : priceThreshold)
      );
    }

    if (!whitelistDepositList[pos][from]) {
      require(deposit0 > 0 && deposit1 > 0, "must deposit to both sides");
      (uint256 test1Min, uint256 test1Max) = getDepositAmount(pos, address(IKrystalVaultV3(pos).token0()), deposit0);
      require(deposit1 >= test1Min && deposit1 <= test1Max, "Improper ratio");

      (uint256 test0Min, uint256 test0Max) = getDepositAmount(pos, address(IKrystalVaultV3(pos).token1()), deposit1);
      require(deposit0 >= test0Min && deposit0 <= test0Max, "Improper ratio");

      if (p.depositOverride) {
        require(deposit0 <= p.deposit0Max, "token0 exceeds");
        require(deposit1 <= p.deposit1Max, "token1 exceeds");
      }
    }
    _;
  }

  function grantOperatorRole(address[] calldata operators) external override onlyAdmin {
    for (uint256 i = 0; i < operators.length; i++) {
      grantRole(OPERATOR_ROLE, operators[i]);
    }
  }

  function revokeOperatorRole(address[] calldata operators) external override onlyAdmin {
    for (uint256 i = 0; i < operators.length; i++) {
      revokeRole(OPERATOR_ROLE, operators[i]);
    }
  }

  /// @notice Add the KrystalVaultV3 config
  /// @param pos Address of the KrystalVaultV3
  /// @param version Type of KrystalVaultV3
  function addConfig(address pos, uint8 version) external override onlyOperator {
    VaultConfig storage p = vaultConfigs[pos];

    require(p.version == 0, "config already exists");
    require(version > 0, "invalid version");

    p.version = version;

    IKrystalVaultV3(pos).token0().safeApprove(pos, MAX_UINT);
    IKrystalVaultV3(pos).token1().safeApprove(pos, MAX_UINT);

    emit ConfigAdded(pos, version);
  }

  /// @notice Deposit into the given position
  /// @param deposit0 Amount of token0 to deposit
  /// @param deposit1 Amount of token1 to deposit
  /// @param to Address to receive liquidity tokens
  /// @param pos KrystalVaultV3 Address
  /// @param minIn min assets to expect in position during a direct deposit
  /// @return shares Amount of liquidity tokens received
  function deposit(
    uint256 deposit0,
    uint256 deposit1,
    address to,
    address pos,
    uint256[4] memory minIn
  )
    external
    override
    nonReentrant
    onlyExistedConfig(pos)
    onlyValidDeposit(deposit0, deposit1, msg.sender, to, pos)
    onlySupplyAvailable(pos)
    returns (uint256 shares)
  {
    shares = _performDeposit(deposit0, deposit1, to, pos, minIn);

    return shares;
  }

  function _performDeposit(
    uint256 deposit0,
    uint256 deposit1,
    address to,
    address pos,
    uint256[4] memory minIn
  ) internal returns (uint256 shares) {
    shares = IKrystalVaultV3(pos).deposit(deposit0, deposit1, to, msg.sender, minIn);

    emit Deposit(msg.sender, to, shares, deposit0, deposit1);

    return shares;
  }

  /// @notice Get the amount of token to deposit for the given amount of pair token
  /// @param pos KrystalVaultV3 Address
  /// @param token Address of token to deposit
  /// @param _deposit Amount of token to deposit
  /// @return amountStart Minimum amounts of the pair token to deposit
  /// @return amountEnd Maximum amounts of the pair token to deposit
  function getDepositAmount(
    address pos,
    address token,
    uint256 _deposit
  ) public view override returns (uint256 amountStart, uint256 amountEnd) {
    require(
      token == address(IKrystalVaultV3(pos).token0()) || token == address(IKrystalVaultV3(pos).token1()),
      "token mismatch"
    );
    require(_deposit > 0, "deposits should not be zero");

    (uint256 total0, uint256 total1) = IKrystalVaultV3(pos).getTotalAmounts();

    if (IERC20(pos).totalSupply() == 0) {
      amountStart = 0;
      if (vaultConfigs[pos].depositOverride) {
        amountEnd = (token == address(IKrystalVaultV3(pos).token0()))
          ? vaultConfigs[pos].deposit1Max
          : vaultConfigs[pos].deposit0Max;
      } else {
        amountEnd = type(uint256).max;
      }
    } else if (total0 == 0 || total1 == 0) {
      amountStart = 0;
      amountEnd = 0;
    } else {
      (uint256 ratioStart, uint256 ratioEnd) = vaultConfigs[pos].customRatio
        ? getRatioRange(pos, token, vaultConfigs[pos].fauxTotal0, vaultConfigs[pos].fauxTotal1)
        : getRatioRange(pos, token, total0, total1);
      amountStart = FullMath.mulDiv(_deposit, PRECISION, ratioStart);
      amountEnd = FullMath.mulDiv(_deposit, PRECISION, ratioEnd);
    }

    return (amountStart, amountEnd);
  }

  /// @notice Get range for deposit based on provided amounts
  /// @param pos KrystalVaultV3 Address
  /// @param token Address of token to deposit
  /// @param total0 Amount of token0 in hype
  /// @param total1 Amount of token1 in hype
  /// @return ratioStart Minimum amounts of the pair token to deposit
  /// @return ratioEnd Maximum amounts of the pair token to deposit
  function getRatioRange(
    address pos,
    address token,
    uint256 total0,
    uint256 total1
  ) public view override returns (uint256 ratioStart, uint256 ratioEnd) {
    require(
      token == address(IKrystalVaultV3(pos).token0()) || token == address(IKrystalVaultV3(pos).token1()),
      "token mismatch"
    );

    uint256 _depositDelta = vaultConfigs[pos].depositOverride ? vaultConfigs[pos].customDepositDelta : depositDelta;

    if (token == address(IKrystalVaultV3(pos).token0())) {
      ratioStart = FullMath.mulDiv(total0.mul(_depositDelta), PRECISION, total1.mul(deltaScale));
      ratioEnd = FullMath.mulDiv(total0.mul(deltaScale), PRECISION, total1.mul(_depositDelta));
    } else {
      ratioStart = FullMath.mulDiv(total1.mul(_depositDelta), PRECISION, total0.mul(deltaScale));
      ratioEnd = FullMath.mulDiv(total1.mul(deltaScale), PRECISION, total0.mul(_depositDelta));
    }

    return (ratioStart, ratioEnd);
  }

  /// @notice Check if the price change overflows or not based on given twap and threshold in the KrystalVaultV3
  /// @param pos KrystalVaultV3 Address
  /// @param _twapInterval Time intervals
  /// @param _priceThreshold Price Threshold
  /// @return price Current price
  function checkPriceChange(
    address pos,
    uint32 _twapInterval,
    uint256 _priceThreshold
  ) public view override returns (uint256 price) {
    (uint160 sqrtPrice, , , , , , ) = IKrystalVaultV3(pos).pool().slot0();
    price = FullMath.mulDiv(uint256(sqrtPrice).mul(uint256(sqrtPrice)), PRECISION, 2 ** (96 * 2));
    uint160 sqrtPriceBefore = getSqrtTwapX96(pos, _twapInterval);
    uint256 priceBefore = FullMath.mulDiv(
      uint256(sqrtPriceBefore).mul(uint256(sqrtPriceBefore)),
      PRECISION,
      2 ** (96 * 2)
    );

    if (price.mul(10_000).div(priceBefore) > _priceThreshold || priceBefore.mul(10_000).div(price) > _priceThreshold)
      revert("Price change overflow");

    return price;
  }

  /// @param pos KrystalVaultV3 address
  /// @param deposit0Max Amount of maximum deposit amounts of token0
  /// @param deposit1Max Amount of maximum deposit amounts of token1
  /// @param maxTotalSupply Maximum total supply of KrystalVaultV3
  /// @param customDepositDelta custom deposit delta
  function updateConfig(
    address pos,
    uint256 deposit0Max,
    uint256 deposit1Max,
    uint256 maxTotalSupply,
    uint256 customDepositDelta
  ) external override onlyOperator onlyExistedConfig(pos) {
    VaultConfig storage p = vaultConfigs[pos];

    p.deposit0Max = deposit0Max;
    p.deposit1Max = deposit1Max;
    p.maxTotalSupply = maxTotalSupply;
    p.customDepositDelta = customDepositDelta;

    emit CustomDeposit(pos, deposit0Max, deposit1Max, maxTotalSupply);
  }

  function getVaultConfig(address pos) public view override returns (VaultConfig memory) {
    return vaultConfigs[pos];
  }

  /// @notice Get the sqrt price before the given interval
  /// @param pos KrystalVaultV3 Address
  /// @param _twapInterval Time intervals
  /// @return sqrtPriceX96 Sqrt price before interval
  function getSqrtTwapX96(address pos, uint32 _twapInterval) public view override returns (uint160 sqrtPriceX96) {
    if (_twapInterval == 0) {
      /// return the current price if _twapInterval == 0
      (sqrtPriceX96, , , , , , ) = IKrystalVaultV3(pos).pool().slot0();
    } else {
      uint32[] memory secondsAgos = new uint32[](2);
      secondsAgos[0] = _twapInterval; /// from (before)
      secondsAgos[1] = 0; /// to (now)
      (int56[] memory tickCumulatives, ) = IKrystalVaultV3(pos).pool().observe(secondsAgos);
      /// tick(imprecise as it's an integer) to price
      sqrtPriceX96 = TickMath.getSqrtRatioAtTick(int24((tickCumulatives[1] - tickCumulatives[0]) / _twapInterval));
    }

    return sqrtPriceX96;
  }

  /// @param _priceThreshold Price Threshold
  function setPriceThreshold(uint256 _priceThreshold) external override onlyAdmin {
    priceThreshold = _priceThreshold;

    emit PriceThresholdSet(_priceThreshold);
  }

  /// @param _depositDelta Number to calculate deposit ratio
  function setDepositDelta(uint256 _depositDelta) external override onlyAdmin {
    depositDelta = _depositDelta;

    emit DepositDeltaSet(_depositDelta);
  }

  /// @param _deltaScale Number to calculate deposit ratio
  function setDeltaScale(uint256 _deltaScale) external override onlyAdmin {
    deltaScale = _deltaScale;

    emit DeltaScaleSet(_deltaScale);
  }

  /// @param pos KrystalVaultV3 address
  /// @param _customRatio whether to use custom ratio
  /// @param fauxTotal0 override total0
  /// @param fauxTotal1 override total1
  function customRatio(
    address pos,
    bool _customRatio,
    uint256 fauxTotal0,
    uint256 fauxTotal1
  ) external override onlyOperator onlyExistedConfig(pos) {
    require(!vaultConfigs[pos].ratioRemoved, "custom ratio unavailable");

    VaultConfig storage p = vaultConfigs[pos];

    p.customRatio = _customRatio;
    p.fauxTotal0 = fauxTotal0;
    p.fauxTotal1 = fauxTotal1;

    emit CustomRatio(pos, fauxTotal0, fauxTotal1);
  }

  // @note permanently remove ability to apply custom ratio to hype
  function removeRatio(address pos) external override onlyOperator onlyExistedConfig(pos) {
    VaultConfig storage p = vaultConfigs[pos];

    p.ratioRemoved = true;

    emit RatioRemoved(pos);
  }

  /// @notice set deposit override
  /// @param pos KrystalVaultV3 Address
  function setDepositOverride(
    address pos,
    bool _depositOverride
  ) external override onlyOperator onlyExistedConfig(pos) {
    VaultConfig storage p = vaultConfigs[pos];

    p.depositOverride = _depositOverride;

    emit DepositOverrideSet(pos, _depositOverride);
  }

  /// @param _twapInterval Time intervals
  function setTwapInterval(uint32 _twapInterval) external override onlyAdmin {
    twapInterval = _twapInterval;

    emit TwapIntervalSet(_twapInterval);
  }

  /// @param pos KrystalVaultV3 Address
  /// @param twapOverride Twap Override
  /// @param _twapInterval Time Intervals
  /// @param _priceThreshold Price Threshold
  function setTwapOverride(
    address pos,
    bool twapOverride,
    uint32 _twapInterval,
    uint256 _priceThreshold
  ) external override onlyOperator onlyExistedConfig(pos) {
    VaultConfig storage p = vaultConfigs[pos];

    p.twapOverride = twapOverride;
    p.twapInterval = _twapInterval;
    p.priceThreshold = _priceThreshold;

    emit TwapOverrideSet(pos, twapOverride, _twapInterval, _priceThreshold);
  }

  /// @notice Set Twap
  function setTwapCheck(bool _twapCheck) external override onlyAdmin {
    twapCheck = _twapCheck;

    emit TwapCheckSet(_twapCheck);
  }

  // @notice check if an address is whitelisted for hype
  function getWhitelistDeposit(address pos, address i) public view override returns (bool) {
    return whitelistDepositList[pos][i];
  }

  /// @notice Whitelist deposit to KrystalVaultV3
  /// @param pos KrystalVaultV3 Address
  /// @param addresses Addresses to add in whitelist
  /// @param whitelisted Whitelisted or not
  function whitelistDeposit(address pos, address[] memory addresses, bool whitelisted) external override onlyOperator {
    for (uint256 i = 0; i < addresses.length; i++) {
      whitelistDepositList[pos][addresses[i]] = whitelisted;
    }

    emit WhitelistDeposit(pos, addresses, whitelisted);
  }
}
