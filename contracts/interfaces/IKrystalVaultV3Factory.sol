// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;
pragma abicoder v2;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "./IKrystalVaultV3Common.sol";

interface IKrystalVaultV3Factory is IKrystalVaultV3Common {
  struct Vault {
    address owner;
    address krystalVaultV3;
    address nfpm;
    INonfungiblePositionManager.MintParams params;
  }

  event VaultCreated(
    address indexed owner,
    address indexed krystalVaultV3,
    address nfpm,
    INonfungiblePositionManager.MintParams params,
    uint256 vaultsLength
  );

  function allVaultsLength() external view returns (uint256);

  function createVault(
    address nfpm,
    INonfungiblePositionManager.MintParams memory params,
    string memory name,
    string memory symbol
  ) external returns (address krystalVaultV3);
}
