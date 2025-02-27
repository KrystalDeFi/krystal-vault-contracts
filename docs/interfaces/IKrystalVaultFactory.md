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

### CreateVaultParams

```solidity
struct CreateVaultParams {
  address owner;
  address nfpm;
  struct INonfungiblePositionManager.MintParams mintParams;
  uint16 ownerFeeBasisPoint;
  string name;
  string symbol;
}
```

### createVault

```solidity
function createVault(struct IKrystalVaultFactory.CreateVaultParams params) external payable returns (address krystalVault)
```
