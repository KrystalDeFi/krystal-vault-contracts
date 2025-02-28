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

### setKrystalVaultImplementation

```solidity
function setKrystalVaultImplementation(address _krystalVaultImplementation) external
```

### setKrystalVaultAutomator

```solidity
function setKrystalVaultAutomator(address _krystalVaultAutomator) external
```

### setOptimalSwapper

```solidity
function setOptimalSwapper(address _optimalSwapper) external
```

### setPlatformFeeRecipient

```solidity
function setPlatformFeeRecipient(address _platformFeeRecipient) external
```

### setPlatformFeeBasisPoint

```solidity
function setPlatformFeeBasisPoint(uint16 _platformFeeBasisPoint) external
```
