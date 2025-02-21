# Solidity API

## IKrystalVaultFactory

### Vault

```solidity
struct Vault {
  address owner;
  address krystalVault;
  address nfpm;
  struct INonfungiblePositionManager.MintParams params;
}
```

### VaultCreated

```solidity
event VaultCreated(address owner, address krystalVault, address nfpm, struct INonfungiblePositionManager.MintParams params, uint256 vaultsLength)
```

### createVault

```solidity
function createVault(address owner, address nfpm, struct INonfungiblePositionManager.MintParams params, uint16 ownerFeeBasisPoint, string name, string symbol) external returns (address krystalVault)
```

