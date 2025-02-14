# Krystal Vault Contracts

This repository contains the smart contracts for the Krystal Vault. The contracts are written in Solidity and are
designed to work with the Ethereum blockchain and other EVM-compatible chains. The contracts should work well with all
Uniswap V3 Liquidity Pool types.

## Table of Contents

- [Krystal Vault Contracts](#krystal-vault-contracts)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Compile](#compile)
    - [Test](#test)
    - [Deploy](#deploy)
  - [Deployment](#deployment)
  - [Contracts](#contracts)
  - [Events](#events)
    - [KrystalVaultV3](#krystalvaultv3)
    - [KrystalVaultV3Factory](#krystalvaultv3factory)

## Installation

To install the dependencies, run:

```sh
yarn install
```

## Usage

### Compile

To compile the smart contracts, run:

```sh
yarn compile
```

### Test

To run the tests, use:

```sh
yarn test
```

### Deploy

To deploy the contracts, use:

```sh
yarn deploy
```

## Deployment

The deployment scripts logic are located in the `scripts` directory. The main deployment logic script is
`deployLogic.ts`. The main deployment script is `cmd.sh`. The deployment script uses the `hardhat` framework to deploy
the contracts.

## Contracts

The main contracts in this repository are:

- `KrystalVaultV3`: The main vault contract.
- `KrystalVaultV3Factory`: Factory contract to create new vault instances.

## Events

The contracts emit various events. Some of the key events are:

### KrystalVaultV3

- `AddLiquidity`
- `Approval`
- `Compound`
- `EIP712DomainChanged`
- `FeeCollected`
- `Initialized`
- `OwnershipTransferred`
- `SetFee`
- `SetWhitelist`
- `Transfer`
- `VaultDeposit`
- `VaultExit`
- `VaultPositionMint`
- `VaultRebalance`
- `VaultWithdraw`

### KrystalVaultV3Factory

- `OwnershipTransferred`
- `Paused`
- `Unpaused`
- `VaultCreated`
