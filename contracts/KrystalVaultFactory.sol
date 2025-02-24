// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import { INonfungiblePositionManager } from "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import { IMulticall } from "@uniswap/v3-periphery/contracts/interfaces/IMulticall.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

import { KrystalVault } from "./KrystalVault.sol";

import "./interfaces/IKrystalVaultFactory.sol";
import { IWETH9 } from "./interfaces/IWETH9.sol";

/// @title KrystalVaultFactory
contract KrystalVaultFactory is Ownable, Pausable, IKrystalVaultFactory, IMulticall {
  using SafeERC20 for IERC20;
  IUniswapV3Factory public uniswapV3Factory;
  address public krystalVaultImplementation;
  address public krystalVaultAutomator;

  mapping(address => Vault[]) public vaultsByAddress;

  address[] public allVaults;
  address public platformFeeRecipient;
  uint16 public platformFeeBasisPoint;
  address public optimalSwapper;

  constructor(
    address uniswapV3FactoryAddress,
    address krystalVaultImplementationAddress,
    address krystalVaultAutomatorAddress,
    address optimalSwapperAddress,
    address platformFeeRecipientAddress,
    uint16 _platformFeeBasisPoint
  ) Ownable(_msgSender()) {
    require(uniswapV3FactoryAddress != address(0), ZeroAddress());
    require(krystalVaultImplementationAddress != address(0), ZeroAddress());
    require(krystalVaultAutomatorAddress != address(0), ZeroAddress());
    require(optimalSwapperAddress != address(0), ZeroAddress());
    require(platformFeeRecipientAddress != address(0), ZeroAddress());
    uniswapV3Factory = IUniswapV3Factory(uniswapV3FactoryAddress);
    krystalVaultImplementation = krystalVaultImplementationAddress;
    krystalVaultAutomator = krystalVaultAutomatorAddress;
    optimalSwapper = optimalSwapperAddress;
    platformFeeRecipient = platformFeeRecipientAddress;
    platformFeeBasisPoint = _platformFeeBasisPoint;
  }

  /// @notice Create a KrystalVault
  /// @param params CreateVaultParams parameter for vault creation
  /// @return vault Address of KrystalVault created
  function createVault(
    CreateVaultParams calldata params
  ) external payable override whenNotPaused returns (address vault) {
    require(params.mintParams.token0 != params.mintParams.token1, IdenticalAddresses());
    require(params.ownerFeeBasisPoint <= 1000, InvalidOwnerFee());

    (address token0, address token1) = params.mintParams.token0 < params.mintParams.token1
      ? (params.mintParams.token0, params.mintParams.token1)
      : (params.mintParams.token1, params.mintParams.token0);

    require(token0 != address(0), ZeroAddress());
    require(token1 != address(0), ZeroAddress());

    int24 tickSpacing = uniswapV3Factory.feeAmountTickSpacing(params.mintParams.fee);

    require(tickSpacing != 0, InvalidFee());

    address pool = uniswapV3Factory.getPool(token0, token1, params.mintParams.fee);
    if (pool == address(0)) {
      revert PoolNotFound();
    }

    vault = Clones.clone(krystalVaultImplementation);
    KrystalVault(vault).initialize(
      params.nfpm,
      pool,
      params.owner,
      VaultConfig({
        platformFeeBasisPoint: platformFeeBasisPoint,
        platformFeeRecipient: platformFeeRecipient,
        ownerFeeBasisPoint: params.ownerFeeBasisPoint
      }),
      params.name,
      params.symbol,
      optimalSwapper,
      krystalVaultAutomator
    );
    address weth = INonfungiblePositionManager(params.nfpm).WETH9();

    if (token0 == weth && msg.value > 0) {
      require(msg.value == params.mintParams.amount0Desired, InvalidAmount());
      IWETH9(weth).deposit{ value: msg.value }();
      IWETH9(weth).transfer(vault, msg.value);
    }else {
      IERC20(token0).safeTransferFrom(_msgSender(), vault, params.mintParams.amount0Desired);
    }
    if (token1 == weth && msg.value > 0) {
      require(msg.value == params.mintParams.amount0Desired, InvalidAmount());
      IWETH9(weth).deposit{ value: msg.value }();
      IWETH9(weth).transfer(vault, msg.value);
    } else {
      IERC20(token1).safeTransferFrom(_msgSender(), vault, params.mintParams.amount1Desired);
    }

    KrystalVault(vault).mintPosition(
      params.owner,
      params.mintParams.tickLower,
      params.mintParams.tickUpper,
      params.mintParams.amount0Min,
      params.mintParams.amount1Min
    );

    vaultsByAddress[params.owner].push(Vault(params.owner, vault, params.nfpm, params.mintParams));
    allVaults.push(vault);

    emit VaultCreated(params.owner, vault, params.nfpm, params.mintParams, allVaults.length);
  }

  /// @notice Pause the contract
  function pause() public onlyOwner {
    _pause();
  }

  /// @notice Unpause the contract
  function unpause() public onlyOwner {
    _unpause();
  }

  /// @notice Set the Vault implementation
  /// @param _krystalVaultImplementation Address of the new KrystalVault implementation
  function setKrystalVaultImplementation(address _krystalVaultImplementation) public onlyOwner {
    krystalVaultImplementation = _krystalVaultImplementation;
  }

  /// @notice Set the KrystalVaultAutomator address
  /// @param _krystalVaultAutomator Address of the new KrystalVaultAutomator
  function setKrystalVaultAutomator(address _krystalVaultAutomator) public onlyOwner {
    krystalVaultAutomator = _krystalVaultAutomator;
  }

  /// @notice Set the default platform fee recipient
  /// @param _platformFeeRecipient Address of the new platform fee recipient
  function setPlatformFeeRecipient(address _platformFeeRecipient) public onlyOwner {
    platformFeeRecipient = _platformFeeRecipient;
  }

  /// @notice Set the default platform fee basis point
  /// @param _platformFeeBasisPoint New platform fee basis point
  function setPlatformFeeBasisPoint(uint16 _platformFeeBasisPoint) public onlyOwner {
    platformFeeBasisPoint = _platformFeeBasisPoint;
  }

  /// @inheritdoc IMulticall
  function multicall(bytes[] calldata data) public payable override returns (bytes[] memory results) {
    results = new bytes[](data.length);
    for (uint256 i = 0; i < data.length; i++) {
      (bool success, bytes memory result) = address(this).delegatecall(data[i]);

      if (!success) {
        // Next 5 lines from https://ethereum.stackexchange.com/a/83577
        if (result.length < 68) revert("Multicall: failed");
        assembly {
          result := add(result, 0x04)
        }
        revert(abi.decode(result, (string)));
      }

      results[i] = result;
    }
  }
}
