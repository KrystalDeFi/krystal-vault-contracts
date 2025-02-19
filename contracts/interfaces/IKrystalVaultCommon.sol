// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;

interface IKrystalVaultCommon {
  struct VaultConfig {
    uint16 platformFeeBasisPoint;
    address platformFeeRecipient;
    uint16 ownerFeeBasisPoint;
  }

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

  error InvalidOwnerFee();
}
