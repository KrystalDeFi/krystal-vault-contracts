// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

interface IKrystalVaultCommon {
  error ZeroAddress();

  error ZeroAmount();

  error IdenticalAddresses();

  error ExceededSupply();

  error Unauthorized();

  error PoolNotFound();

  error InvalidFee();

  error InvalidAddress();

  error InvalidShares();

  error InvalidSender();

  error InvalidPriceRange();

  error InvalidAmount();

  error InvalidOwner();

  error InvalidPosition();
}
