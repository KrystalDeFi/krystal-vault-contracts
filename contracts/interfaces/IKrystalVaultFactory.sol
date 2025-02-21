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

  function createVault(
    address owner,
    address nfpm,
    INonfungiblePositionManager.MintParams memory params,
    uint16 ownerFeeBasisPoint,
    string memory name,
    string memory symbol
  ) external returns (address krystalVault);
}
