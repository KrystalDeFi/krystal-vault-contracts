// SPDX-License-Identifier: BUSL-1.1

pragma solidity =0.7.6;
pragma abicoder v2;

interface IKrystalVaultV3Factory {
  event VaultCreated(address token0, address token1, uint24 fee, address krystalVaultV3, uint256);

  function allVaultsLength() external view returns (uint256);

  function createVault(
    address tokenA,
    address tokenB,
    uint24 fee,
    string memory name,
    string memory symbol
  ) external returns (address krystalVaultV3);
}
