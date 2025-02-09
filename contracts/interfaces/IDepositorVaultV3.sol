// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;
pragma abicoder v2;

interface IDepositorVaultV3 {
  struct VaultConfig {
    bool customRatio;
    bool customTwap;
    bool ratioRemoved;
    bool depositOverride; // force custom deposit constraints
    bool twapOverride; // force twap check for KrystalVaultV3 instance
    uint8 version;
    uint32 twapInterval; // override global twap
    uint256 priceThreshold; // custom price threshold
    uint256 deposit0Max;
    uint256 deposit1Max;
    uint256 maxTotalSupply;
    uint256 fauxTotal0;
    uint256 fauxTotal1;
    uint256 customDepositDelta;
  }

  event ConfigAdded(address pos, uint8 version);

  event Deposit(address sender, address to, uint256 shares, uint256 deposit0, uint256 deposit1);

  event CustomDeposit(address pos, uint256 deposit0Max, uint256 deposit1Max, uint256 maxTotalSupply);

  event PriceThresholdSet(uint256 _priceThreshold);

  event DepositDeltaSet(uint256 _depositDelta);

  event DeltaScaleSet(uint256 _deltaScale);

  event TwapIntervalSet(uint32 _twapInterval);

  event TwapOverrideSet(address pos, bool twapOverride, uint32 _twapInterval, uint256 _priceThreshold);

  event PriceThresholdPosSet(address pos, uint256 _priceThreshold);

  event DepositOverrideSet(address pos, bool depositOverride);

  event TwapCheckSet(bool twapCheck);

  event WhitelistDeposit(address pos, address[] addresses, bool whitelisted);

  event CustomRatio(address pos, uint256 fauxTotal0, uint256 fauxTotal1);

  event RatioRemoved(address pos);

  function grantOperatorRole(address[] calldata operators) external;

  function revokeOperatorRole(address[] calldata operators) external;

  function addConfig(address pos, uint8 version) external;

  function deposit(
    uint256 deposit0,
    uint256 deposit1,
    address to,
    address pos,
    uint256[2] memory minIn
  ) external returns (uint256 shares);

  function getDepositAmount(
    address pos,
    address token,
    uint256 _deposit
  ) external view returns (uint256 amountStart, uint256 amountEnd);

  function getRatioRange(
    address pos,
    address token,
    uint256 total0,
    uint256 total1
  ) external view returns (uint256 ratioStart, uint256 ratioEnd);

  function checkPriceChange(
    address pos,
    uint32 _twapInterval,
    uint256 _priceThreshold
  ) external view returns (uint256 price);

  function setPriceThreshold(uint256 _priceThreshold) external;

  function setDepositDelta(uint256 _depositDelta) external;

  function setDeltaScale(uint256 _deltaScale) external;

  function updateConfig(
    address pos,
    uint256 deposit0Max,
    uint256 deposit1Max,
    uint256 maxTotalSupply,
    uint256 customDepositDelta
  ) external;

  function getVaultConfig(address pos) external view returns (VaultConfig memory);

  function getSqrtTwapX96(address pos, uint32 _twapInterval) external view returns (uint160 sqrtPriceX96);

  function customRatio(address pos, bool _customRatio, uint256 fauxTotal0, uint256 fauxTotal1) external;

  function removeRatio(address pos) external;

  function setDepositOverride(address pos, bool _depositOverride) external;

  function setTwapInterval(uint32 _twapInterval) external;

  function setTwapOverride(address pos, bool twapOverride, uint32 _twapInterval, uint256 _priceThreshold) external;

  function setTwapCheck(bool _twapCheck) external;

  function getWhitelistDeposit(address pos, address i) external view returns (bool);

  function whitelistDeposit(address pos, address[] memory addresses, bool whitelisted) external;
}
