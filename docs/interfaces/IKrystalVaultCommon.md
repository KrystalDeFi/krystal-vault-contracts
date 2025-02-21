# Solidity API

## IKrystalVaultCommon

### VaultConfig

```solidity
struct VaultConfig {
  uint16 platformFeeBasisPoint;
  address platformFeeRecipient;
  uint16 ownerFeeBasisPoint;
}
```

### ZeroAddress

```solidity
error ZeroAddress()
```

### ZeroAmount

```solidity
error ZeroAmount()
```

### IdenticalAddresses

```solidity
error IdenticalAddresses()
```

### ExceededSupply

```solidity
error ExceededSupply()
```

### Unauthorized

```solidity
error Unauthorized()
```

### PoolNotFound

```solidity
error PoolNotFound()
```

### InvalidFee

```solidity
error InvalidFee()
```

### InvalidAddress

```solidity
error InvalidAddress()
```

### InvalidShares

```solidity
error InvalidShares()
```

### InvalidSender

```solidity
error InvalidSender()
```

### InvalidPriceRange

```solidity
error InvalidPriceRange()
```

### InvalidAmount

```solidity
error InvalidAmount()
```

### InvalidOwner

```solidity
error InvalidOwner()
```

### InvalidPosition

```solidity
error InvalidPosition()
```

### InvalidOwnerFee

```solidity
error InvalidOwnerFee()
```

