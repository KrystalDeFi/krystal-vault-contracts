// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

import { KrystalVaultV3 } from "./KrystalVaultV3.sol";

import "./interfaces/IKrystalVaultV3Factory.sol";

/// @title KrystalVaultV3Factory
contract KrystalVaultV3Factory is Ownable, IKrystalVaultV3Factory {
  IUniswapV3Factory public uniswapV3Factory;

  address public depositor;

  mapping(address => mapping(address => mapping(uint24 => address))) public vaults;

  address[] public allVaults;

  constructor(address _uniswapV3Factory, address _depositor) {
    require(_uniswapV3Factory != address(0), "uniswapV3Factory should be non-zero");
    uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
    depositor = _depositor;
  }

  /// @notice Get the number of KrystalVaultV3 created
  /// @return Number of KrystalVaultV3 created
  function allVaultsLength() external view override returns (uint256) {
    return allVaults.length;
  }

  /// @notice Create a KrystalVaultV3
  /// @param tokenA Address of token0
  /// @param tokenB Address of token1
  /// @param fee The desired fee for the KrystalVaultV3
  /// @param name Name of the KrystalVaultV3
  /// @param symbol Symbol of the KrystalVaultV3
  /// @return krystalVaultV3 Address of KrystalVaultV3 created
  function createVault(
    address tokenA,
    address tokenB,
    uint24 fee,
    string memory name,
    string memory symbol
  ) external override returns (address krystalVaultV3) {
    require(tokenA != tokenB, "SF: IDENTICAL_ADDRESSES");

    (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);

    require(token0 != address(0), "SF: ZERO_ADDRESS");
    require(token1 != address(0), "SF: ZERO_ADDRESS");
    require(vaults[token0][token1][fee] == address(0), "SF: KRYSTALVAULTV3_EXISTS");

    int24 tickSpacing = uniswapV3Factory.feeAmountTickSpacing(fee);

    require(tickSpacing != 0, "SF: INCORRECT_FEE");

    address pool = uniswapV3Factory.getPool(token0, token1, fee);
    if (pool == address(0)) {
      pool = uniswapV3Factory.createPool(token0, token1, fee);
    }

    krystalVaultV3 = address(
      new KrystalVaultV3{ salt: keccak256(abi.encodePacked(token0, token1, fee, tickSpacing)) }(
        pool,
        _msgSender(),
        depositor,
        name,
        symbol
      )
    );

    vaults[token0][token1][fee] = krystalVaultV3;
    vaults[token1][token0][fee] = krystalVaultV3;
    allVaults.push(krystalVaultV3);

    emit VaultCreated(token0, token1, fee, krystalVaultV3, allVaults.length);

    return krystalVaultV3;
  }

  function setDepositor(address _depositor) external override onlyOwner {
    depositor = _depositor;

    emit DepositorSet(_depositor);
  }
}
