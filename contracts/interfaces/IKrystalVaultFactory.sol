// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "./IKrystalVaultCommon.sol";

interface IKrystalVaultFactory is IKrystalVaultCommon {
  struct Vault {
    address owner;
    address krystalVault;
    address nfpm;
    INonfungiblePositionManager.MintParams params;
  }

  event VaultCreated(
    address indexed owner,
    address indexed krystalVault,
    address nfpm,
    INonfungiblePositionManager.MintParams params,
    uint256 vaultsLength
  );

  struct CreateVaultParams {
    address owner;
    address nfpm;
    INonfungiblePositionManager.MintParams mintParams;
    uint16 ownerFeeBasisPoint;
    string name;
    string symbol;
  }

  function createVault(CreateVaultParams calldata params) external payable returns (address krystalVault);

  function setKrystalVaultImplementation(address _krystalVaultImplementation) external;

  function setKrystalVaultAutomator(address _krystalVaultAutomator) external;

  function setOptimalSwapper(address _optimalSwapper) external;

  function setPlatformFeeRecipient(address _platformFeeRecipient) external;

  function setPlatformFeeBasisPoint(uint16 _platformFeeBasisPoint) external;
}
