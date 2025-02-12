// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.28;
pragma abicoder v2;

interface IKrystalVaultV3Common {
  error ZeroAddress();

  error ZeroAmount();

  error IdenticalAddresses();

  error ExceededSupply();

  error InvalidFee();

  error InvalidAddress();

  error InvalidShares();

  error InvalidSender();

  error InvalidPriceRange();

  error InvalidAmount();

  error InvalidOwner();

  error InvalidVaultFactory();

  error InvalidPosition();
}
