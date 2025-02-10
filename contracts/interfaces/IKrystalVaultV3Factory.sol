// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;
pragma abicoder v2;

interface IKrystalVaultV3Factory {
  struct Vault {
    address owner;
    address krystalVaultV3;
    address token0;
    address token1;
    uint24 fee;
  }

  event VaultCreated(
    address indexed owner,
    address indexed krystalVaultV3,
    address token0,
    address token1,
    uint24 fee,
    uint256 vaultsLength
  );

  function allVaultsLength() external view returns (uint256);

  function createVault(
    address tokenA,
    address tokenB,
    uint24 fee,
    string memory name,
    string memory symbol
  ) external returns (address krystalVaultV3);
}
