// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { INonfungiblePositionManager } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { KrystalVault } from "./KrystalVault.sol";

import "./interfaces/IKrystalVaultFactory.sol";

/// @title KrystalVaultFactory
contract KrystalVaultFactory is Ownable, Pausable, IKrystalVaultFactory {
  using SafeERC20 for IERC20;
  IUniswapV3Factory public uniswapV3Factory;
  address public krystalVaultImplementation;

  mapping(address => Vault[]) public vaultsByAddress;

  address[] public allVaults;
  address public platformFeeRecipient;
  uint16 public platformFeeBasisPoint;
  uint16 public ownerFeeBasisPoint;
  address public optimalSwapper;

  constructor(
    address uniswapV3FactoryAddress,
    address krystalVaultImplementationAddress,
    address optimalSwapperAddress,
    address platformFeeRecipientAddress,
    uint16 _platformFeeBasisPoint,
    uint16 _ownerFeeBasisPoint
  ) Ownable(_msgSender()) {
    require(uniswapV3FactoryAddress != address(0), ZeroAddress());
    require(krystalVaultImplementationAddress != address(0), ZeroAddress());
    require(optimalSwapperAddress != address(0), ZeroAddress());
    require(platformFeeRecipientAddress != address(0), ZeroAddress());
    uniswapV3Factory = IUniswapV3Factory(uniswapV3FactoryAddress);
    krystalVaultImplementation = krystalVaultImplementationAddress;
    optimalSwapper = optimalSwapperAddress;
    platformFeeRecipient = platformFeeRecipientAddress;
    platformFeeBasisPoint = _platformFeeBasisPoint;
    ownerFeeBasisPoint = _ownerFeeBasisPoint;
  }

  /// @notice Create a KrystalVault
  /// @param nfpm Address of INonfungiblePositionManager
  /// @param params MintParams of INonfungiblePositionManager
  /// @param name Name of the KrystalVault
  /// @param symbol Symbol of the KrystalVault
  /// @return krystalVault Address of KrystalVault created
  function createVault(
    address nfpm,
    INonfungiblePositionManager.MintParams memory params,
    string memory name,
    string memory symbol
  ) external override whenNotPaused returns (address krystalVault) {
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
      revert PoolNotFound();
    }

    krystalVault = Clones.clone(krystalVaultImplementation);
    KrystalVault vault = KrystalVault(krystalVault);

    vault.initialize(
      nfpm,
      pool,
      _msgSender(),
      name,
      symbol,
      platformFeeBasisPoint,
      platformFeeRecipient,
      ownerFeeBasisPoint,
      optimalSwapper
    );

    IERC20(token0).safeTransferFrom(_msgSender(), krystalVault, params.amount0Desired);
    IERC20(token1).safeTransferFrom(_msgSender(), krystalVault, params.amount1Desired);

    vault.mintPosition(_msgSender(), params.tickLower, params.tickUpper, params.amount0Min, params.amount1Min);

    vaultsByAddress[_msgSender()].push(Vault(_msgSender(), krystalVault, nfpm, params));
    allVaults.push(krystalVault);

    emit VaultCreated(_msgSender(), krystalVault, nfpm, params, allVaults.length);

    return krystalVault;
  }

  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  function setPlatformFeeRecipient(address _platformFeeRecipient) public onlyOwner {
    platformFeeRecipient = _platformFeeRecipient;
  }

  function setPlatformFeeBasisPoint(uint16 _platformFeeBasisPoint) public onlyOwner {
    platformFeeBasisPoint = _platformFeeBasisPoint;
  }

  function setOwnerFeeBasisPoint(uint16 _ownerFeeBasisPoint) public onlyOwner {
    ownerFeeBasisPoint = _ownerFeeBasisPoint;
  }
}
