# Solidity API

## KrystalVaultFactory

### uniswapV3Factory

```solidity
contract IUniswapV3Factory uniswapV3Factory
```

### krystalVaultImplementation

```solidity
address krystalVaultImplementation
```

### krystalVaultAutomator

```solidity
address krystalVaultAutomator
```

### vaultsByAddress

```solidity
mapping(address => struct IKrystalVaultFactory.Vault[]) vaultsByAddress
```

### allVaults

```solidity
address[] allVaults
```

### platformFeeRecipient

```solidity
address platformFeeRecipient
```

### platformFeeBasisPoint

```solidity
uint16 platformFeeBasisPoint
```

### optimalSwapper

```solidity
address optimalSwapper
```

### constructor

```solidity
constructor(address uniswapV3FactoryAddress, address krystalVaultImplementationAddress, address krystalVaultAutomatorAddress, address optimalSwapperAddress, address platformFeeRecipientAddress, uint16 _platformFeeBasisPoint) public
```

### createVault

```solidity
function createVault(struct IKrystalVaultFactory.CreateVaultParams params) external payable returns (address vault)
```

Create a KrystalVault

#### Parameters

| Name   | Type                                          | Description                                    |
| ------ | --------------------------------------------- | ---------------------------------------------- |
| params | struct IKrystalVaultFactory.CreateVaultParams | CreateVaultParams parameter for vault creation |

#### Return Values

| Name  | Type    | Description                     |
| ----- | ------- | ------------------------------- |
| vault | address | Address of KrystalVault created |

### pause

```solidity
function pause() public
```

Pause the contract

### unpause

```solidity
function unpause() public
```

Unpause the contract

### setKrystalVaultImplementation

```solidity
function setKrystalVaultImplementation(address _krystalVaultImplementation) public
```

Set the Vault implementation

#### Parameters

| Name                         | Type    | Description                                    |
| ---------------------------- | ------- | ---------------------------------------------- |
| \_krystalVaultImplementation | address | Address of the new KrystalVault implementation |

### setKrystalVaultAutomator

```solidity
function setKrystalVaultAutomator(address _krystalVaultAutomator) public
```

Set the KrystalVaultAutomator address

#### Parameters

| Name                    | Type    | Description                              |
| ----------------------- | ------- | ---------------------------------------- |
| \_krystalVaultAutomator | address | Address of the new KrystalVaultAutomator |

### setOptimalSwapper

```solidity
function setOptimalSwapper(address _optimalSwapper) public
```

Set the optimal swapper address

#### Parameters

| Name             | Type    | Description                        |
| ---------------- | ------- | ---------------------------------- |
| \_optimalSwapper | address | Address of the new optimal swapper |

### setPlatformFeeRecipient

```solidity
function setPlatformFeeRecipient(address _platformFeeRecipient) public
```

Set the default platform fee recipient

#### Parameters

| Name                   | Type    | Description                               |
| ---------------------- | ------- | ----------------------------------------- |
| \_platformFeeRecipient | address | Address of the new platform fee recipient |

### setPlatformFeeBasisPoint

```solidity
function setPlatformFeeBasisPoint(uint16 _platformFeeBasisPoint) public
```

Set the default platform fee basis point

#### Parameters

| Name                    | Type   | Description                  |
| ----------------------- | ------ | ---------------------------- |
| \_platformFeeBasisPoint | uint16 | New platform fee basis point |

### multicall

```solidity
function multicall(bytes[] data) public payable returns (bytes[] results)
```

Call multiple functions in the current contract and return the data from all of them if they all succeed

_The `msg.value` should not be trusted for any method callable from multicall._

#### Parameters

| Name | Type    | Description                                                              |
| ---- | ------- | ------------------------------------------------------------------------ |
| data | bytes[] | The encoded function data for each of the calls to make to this contract |

#### Return Values

| Name    | Type    | Description                                           |
| ------- | ------- | ----------------------------------------------------- |
| results | bytes[] | The results from each of the calls passed in via data |
