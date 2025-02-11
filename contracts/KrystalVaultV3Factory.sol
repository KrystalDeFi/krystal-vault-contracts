// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { INonfungiblePositionManager } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { KrystalVaultV3 } from "./KrystalVaultV3.sol";

import "./interfaces/IKrystalVaultV3Factory.sol";

/// @title KrystalVaultV3Factory
contract KrystalVaultV3Factory is Ownable, IKrystalVaultV3Factory {
  IUniswapV3Factory public uniswapV3Factory;

  mapping(address => Vault[]) public vaultsByAddress;

  address[] public allVaults;

  constructor(address uniswapV3FactoryAddress) Ownable(_msgSender()) {
    require(uniswapV3FactoryAddress != address(0), ZeroAddress());
    uniswapV3Factory = IUniswapV3Factory(uniswapV3FactoryAddress);
  }

  /// @notice Get the number of KrystalVaultV3 created
  /// @return Number of KrystalVaultV3 created
  function allVaultsLength() external view override returns (uint256) {
    return allVaults.length;
  }

  /// @notice Create a KrystalVaultV3
  /// @param nfpm Address of INonfungiblePositionManager
  /// @param params MintParams of INonfungiblePositionManager
  /// @param name Name of the KrystalVaultV3
  /// @param symbol Symbol of the KrystalVaultV3
  /// @return krystalVaultV3 Address of KrystalVaultV3 created
  function createVault(
    address nfpm,
    INonfungiblePositionManager.MintParams memory params,
    string memory name,
    string memory symbol
  ) external override returns (address krystalVaultV3) {
    require(params.token0 != params.token1, IdenticalAddresses());

    (address token0, address token1) = params.token0 < params.token1
      ? (params.token0, params.token1)
      : (params.token1, params.token0);

    require(token0 != address(0), ZeroAddress());
    require(token1 != address(0), ZeroAddress());

    int24 tickSpacing = uniswapV3Factory.feeAmountTickSpacing(params.fee);

    require(tickSpacing != 0, InvalidFee());

    address pool = uniswapV3Factory.getPool(token0, token1, params.fee);
    if (pool == address(0)) {
      pool = uniswapV3Factory.createPool(token0, token1, params.fee);
    }

    krystalVaultV3 = address(new KrystalVaultV3(nfpm, pool, _msgSender(), params, name, symbol));

    vaultsByAddress[_msgSender()].push(Vault(_msgSender(), krystalVaultV3, nfpm, params));
    allVaults.push(krystalVaultV3);

    emit VaultCreated(_msgSender(), krystalVaultV3, nfpm, params, allVaults.length);

    return krystalVaultV3;
  }
}
