# Solidity API

## Whitelist

### AccessControlManager

```solidity
contract IAccessControlManager AccessControlManager
```

### whitelistedAddresses

```solidity
mapping(address => bool) whitelistedAddresses
```

_Returns true if the address is in the whitelist, false otherwise._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

### whitelistEnabled

```solidity
bool whitelistEnabled
```

_Returns true if the whitelist is enabled, false otherwise.
    @return bool representing whether the whitelist is enabled._

### constructor

```solidity
constructor() public
```

### checkZeroAddress

```solidity
modifier checkZeroAddress(address _address)
```

_Modifier to check for empty addresses_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to check |

### checkRole

```solidity
modifier checkRole(bytes32 role)
```

Helper to check the sender against the given role

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| role | bytes32 | The role to check for the msg.sender |

### checkWhitelist

```solidity
modifier checkWhitelist(address _address)
```

_Method checks if the whitelist is enabled and also whether the address is in the whitelist, reverting if true._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to check in the whitelist |

### __Whitelist_init

```solidity
function __Whitelist_init(contract IAccessControlManager _accessControlManager) internal
```

_This contract is intended to be inherited from a parent contract, so using an onlyInitializing modifier to allow that._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _accessControlManager | contract IAccessControlManager | The access control manager to use for role management |

### addToWhitelist

```solidity
function addToWhitelist(address _address) external
```

_Adds the specified address to the whitelist, reverts if not the platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to add. |

### batchAddToWhitelist

```solidity
function batchAddToWhitelist(address[] _addresses) external
```

_Adds the array of addresses to the whitelist, reverts if not the platform admin._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addresses | address[] | The address to add. |

### removeFromWhitelist

```solidity
function removeFromWhitelist(address _address) external
```

_Removes the specified address from the whitelist, reverts if not the platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to remove. |

### batchRemoveFromWhitelist

```solidity
function batchRemoveFromWhitelist(address[] _addresses) external
```

_Removes the array of addresses from the whitelist, reverts if not the platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addresses | address[] | The array of addresses to remove. |

### enableWhitelist

```solidity
function enableWhitelist() external
```

_Enables the whitelist, allowing only whitelisted addresses to interact with the contract. Reverts if the caller is not the platform admin_

### disableWhitelist

```solidity
function disableWhitelist() external
```

_Disables the whitelist, allowing all addresses to interact with the contract. Reverts if the caller is not the platform admin_

### _checkAndAddToWhitelist

```solidity
function _checkAndAddToWhitelist(address _address) internal
```

_This method checks if the given address is the zero address or is in the whitelist already, reverting if true; otherwise the address is added and an event is emitted_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to check and add to the whitelist |

### _checkAndRemoveFromWhitelist

```solidity
function _checkAndRemoveFromWhitelist(address _address) internal
```

_This method checks if the address doesn't exist within the whitelist and reverts if true, otherwise the address is removed from the whitelist and an event is emitted_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to check and remove from the whitelist |

## swETH

Contract for handling user deposits in ETH in exchange for swETH at the stored rate. Also handles the rate updates from the BOT wallet which will occur at a fixed interval.

_This contract inherits the Whitelist contract which holds the Access control manager state variable and the checkRole modifier_

### lastRepriceETHReserves

```solidity
uint256 lastRepriceETHReserves
```

_Returns the ETH reserves that were provided in the most recent call to the reprice function_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### swellTreasuryRewardPercentage

```solidity
uint256 swellTreasuryRewardPercentage
```

_Returns the current swell treasury reward percentage._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### nodeOperatorRewardPercentage

```solidity
uint256 nodeOperatorRewardPercentage
```

_Returns the current node operator reward percentage._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### lastRepriceUNIX

```solidity
uint256 lastRepriceUNIX
```

_Returns the last time the reprice method was called in UNIX_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### totalETHDeposited

```solidity
uint256 totalETHDeposited
```

_Returns the total ETH that has been deposited over the protocols lifespan_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### minimumRepriceTime

```solidity
uint256 minimumRepriceTime
```

_Returns the minimum reprice time_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### maximumRepriceDifferencePercentage

```solidity
uint256 maximumRepriceDifferencePercentage
```

_Returns the maximum percentage difference with 1e18 precision_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### maximumRepriceswETHDifferencePercentage

```solidity
uint256 maximumRepriceswETHDifferencePercentage
```

_Returns the maximum percentage difference with 1e18 precision_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### constructor

```solidity
constructor() public
```

### fallback

```solidity
fallback() external
```

### initialize

```solidity
function initialize(contract IAccessControlManager _accessControlManager) external
```

### withdrawERC20

```solidity
function withdrawERC20(contract IERC20 _token) external
```

_This method withdraws contract's _token balance to a platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | contract IERC20 | The ERC20 token to withdraw from the contract |

### setSwellTreasuryRewardPercentage

```solidity
function setSwellTreasuryRewardPercentage(uint256 _newSwellTreasuryRewardPercentage) external
```

Only a platform admin can call this function.

_Sets the new swell treasury reward percentage._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newSwellTreasuryRewardPercentage | uint256 | The new swell treasury reward percentage to set. |

### setNodeOperatorRewardPercentage

```solidity
function setNodeOperatorRewardPercentage(uint256 _newNodeOperatorRewardPercentage) external
```

Only a platform admin can call this function.

_Sets the new node operator reward percentage._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newNodeOperatorRewardPercentage | uint256 | The new node operator reward percentage to set. |

### setMinimumRepriceTime

```solidity
function setMinimumRepriceTime(uint256 _minimumRepriceTime) external
```

Only a platform admin can call this function.

_Sets the minimum permitted time between successful repricing calls using the block timestamp._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _minimumRepriceTime | uint256 | The new minimum time between successful repricing calls |

### setMaximumRepriceswETHDifferencePercentage

```solidity
function setMaximumRepriceswETHDifferencePercentage(uint256 _maximumRepriceswETHDifferencePercentage) external
```

Only a platform admin can call this function.

_Sets the maximum percentage allowable difference in swETH supplied to repricing compared to current swETH supply._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _maximumRepriceswETHDifferencePercentage | uint256 | The new maximum percentage swETH supply difference allowed. |

### setMaximumRepriceDifferencePercentage

```solidity
function setMaximumRepriceDifferencePercentage(uint256 _maximumRepriceDifferencePercentage) external
```

Only a platform admin can call this function.

_Sets the maximum percentage allowable difference in swETH to ETH price changes for a repricing call._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _maximumRepriceDifferencePercentage | uint256 | The new maximum percentage difference in repricing rate. |

### swETHToETHRate

```solidity
function swETHToETHRate() external view returns (uint256)
```

_Returns the current SwETH to ETH rate, returns 1:1 if no reprice has occurred otherwise it returns the swETHToETHRateFixed rate._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current SwETH to ETH rate. |

### ethToSwETHRate

```solidity
function ethToSwETHRate() external view returns (uint256)
```

_Returns the current ETH to SwETH rate._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current ETH to SwETH rate. |

### getRate

```solidity
function getRate() external view returns (uint256)
```

### deposit

```solidity
function deposit() external payable
```

The amount of ETH deposited will be converted to SwETH at the current SwETH to ETH rate

_Deposits ETH into the contract_

### reprice

```solidity
function reprice(uint256 _preRewardETHReserves, uint256 _newETHRewards, uint256 _swETHTotalSupply) external
```

//  * TODO: Reword

_This method reprices the swETH -> ETH rate, this will be called via an offchain service on a regular interval, likely ~1 day. The swETH total supply is passed as an argument to avoid a potential race conditions between the off-chain reserve calculations and the on-chain repricing
This method also mints a percentage of swETH as rewards to be claimed by NO's and the swell treasury. The formula for determining the amount of swETH to mint is the following: swETHToMint = (swETHSupply * newETHRewards * feeRate) / (preRewardETHReserves - newETHRewards * feeRate + newETHRewards)
The formula is quite complicated because it needs to factor in the updated exchange rate whilst it calculates the amount of swETH rewards to mint. This ensures the rewards aren't double-minted and are backed by ETH._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _preRewardETHReserves | uint256 | The PoR value exclusive of the new ETH rewards earned |
| _newETHRewards | uint256 | The total amount of new ETH earnt over the period. |
| _swETHTotalSupply | uint256 | The total swETH supply at the time of off-chain reprice calculation |

### _ethToSwETHRate

```solidity
function _ethToSwETHRate() internal view returns (UD60x18)
```

_Returns the ETH -> swETH rate, if no PoR reading has come through the rate is 1:1_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | UD60x18 | The rate as a fixed-point type |

### _swETHToETHRate

```solidity
function _swETHToETHRate() internal view returns (UD60x18)
```

_Returns the swETH -> ETH rate, if no PoR reading has come in the rate is 1:1_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | UD60x18 | The rate as a fixed-point type |

### _absolute

```solidity
function _absolute(uint256 _a, uint256 _b) internal pure returns (uint256)
```

_Returns the absolute difference between two uint256 values_

## IAccessControlManager

### InitializeParams

```solidity
struct InitializeParams {
  address admin;
  address swellTreasury;
}
```

### AlreadyPaused

```solidity
error AlreadyPaused()
```

_Error thrown when attempting to pause an already-paused boolean_

### AlreadyUnpaused

```solidity
error AlreadyUnpaused()
```

_Error thrown when attempting to unpause an already-unpaused boolean_

### UpdatedDepositManager

```solidity
event UpdatedDepositManager(address newAddress, address oldAddress)
```

_Emitted when a new DepositManager contract address is set.
    @param newAddress The new DepositManager contract address.
    @param oldAddress The old DepositManager contract address._

### UpdatedNodeOperatorRegistry

```solidity
event UpdatedNodeOperatorRegistry(address newAddress, address oldAddress)
```

_Emitted when a new NodeOperatorRegistry contract address is set.
    @param newAddress The new NodeOperatorRegistry contract address.
    @param oldAddress The old NodeOperatorRegistry contract address._

### UpdatedSwellTreasury

```solidity
event UpdatedSwellTreasury(address newAddress, address oldAddress)
```

_Emitted when a new SwellTreasury contract address is set.
    @param newAddress The new SwellTreasury contract address.
    @param oldAddress The old SwellTreasury contract address._

### UpdatedSwETH

```solidity
event UpdatedSwETH(address newAddress, address oldAddress)
```

_Emitted when a new SwETH contract address is set.
    @param newAddress The new SwETH contract address.
    @param oldAddress The old SwETH contract address._

### CoreMethodsPause

```solidity
event CoreMethodsPause(bool newPausedStatus)
```

_Emitted when core methods functionality is paused or unpaused.
    @param newPausedStatus The new paused status._

### BotMethodsPause

```solidity
event BotMethodsPause(bool newPausedStatus)
```

_Emitted when bot methods functionality is paused or unpaused.
    @param newPausedStatus The new paused status._

### OperatorMethodsPause

```solidity
event OperatorMethodsPause(bool newPausedStatus)
```

_Emitted when operator methods functionality is paused or unpaused.
    @param newPausedStatus The new paused status._

### WithdrawalsPause

```solidity
event WithdrawalsPause(bool newPausedStatus)
```

_Emitted when withdrawals functionality is paused or unpaused.
    @param newPausedStatus The new paused status._

### checkRole

```solidity
function checkRole(bytes32 role, address account) external view
```

_Pass-through method to call the _checkRole method on the inherited access control contract. This method is to be used by external contracts that are using this centralised access control manager, this ensures that if the check fails it reverts with the correct access control error message_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| role | bytes32 | The role to check |
| account | address | The account to check for |

### setSwETH

```solidity
function setSwETH(contract IswETH _swETH) external
```

Sets the `swETH` address to `_swETH`.

_This function is only callable by the `PLATFORM_ADMIN` role._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _swETH | contract IswETH | The address of the `swETH` contract. |

### setDepositManager

```solidity
function setDepositManager(contract IDepositManager _depositManager) external
```

Sets the `DepositManager` address to `_depositManager`.

_This function is only callable by the `PLATFORM_ADMIN` role._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _depositManager | contract IDepositManager | The address of the `DepositManager` contract. |

### setNodeOperatorRegistry

```solidity
function setNodeOperatorRegistry(contract INodeOperatorRegistry _NodeOperatorRegistry) external
```

Sets the `NodeOperatorRegistry` address to `_NodeOperatorRegistry`.

_This function is only callable by the `PLATFORM_ADMIN` role._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NodeOperatorRegistry | contract INodeOperatorRegistry | The address of the `NodeOperatorRegistry` contract. |

### setSwellTreasury

```solidity
function setSwellTreasury(address _swellTreasury) external
```

Sets the `SwellTreasury` address to `_swellTreasury`.

_This function is only callable by the `PLATFORM_ADMIN` role._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _swellTreasury | address | The new address of the `SwellTreasury` contract. |

### PLATFORM_ADMIN

```solidity
function PLATFORM_ADMIN() external pure returns (bytes32)
```

_Returns the PLATFORM_ADMIN role.
    @return The bytes32 representation of the PLATFORM_ADMIN role._

### swETH

```solidity
function swETH() external returns (contract IswETH)
```

_Returns the Swell ETH contract.
    @return The Swell ETH contract._

### SwellTreasury

```solidity
function SwellTreasury() external returns (address)
```

_Returns the address of the Swell Treasury contract.
    @return The address of the Swell Treasury contract._

### DepositManager

```solidity
function DepositManager() external returns (contract IDepositManager)
```

_Returns the Deposit Manager contract.
    @return The Deposit Manager contract._

### NodeOperatorRegistry

```solidity
function NodeOperatorRegistry() external returns (contract INodeOperatorRegistry)
```

_Returns the Node Operator Registry contract.
    @return The Node Operator Registry contract._

### coreMethodsPaused

```solidity
function coreMethodsPaused() external returns (bool)
```

_Returns true if core methods are currently paused.
    @return Whether core methods are paused._

### botMethodsPaused

```solidity
function botMethodsPaused() external returns (bool)
```

_Returns true if bot methods are currently paused.
    @return Whether bot methods are paused._

### operatorMethodsPaused

```solidity
function operatorMethodsPaused() external returns (bool)
```

_Returns true if operator methods are currently paused.
    @return Whether operator methods are paused._

### withdrawalsPaused

```solidity
function withdrawalsPaused() external returns (bool)
```

_Returns true if withdrawals are currently paused.
    @dev ! Note that this is completely unused in the current implementation and is a placeholder that will be used once the withdrawals are implemented.
    @return Whether withdrawals are paused._

### pauseCoreMethods

```solidity
function pauseCoreMethods() external
```

_Pauses the core methods of the Swell ecosystem, only callable by the PLATFORM_ADMIN_

### unpauseCoreMethods

```solidity
function unpauseCoreMethods() external
```

_Unpauses the core methods of the Swell ecosystem, only callable by the PLATFORM_ADMIN_

### pauseBotMethods

```solidity
function pauseBotMethods() external
```

_Pauses the bot specific methods, only callable by the PLATFORM_ADMIN_

### unpauseBotMethods

```solidity
function unpauseBotMethods() external
```

_Unpauses the bot specific methods, only callable by the PLATFORM_ADMIN_

### pauseOperatorMethods

```solidity
function pauseOperatorMethods() external
```

_Pauses the operator methods in the NO registry contract, only callable by the PLATFORM_ADMIN_

### unpauseOperatorMethods

```solidity
function unpauseOperatorMethods() external
```

_Unpauses the operator methods in the NO registry contract, only callable by the PLATFORM_ADMIN_

### pauseWithdrawals

```solidity
function pauseWithdrawals() external
```

_Pauses the withdrawals of the Swell ecosystem, only callable by the PLATFORM_ADMIN_

### unpauseWithdrawals

```solidity
function unpauseWithdrawals() external
```

_Unpauses the withdrawals of the Swell ecosystem, only callable by the PLATFORM_ADMIN_

### withdrawERC20

```solidity
function withdrawERC20(contract IERC20 _token) external
```

_This method withdraws contract's _token balance to a platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | contract IERC20 | The ERC20 token to withdraw from the contract |

## IDepositManager

The interface for the deposit manager contract

### InvalidETHWithdrawCaller

```solidity
error InvalidETHWithdrawCaller()
```

_Error thrown when calling the withdrawETH method from an account that isn't the swETH contract_

### InvalidDepositDataRoot

```solidity
error InvalidDepositDataRoot()
```

_Error thrown when the depositDataRoot parameter in the setupValidators contract doesn't match the onchain deposit data root from the deposit contract_

### InsufficientETHBalance

```solidity
error InsufficientETHBalance()
```

_Error thrown when setting up new validators and the contract doesn't hold enough ETH to be able to set them up._

### ValidatorsSetup

```solidity
event ValidatorsSetup(bytes[] pubKeys)
```

Emitted when new validators are setup

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubKeys | bytes[] | The pubKeys that have been used for validator setup |

### ETHReceived

```solidity
event ETHReceived(address from, uint256 amount)
```

_Event is fired when some contracts receive ETH_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The account that sent the ETH |
| amount | uint256 | The amount of ETH received |

### withdrawERC20

```solidity
function withdrawERC20(contract IERC20 _token) external
```

_This method withdraws contract's _token balance to a platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | contract IERC20 | The ERC20 token to withdraw from the contract |

### getWithdrawalCredentials

```solidity
function getWithdrawalCredentials() external view returns (bytes withdrawalCredentials)
```

_Formats ETH1 the withdrawal credentials according to the following standard: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/validator.md#eth1_address_withdrawal_prefix
It doesn't outline the withdrawal prefixes, they can be found here: https://eth2book.info/altair/part3/config/constants#withdrawal-prefixes
As the DepositManager on the execution layer is going to be the withdrawal contract, we will be doing ETH1 withdrawals. The standard for this is a 32 byte response where; the first byte stores the withdrawal prefix (0x01), the following 11 bytes are empty and the last 20 bytes are the address_

### setupValidators

```solidity
function setupValidators(bytes[] _pubKeys, bytes32 _depositDataRoot) external
```

It also provides protection against front-running by operators, it does this by ensuring that the depositDataRoot provided matches the onchain beacon deposit contract's deposit data root, more details on the vulnerability here: https://research.lido.fi/t/mitigations-for-deposit-front-running-vulnerability/1239

_This method allows setting up of new validators in the beacon deposit contract, it ensures the provided pubKeys are unused by calling the NO registry_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKeys | bytes[] | The pubKeys to setup |
| _depositDataRoot | bytes32 | The deposit contracts deposit root which MUST match the current beacon deposit contract deposit data root otherwise the contract will revert due to the risk of the front-running vulnerability. |

## INodeOperatorRegistry

Interface for the Node Operator Registry contract.

### ValidatorDetails

```solidity
struct ValidatorDetails {
  bytes pubKey;
  bytes signature;
}
```

### Operator

```solidity
struct Operator {
  bool enabled;
  address rewardAddress;
  address controllingAddress;
  string name;
  uint128 activeValidators;
}
```

### OperatorAdded

```solidity
event OperatorAdded(address operatorAddress, address rewardAddress)
```

_Emitted when a new operator is added._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operatorAddress | address | The address of the newly added operator. |
| rewardAddress | address | The address associated with the reward for the operator. |

### OperatorEnabled

```solidity
event OperatorEnabled(address operator)
```

_Emitted when an operator is enabled._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the operator that was enabled. |

### OperatorDisabled

```solidity
event OperatorDisabled(address operator)
```

_Emitted when an operator is disabled._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the operator that was disabled. |

### OperatorAddedValidatorDetails

```solidity
event OperatorAddedValidatorDetails(address operator, struct INodeOperatorRegistry.ValidatorDetails[] pubKeys)
```

_Emitted when the validator details for an operator are added._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the operator for which the validator details were added. |
| pubKeys | struct INodeOperatorRegistry.ValidatorDetails[] | An array of `ValidatorDetails` for the operator. |

### ActivePubKeysDeleted

```solidity
event ActivePubKeysDeleted(bytes[] pubKeys)
```

_Emitted when active public keys are deleted._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubKeys | bytes[] | An array of public keys that were deleted. |

### PendingPubKeysDeleted

```solidity
event PendingPubKeysDeleted(bytes[] pubKeys)
```

_Emitted when pending public keys are deleted._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubKeys | bytes[] | An array of public keys that were deleted. |

### PubKeysUsedForValidatorSetup

```solidity
event PubKeysUsedForValidatorSetup(bytes[] pubKeys)
```

_Emitted when public keys are used for validator setup._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubKeys | bytes[] | An array of public keys that were used for validator setup. |

### NoOperatorFound

```solidity
error NoOperatorFound(address operator)
```

_Thrown when an operator is not found._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the operator that was not found. |

### OperatorAlreadyExists

```solidity
error OperatorAlreadyExists(address operator)
```

_Thrown when an operator already exists._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | address | The address of the operator that already exists. |

### OperatorAlreadyEnabled

```solidity
error OperatorAlreadyEnabled()
```

_Thrown when an operator is already enabled._

### OperatorAlreadyDisabled

```solidity
error OperatorAlreadyDisabled()
```

_Thrown when an operator is already disabled._

### InvalidArrayLengthOfZero

```solidity
error InvalidArrayLengthOfZero()
```

_Thrown when an array length of zero is invalid._

### AmountOfValidatorDetailsExceedsLimit

```solidity
error AmountOfValidatorDetailsExceedsLimit()
```

_Thrown when an operator is adding new validator details and this causes the total amount of operator's validator details to exceed uint128_

### NextOperatorPubKeyMismatch

```solidity
error NextOperatorPubKeyMismatch(bytes foundPubKey, bytes providedPubKey)
```

_Thrown during setup of new validators, when comparing the next operator's public key to the provided public key they should match. This ensures consistency in the tracking of the active and pending validator details._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| foundPubKey | bytes | The operator's next available public key |
| providedPubKey | bytes | The public key that was passed in as an argument |

### OperatorOutOfPendingKeys

```solidity
error OperatorOutOfPendingKeys()
```

_Thrown during the setup of new validators and when the operator that has no pending details left to use_

### NoPubKeyFound

```solidity
error NoPubKeyFound(bytes pubKey)
```

_Thrown when the given pubKey hasn't been added to the registry and cannot be found_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubKey | bytes | The public key that was not found. |

### CannotUseDisabledOperator

```solidity
error CannotUseDisabledOperator()
```

_Thrown when an operator tries to use the node operator registry whilst they are disabled_

### CannotAddDuplicatePubKey

```solidity
error CannotAddDuplicatePubKey(bytes existingKey)
```

_Thrown when a duplicate public key is added._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| existingKey | bytes | The public key that already exists. |

### MissingPendingValidatorDetails

```solidity
error MissingPendingValidatorDetails(bytes pubKey)
```

_Thrown when the given pubKey doesn't exist in the pending validator details sets_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubKey | bytes | The missing pubKey |

### MissingActiveValidatorDetails

```solidity
error MissingActiveValidatorDetails(bytes pubKey)
```

_Thrown when the pubKey doesn't exist in the active validator details set_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubKey | bytes | The missing pubKey |

### InvalidPubKeySetupCaller

```solidity
error InvalidPubKeySetupCaller()
```

_Throw when the msg.sender isn't the Deposit Manager contract_

### InvalidPubKeyLength

```solidity
error InvalidPubKeyLength()
```

_Thrown when an operator is trying to add validator details and a provided pubKey isn't the correct length_

### InvalidSignatureLength

```solidity
error InvalidSignatureLength()
```

_Thrown when an operator is trying to add validator details and a provided signature isn't the correct length_

### withdrawERC20

```solidity
function withdrawERC20(contract IERC20 _token) external
```

_This method withdraws contract's _token balance to a platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | contract IERC20 | The ERC20 token to withdraw from the contract |

### getNextValidatorDetails

```solidity
function getNextValidatorDetails(uint256 _numNewValidators) external view returns (struct INodeOperatorRegistry.ValidatorDetails[], uint256 foundValidators)
```

This method tries to return enough validator details to equal the provided _numNewValidators, but if there aren't enough validator details to find, it will simply return what it found, and the caller will need to check for empty values.

_Gets the next available validator details, ordered by operators with the least amount of active validators. There may be less available validators then the provided _numNewValidators amount, in that case the function will return an array of length equal to _numNewValidators but all indexes after the second return value; foundValidators, will be 0x0 values_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _numNewValidators | uint256 | The number of new validators to get details for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct INodeOperatorRegistry.ValidatorDetails[] | An array of ValidatorDetails and the length of the array of non-zero validator details |
| foundValidators | uint256 |  |

### usePubKeysForValidatorSetup

```solidity
function usePubKeysForValidatorSetup(bytes[] _pubKeys) external returns (struct INodeOperatorRegistry.ValidatorDetails[] validatorDetails)
```

This method will be called when the DepositManager is setting up new validators.

_Allows the DepositManager to move provided _pubKeys from the pending validator details arrays into the active validator details array. It also returns the validator details, so that the DepositManager can pass the signature along to the ETH2 deposit contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKeys | bytes[] | Array of public keys to use for validator setup. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| validatorDetails | struct INodeOperatorRegistry.ValidatorDetails[] | The associated validator details for the given public keys |

### addNewValidatorDetails

```solidity
function addNewValidatorDetails(struct INodeOperatorRegistry.ValidatorDetails[] _validatorDetails) external
```

_Adds new validator details to the registry.
  /**
 Callable by node operator's to add their validator details to the setup queue_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _validatorDetails | struct INodeOperatorRegistry.ValidatorDetails[] | Array of ValidatorDetails to add. |

### addOperator

```solidity
function addOperator(string _name, address _operatorAddress, address _rewardAddress) external
```

Throws if an operator already exists with the given _operatorAddress

_Adds a new operator to the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _name | string | Name of the operator. |
| _operatorAddress | address | Address of the operator. |
| _rewardAddress | address | Address of the reward recipient for this operator. |

### enableOperator

```solidity
function enableOperator(address _operatorAddress) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Enables an operator in the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | Address of the operator to enable. |

### disableOperator

```solidity
function disableOperator(address _operatorAddress) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Disables an operator in the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | Address of the operator to disable. |

### updateOperatorControllingAddress

```solidity
function updateOperatorControllingAddress(address _operatorAddress, address _newOperatorAddress) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Updates the controlling address of an operator in the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | Current address of the operator. |
| _newOperatorAddress | address | New address of the operator. |

### updateOperatorRewardAddress

```solidity
function updateOperatorRewardAddress(address _operatorAddress, address _newRewardAddress) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Updates the reward address of an operator in the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | Address of the operator to update. |
| _newRewardAddress | address | New reward address for the operator. |

### updateOperatorName

```solidity
function updateOperatorName(address _operatorAddress, string _name) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Updates the name of an operator in the registry_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The address of the operator to update |
| _name | string | The new name for the operator |

### deletePendingValidators

```solidity
function deletePendingValidators(bytes[] _pubKeys) external
```

Throws InvalidArrayLengthOfZero if the length of _pubKeys is 0
Throws NoPubKeyFound if any of the provided pubKeys is not found in the pending validators set

_Allows the PLATFORM_ADMIN to delete validators that are pending. This is likely to be called via an admin if a public key fails the front-running checks_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKeys | bytes[] | The public keys of the pending validators to delete |

### deleteActiveValidators

```solidity
function deleteActiveValidators(bytes[] _pubKeys) external
```

Throws NoPubKeyFound if any of the provided pubKeys is not found in the active validators set
Throws InvalidArrayLengthOfZero if the length of _pubKeys is 0

_Allows the PLATFORM_ADMIN to delete validator public keys that have been used to setup a validator and that validator has now exited_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKeys | bytes[] | The public keys of the active validators to delete |

### AccessControlManager

```solidity
function AccessControlManager() external returns (contract IAccessControlManager)
```

_Returns the address of the AccessControlManager contract_

### getOperator

```solidity
function getOperator(address _operatorAddress) external view returns (struct INodeOperatorRegistry.Operator operator, uint128 totalValidatorDetails, uint128 operatorId)
```

Throws NoOperatorFound if the operator address is not found in the registry

_Returns the operator details for a given operator address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The address of the operator to retrieve |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | struct INodeOperatorRegistry.Operator | The operator details, including name, reward address, and enabled status |
| totalValidatorDetails | uint128 | The total amount of validator details for an operator |
| operatorId | uint128 | The operator's Id |

### getOperatorsPendingValidatorDetails

```solidity
function getOperatorsPendingValidatorDetails(address _operatorAddress) external returns (struct INodeOperatorRegistry.ValidatorDetails[])
```

Throws NoOperatorFound if the operator address is not found in the registry

_Returns the pending validator details for a given operator address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The address of the operator to retrieve pending validator details for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | struct INodeOperatorRegistry.ValidatorDetails[] | validatorDetails The pending validator details for the given operator |

### getOperatorsActiveValidatorDetails

```solidity
function getOperatorsActiveValidatorDetails(address _operatorAddress) external returns (struct INodeOperatorRegistry.ValidatorDetails[] validatorDetails)
```

Throws NoOperatorFound if the operator address is not found in the registry

_Returns the active validator details for a given operator address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The address of the operator to retrieve active validator details for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| validatorDetails | struct INodeOperatorRegistry.ValidatorDetails[] | The active validator details for the given operator |

### getRewardDetailsForOperatorId

```solidity
function getRewardDetailsForOperatorId(uint128 _operatorId) external returns (address rewardAddress, uint128 activeValidators)
```

_Returns the reward details for a given operator Id, this method is used in the swETH contract when paying swETH rewards_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorId | uint128 | The operator Id to get the reward details for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| rewardAddress | address | The reward address of the operator |
| activeValidators | uint128 | The amount of active validators for the operator |

### numOperators

```solidity
function numOperators() external returns (uint128)
```

_Returns the number of operators in the registry_

### numPendingValidators

```solidity
function numPendingValidators() external returns (uint256)
```

_Returns the amount of pending validator keys in the registry_

### getOperatorIdForAddress

```solidity
function getOperatorIdForAddress(address _operator) external returns (uint128 _operatorId)
```

Throws NoOperatorFound if the operator address is not found in the registry

_Returns the operator ID for a given operator address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operator | address | The address of the operator to retrieve the operator ID for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorId | uint128 | The operator ID for the given operator |

### getOperatorIdForPubKey

```solidity
function getOperatorIdForPubKey(bytes pubKey) external returns (uint128)
```

Returns 0 if no operatorId controls the pubKey

_Returns the `operatorId` associated with the given `pubKey`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubKey | bytes | The public key to lookup the `operatorId` for. |

## IWhitelist

_Interface for managing a whitelist of addresses._

### AddedToWhitelist

```solidity
event AddedToWhitelist(address _address)
```

_Emitted when an address is added to the whitelist._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address that was added to the whitelist. |

### RemovedFromWhitelist

```solidity
event RemovedFromWhitelist(address _address)
```

_Emitted when an address is removed from the whitelist._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address that was removed from the whitelist. |

### WhitelistEnabled

```solidity
event WhitelistEnabled()
```

_Emitted when the whitelist is enabled._

### WhitelistDisabled

```solidity
event WhitelistDisabled()
```

_Emitted when the whitelist is disabled._

### AddressAlreadyInWhitelist

```solidity
error AddressAlreadyInWhitelist(address _address)
```

_Throws an error indicating that the address is already in the whitelist._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address that already exists in the whitelist. |

### AddressMissingFromWhitelist

```solidity
error AddressMissingFromWhitelist(address _address)
```

_Throws an error indicating that the address is missing from the whitelist._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address that is missing from the whitelist. |

### WhitelistAlreadyEnabled

```solidity
error WhitelistAlreadyEnabled()
```

_Throws an error indicating that the whitelist is already enabled._

### WhitelistAlreadyDisabled

```solidity
error WhitelistAlreadyDisabled()
```

_Throws an error indicating that the whitelist is already disabled._

### NotInWhitelist

```solidity
error NotInWhitelist()
```

_Throws an error indicating that the address is not in the whitelist._

### whitelistEnabled

```solidity
function whitelistEnabled() external returns (bool)
```

_Returns true if the whitelist is enabled, false otherwise.
    @return bool representing whether the whitelist is enabled._

### whitelistedAddresses

```solidity
function whitelistedAddresses(address _address) external returns (bool)
```

_Returns true if the address is in the whitelist, false otherwise._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to check.     @return bool representing whether the address is in the whitelist. |

### addToWhitelist

```solidity
function addToWhitelist(address _address) external
```

_Adds the specified address to the whitelist, reverts if not the platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to add. |

### batchAddToWhitelist

```solidity
function batchAddToWhitelist(address[] _addresses) external
```

_Adds the array of addresses to the whitelist, reverts if not the platform admin._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addresses | address[] | The address to add. |

### removeFromWhitelist

```solidity
function removeFromWhitelist(address _address) external
```

_Removes the specified address from the whitelist, reverts if not the platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to remove. |

### batchRemoveFromWhitelist

```solidity
function batchRemoveFromWhitelist(address[] _addresses) external
```

_Removes the array of addresses from the whitelist, reverts if not the platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _addresses | address[] | The array of addresses to remove. |

### enableWhitelist

```solidity
function enableWhitelist() external
```

_Enables the whitelist, allowing only whitelisted addresses to interact with the contract. Reverts if the caller is not the platform admin_

### disableWhitelist

```solidity
function disableWhitelist() external
```

_Disables the whitelist, allowing all addresses to interact with the contract. Reverts if the caller is not the platform admin_

## IswETH

_This interface provides the methods to interact with the SwETH contract._

### CannotRepriceWithZeroSwETHSupply

```solidity
error CannotRepriceWithZeroSwETHSupply()
```

_Error thrown when attempting to reprice with zero SwETH supply._

### InvalidPreRewardETHReserves

```solidity
error InvalidPreRewardETHReserves()
```

_Error thrown when passing a preRewardETHReserves value equal to 0 into the repricing function_

### NoActiveValidators

```solidity
error NoActiveValidators()
```

_Error thrown when repricing the rate and distributing rewards to NOs when they are no active validators. This condition should never happen; it means that no active validators were running but we still have rewards, despite this it's still here for security_

### RewardPercentageTotalOverflow

```solidity
error RewardPercentageTotalOverflow()
```

_Error thrown when updating the reward percentage for either the NOs or the swell treasury and the update will cause the NO percentage + swell treasury percentage to exceed 100%._

### NotEnoughTimeElapsedForReprice

```solidity
error NotEnoughTimeElapsedForReprice(uint256 remainingTime)
```

_Thrown when calling the reprice function and not enough time has elapsed between the previous repriace and the current reprice._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| remainingTime | uint256 | Remaining time until reprice can be called |

### RepriceDifferenceTooLarge

```solidity
error RepriceDifferenceTooLarge(uint256 repriceDiff, uint256 maximumRepriceDiff)
```

_Thrown when repricing the rate and the difference in reserves values is greater than expected_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| repriceDiff | uint256 | The difference between the previous swETH rate and what would be the updated rate |
| maximumRepriceDiff | uint256 | The maximum allowed difference in swETH rate |

### RepriceswETHDifferenceTooLarge

```solidity
error RepriceswETHDifferenceTooLarge(uint256 repriceswETHDiff, uint256 maximumswETHRepriceDiff)
```

_Thrown during repricing when the difference in swETH supplied to repricing compared to the actual supply is too great_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| repriceswETHDiff | uint256 | The difference between the swETH supplied to repricing and actual supply |
| maximumswETHRepriceDiff | uint256 | The maximum allowed difference in swETH supply |

### ETHWithdrawn

```solidity
event ETHWithdrawn(address to, uint256 swETHBurned, uint256 ethReturned)
```

_Event emitted when a user withdraws ETH for swETH_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| to | address | Address of the recipient. |
| swETHBurned | uint256 | Amount of SwETH burned in the transaction. |
| ethReturned | uint256 | Amount of ETH returned in the transaction. |

### SwellTreasuryRewardPercentageUpdate

```solidity
event SwellTreasuryRewardPercentageUpdate(uint256 oldPercentage, uint256 newPercentage)
```

_Event emitted when the swell treasury reward percentage is updated.
Only callable by the platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| oldPercentage | uint256 | The previous swell treasury reward percentage. |
| newPercentage | uint256 | The new swell treasury reward percentage. |

### NodeOperatorRewardPercentageUpdate

```solidity
event NodeOperatorRewardPercentageUpdate(uint256 oldPercentage, uint256 newPercentage)
```

_Event emitted when the node operator reward percentage is updated.
Only callable by the platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| oldPercentage | uint256 | The previous node operator reward percentage. |
| newPercentage | uint256 | The new node operator reward percentage. |

### Reprice

```solidity
event Reprice(uint256 newEthReserves, uint256 newSwETHToETHRate, uint256 nodeOperatorRewards, uint256 swellTreasuryRewards, uint256 totalETHDeposited)
```

_Event emitted when the swETH - ETH rate is updated_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| newEthReserves | uint256 | The new ETH reserves for the swell protocol |
| newSwETHToETHRate | uint256 | The new SwETH to ETH rate. |
| nodeOperatorRewards | uint256 | The rewards for the node operator's. |
| swellTreasuryRewards | uint256 | The rewards for the swell treasury. |
| totalETHDeposited | uint256 | Current total ETH staked at time of reprice. |

### ETHDepositReceived

```solidity
event ETHDepositReceived(address from, uint256 amount, uint256 swETHMinted, uint256 newTotalETHDeposited)
```

_Event is fired when some contracts receive ETH_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| from | address | The account that sent the ETH |
| amount | uint256 | The amount of ETH received |
| swETHMinted | uint256 | The amount of swETH minted to the caller |
| newTotalETHDeposited | uint256 |  |

### MinimumRepriceTimeUpdated

```solidity
event MinimumRepriceTimeUpdated(uint256 _oldMinimumRepriceTime, uint256 _newMinimumRepriceTime)
```

_Event emitted on a successful call to setMinimumRepriceTime_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _oldMinimumRepriceTime | uint256 | The old reprice time |
| _newMinimumRepriceTime | uint256 | The new updated reprice time |

### MaximumRepriceswETHDifferencePercentageUpdated

```solidity
event MaximumRepriceswETHDifferencePercentageUpdated(uint256 _oldMaximumRepriceswETHDifferencePercentage, uint256 _newMaximumRepriceswETHDifferencePercentage)
```

_Event emitted on a successful call to setMaximumRepriceswETHDifferencePercentage_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _oldMaximumRepriceswETHDifferencePercentage | uint256 | The old maximum swETH supply difference |
| _newMaximumRepriceswETHDifferencePercentage | uint256 | The new updated swETH supply difference |

### MaximumRepriceDifferencePercentageUpdated

```solidity
event MaximumRepriceDifferencePercentageUpdated(uint256 _oldMaximumRepriceDifferencePercentage, uint256 _newMaximumRepriceDifferencePercentage)
```

_Event emitted on a successful call to setMaximumRepriceDifferencePercentage_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _oldMaximumRepriceDifferencePercentage | uint256 | The old maximum reprice difference |
| _newMaximumRepriceDifferencePercentage | uint256 | The new updated maximum reprice difference |

### withdrawERC20

```solidity
function withdrawERC20(contract IERC20 _token) external
```

_This method withdraws contract's _token balance to a platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | contract IERC20 | The ERC20 token to withdraw from the contract |

### lastRepriceETHReserves

```solidity
function lastRepriceETHReserves() external returns (uint256)
```

_Returns the ETH reserves that were provided in the most recent call to the reprice function_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The last recorded ETH reserves |

### lastRepriceUNIX

```solidity
function lastRepriceUNIX() external returns (uint256)
```

_Returns the last time the reprice method was called in UNIX_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The UNIX timestamp of the last time reprice was called |

### totalETHDeposited

```solidity
function totalETHDeposited() external returns (uint256)
```

_Returns the total ETH that has been deposited over the protocols lifespan_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current total amount of ETH that has been deposited |

### swellTreasuryRewardPercentage

```solidity
function swellTreasuryRewardPercentage() external returns (uint256)
```

_Returns the current swell treasury reward percentage._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current swell treasury reward percentage. |

### nodeOperatorRewardPercentage

```solidity
function nodeOperatorRewardPercentage() external returns (uint256)
```

_Returns the current node operator reward percentage._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current node operator reward percentage. |

### swETHToETHRate

```solidity
function swETHToETHRate() external returns (uint256)
```

_Returns the current SwETH to ETH rate, returns 1:1 if no reprice has occurred otherwise it returns the swETHToETHRateFixed rate._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current SwETH to ETH rate. |

### ethToSwETHRate

```solidity
function ethToSwETHRate() external returns (uint256)
```

_Returns the current ETH to SwETH rate._

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The current ETH to SwETH rate. |

### minimumRepriceTime

```solidity
function minimumRepriceTime() external returns (uint256)
```

_Returns the minimum reprice time_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The minimum reprice time |

### maximumRepriceDifferencePercentage

```solidity
function maximumRepriceDifferencePercentage() external returns (uint256)
```

_Returns the maximum percentage difference with 1e18 precision_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The maximum percentage difference |

### maximumRepriceswETHDifferencePercentage

```solidity
function maximumRepriceswETHDifferencePercentage() external returns (uint256)
```

_Returns the maximum percentage difference with 1e18 precision_

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The maximum percentage difference in suppled and actual swETH supply |

### setSwellTreasuryRewardPercentage

```solidity
function setSwellTreasuryRewardPercentage(uint256 _newSwellTreasuryRewardPercentage) external
```

Only a platform admin can call this function.

_Sets the new swell treasury reward percentage._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newSwellTreasuryRewardPercentage | uint256 | The new swell treasury reward percentage to set. |

### setNodeOperatorRewardPercentage

```solidity
function setNodeOperatorRewardPercentage(uint256 _newNodeOperatorRewardPercentage) external
```

Only a platform admin can call this function.

_Sets the new node operator reward percentage._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _newNodeOperatorRewardPercentage | uint256 | The new node operator reward percentage to set. |

### setMinimumRepriceTime

```solidity
function setMinimumRepriceTime(uint256 _minimumRepriceTime) external
```

Only a platform admin can call this function.

_Sets the minimum permitted time between successful repricing calls using the block timestamp._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _minimumRepriceTime | uint256 | The new minimum time between successful repricing calls |

### setMaximumRepriceswETHDifferencePercentage

```solidity
function setMaximumRepriceswETHDifferencePercentage(uint256 _maximumRepriceswETHDifferencePercentage) external
```

Only a platform admin can call this function.

_Sets the maximum percentage allowable difference in swETH supplied to repricing compared to current swETH supply._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _maximumRepriceswETHDifferencePercentage | uint256 | The new maximum percentage swETH supply difference allowed. |

### setMaximumRepriceDifferencePercentage

```solidity
function setMaximumRepriceDifferencePercentage(uint256 _maximumRepriceDifferencePercentage) external
```

Only a platform admin can call this function.

_Sets the maximum percentage allowable difference in swETH to ETH price changes for a repricing call._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _maximumRepriceDifferencePercentage | uint256 | The new maximum percentage difference in repricing rate. |

### deposit

```solidity
function deposit() external payable
```

The amount of ETH deposited will be converted to SwETH at the current SwETH to ETH rate

_Deposits ETH into the contract_

### reprice

```solidity
function reprice(uint256 _preRewardETHReserves, uint256 _newETHRewards, uint256 _swETHTotalSupply) external
```

//  * TODO: Reword

_This method reprices the swETH -> ETH rate, this will be called via an offchain service on a regular interval, likely ~1 day. The swETH total supply is passed as an argument to avoid a potential race conditions between the off-chain reserve calculations and the on-chain repricing
This method also mints a percentage of swETH as rewards to be claimed by NO's and the swell treasury. The formula for determining the amount of swETH to mint is the following: swETHToMint = (swETHSupply * newETHRewards * feeRate) / (preRewardETHReserves - newETHRewards * feeRate + newETHRewards)
The formula is quite complicated because it needs to factor in the updated exchange rate whilst it calculates the amount of swETH rewards to mint. This ensures the rewards aren't double-minted and are backed by ETH._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _preRewardETHReserves | uint256 | The PoR value exclusive of the new ETH rewards earned |
| _newETHRewards | uint256 | The total amount of new ETH earnt over the period. |
| _swETHTotalSupply | uint256 | The total swETH supply at the time of off-chain reprice calculation |

## SwellLib

This library contains roles, errors, events and functions that are widely used throughout the protocol

### PLATFORM_ADMIN

```solidity
bytes32 PLATFORM_ADMIN
```

_The platform admin role_

### BOT

```solidity
bytes32 BOT
```

_The bot role_

### CannotBeZeroAddress

```solidity
error CannotBeZeroAddress()
```

_Thrown when _checkZeroAddress is called with the zero address_

### InvalidMethodCall

```solidity
error InvalidMethodCall()
```

_Thrown in some contracts when the contract call is received by the fallback method_

### InvalidETHDeposit

```solidity
error InvalidETHDeposit()
```

_Thrown in some contracts when ETH is sent directly to the contract_

### CoreMethodsPaused

```solidity
error CoreMethodsPaused()
```

_Thrown when interacting with a method on the protocol that is disabled via the coreMethodsPaused bool_

### BotMethodsPaused

```solidity
error BotMethodsPaused()
```

_Thrown when interacting with a method on the protocol that is disabled via the botMethodsPaused bool_

### OperatorMethodsPaused

```solidity
error OperatorMethodsPaused()
```

_Thrown when interacting with a method on the protocol that is disabled via the operatorMethodsPaused bool_

### WithdrawalsPaused

```solidity
error WithdrawalsPaused()
```

_Thrown when interacting with a method on the protocol that is disabled via the withdrawalsPaused bool_

### NoTokensToWithdraw

```solidity
error NoTokensToWithdraw()
```

_Thrown when calling the withdrawERC20 method and the contracts balance is 0_

### _checkZeroAddress

```solidity
function _checkZeroAddress(address _address) internal pure
```

_This helper is used throughout the protocol to guard against zero addresses being passed as parameters_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to check if it is the zero address |

## IPoRAddresses

This interface enables Chainlink nodes to get the list addresses to be used in a PoR feed. A single
contract that implements this interface can only store an address list for a single PoR feed.

_All functions in this interface are expected to be called off-chain, so gas usage is not a big concern.
This makes it possible to store addresses in optimized data types and convert them to human-readable strings
in `getPoRAddressList()`._

### getPoRAddressListLength

```solidity
function getPoRAddressListLength() external view returns (uint256)
```

Get total number of addresses in the list.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The array length |

### getPoRAddressList

```solidity
function getPoRAddressList(uint256 startIndex, uint256 endIndex) external view returns (string[])
```

Get a batch of human-readable addresses from the address list.

_Due to limitations of gas usage in off-chain calls, we need to support fetching the addresses in batches.
EVM addresses need to be converted to human-readable strings. The address strings need to be in the same format
that would be used when querying the balance of that address._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| startIndex | uint256 | The index of the first address in the batch. |
| endIndex | uint256 | The index of the last address in the batch. If `endIndex > getPoRAddressListLength()-1`, endIndex need to default to `getPoRAddressListLength()-1`. If `endIndex < startIndex`, the result would be an empty array. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string[] | Array of addresses as strings. |

## IRateProvider

This interface ensure compatibility with Balancer's Metastable pools, the getRate() method is used as the pool rate. This reduces arbitrages whenever the swETH rate increases from a repricing event.

_https://github.com/balancer-labs/metastable-rate-providers/blob/master/contracts/interfaces/IRateProvider.sol_

### getRate

```solidity
function getRate() external view returns (uint256)
```

## AccessControlManager

This contract will act as the centralized access control registry to use throughout the protocol. It also manages the pausing of protocol functionality.

### SwellTreasury

```solidity
address SwellTreasury
```

_Returns the address of the Swell Treasury contract.
    @return The address of the Swell Treasury contract._

### swETH

```solidity
contract IswETH swETH
```

_Returns the Swell ETH contract.
    @return The Swell ETH contract._

### DepositManager

```solidity
contract IDepositManager DepositManager
```

_Returns the Deposit Manager contract.
    @return The Deposit Manager contract._

### NodeOperatorRegistry

```solidity
contract INodeOperatorRegistry NodeOperatorRegistry
```

_Returns the Node Operator Registry contract.
    @return The Node Operator Registry contract._

### coreMethodsPaused

```solidity
bool coreMethodsPaused
```

_Returns true if core methods are currently paused.
    @return Whether core methods are paused._

### botMethodsPaused

```solidity
bool botMethodsPaused
```

_Returns true if bot methods are currently paused.
    @return Whether bot methods are paused._

### operatorMethodsPaused

```solidity
bool operatorMethodsPaused
```

_Returns true if operator methods are currently paused.
    @return Whether operator methods are paused._

### withdrawalsPaused

```solidity
bool withdrawalsPaused
```

_Returns true if withdrawals are currently paused.
    @dev ! Note that this is completely unused in the current implementation and is a placeholder that will be used once the withdrawals are implemented.
    @return Whether withdrawals are paused._

### constructor

```solidity
constructor() public
```

### checkZeroAddress

```solidity
modifier checkZeroAddress(address _address)
```

_Modifier to check for empty addresses_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to check |

### alreadyPausedStatus

```solidity
modifier alreadyPausedStatus(bool _currentStatus, bool _newStatus)
```

_Modifier to help paused status updates and throwing of errors when the paused status' are equal_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _currentStatus | bool | The current paused status |
| _newStatus | bool | The new status to update to |

### initialize

```solidity
function initialize(struct IAccessControlManager.InitializeParams _initializeParams) external
```

### withdrawERC20

```solidity
function withdrawERC20(contract IERC20 _token) external
```

_This method withdraws contract's _token balance to a platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | contract IERC20 | The ERC20 token to withdraw from the contract |

### checkRole

```solidity
function checkRole(bytes32 role, address account) external view
```

_Pass-through method to call the _checkRole method on the inherited access control contract. This method is to be used by external contracts that are using this centralised access control manager, this ensures that if the check fails it reverts with the correct access control error message_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| role | bytes32 | The role to check |
| account | address | The account to check for |

### setSwETH

```solidity
function setSwETH(contract IswETH _swETH) external
```

Sets the `swETH` address to `_swETH`.

_This function is only callable by the `PLATFORM_ADMIN` role._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _swETH | contract IswETH | The address of the `swETH` contract. |

### setDepositManager

```solidity
function setDepositManager(contract IDepositManager _depositManager) external
```

Sets the `DepositManager` address to `_depositManager`.

_This function is only callable by the `PLATFORM_ADMIN` role._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _depositManager | contract IDepositManager | The address of the `DepositManager` contract. |

### setNodeOperatorRegistry

```solidity
function setNodeOperatorRegistry(contract INodeOperatorRegistry _NodeOperatorRegistry) external
```

Sets the `NodeOperatorRegistry` address to `_NodeOperatorRegistry`.

_This function is only callable by the `PLATFORM_ADMIN` role._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _NodeOperatorRegistry | contract INodeOperatorRegistry | The address of the `NodeOperatorRegistry` contract. |

### setSwellTreasury

```solidity
function setSwellTreasury(address _swellTreasury) external
```

Sets the `SwellTreasury` address to `_swellTreasury`.

_This function is only callable by the `PLATFORM_ADMIN` role._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _swellTreasury | address | The new address of the `SwellTreasury` contract. |

### pauseCoreMethods

```solidity
function pauseCoreMethods() external
```

_Pauses the core methods of the Swell ecosystem, only callable by the PLATFORM_ADMIN_

### unpauseCoreMethods

```solidity
function unpauseCoreMethods() external
```

_Unpauses the core methods of the Swell ecosystem, only callable by the PLATFORM_ADMIN_

### pauseBotMethods

```solidity
function pauseBotMethods() external
```

_Pauses the bot specific methods, only callable by the PLATFORM_ADMIN_

### unpauseBotMethods

```solidity
function unpauseBotMethods() external
```

_Unpauses the bot specific methods, only callable by the PLATFORM_ADMIN_

### pauseOperatorMethods

```solidity
function pauseOperatorMethods() external
```

_Pauses the operator methods in the NO registry contract, only callable by the PLATFORM_ADMIN_

### unpauseOperatorMethods

```solidity
function unpauseOperatorMethods() external
```

_Unpauses the operator methods in the NO registry contract, only callable by the PLATFORM_ADMIN_

### pauseWithdrawals

```solidity
function pauseWithdrawals() external
```

_Pauses the withdrawals of the Swell ecosystem, only callable by the PLATFORM_ADMIN_

### unpauseWithdrawals

```solidity
function unpauseWithdrawals() external
```

_Unpauses the withdrawals of the Swell ecosystem, only callable by the PLATFORM_ADMIN_

### PLATFORM_ADMIN

```solidity
function PLATFORM_ADMIN() external pure returns (bytes32)
```

_Returns the PLATFORM_ADMIN role.
    @return The bytes32 representation of the PLATFORM_ADMIN role._

## DepositManager

This contract will hold the ETH while awaiting new validator setup. This contract will also be used as the withdrawal_credentials when setting up new validators, so that any exited validator ETH and rewards will be sent here.

### AccessControlManager

```solidity
contract IAccessControlManager AccessControlManager
```

### DepositContract

```solidity
contract IDepositContract DepositContract
```

### constructor

```solidity
constructor() public
```

### checkRole

```solidity
modifier checkRole(bytes32 role)
```

### checkZeroAddress

```solidity
modifier checkZeroAddress(address _address)
```

_Modifier to check for empty addresses_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to check |

### fallback

```solidity
fallback() external
```

### receive

```solidity
receive() external payable
```

### initialize

```solidity
function initialize(contract IAccessControlManager _accessControlManager) external
```

### withdrawERC20

```solidity
function withdrawERC20(contract IERC20 _token) external
```

_This method withdraws contract's _token balance to a platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | contract IERC20 | The ERC20 token to withdraw from the contract |

### setupValidators

```solidity
function setupValidators(bytes[] _pubKeys, bytes32 _depositDataRoot) external
```

It also provides protection against front-running by operators, it does this by ensuring that the depositDataRoot provided matches the onchain beacon deposit contract's deposit data root, more details on the vulnerability here: https://research.lido.fi/t/mitigations-for-deposit-front-running-vulnerability/1239

_This method allows setting up of new validators in the beacon deposit contract, it ensures the provided pubKeys are unused by calling the NO registry_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKeys | bytes[] | The pubKeys to setup |
| _depositDataRoot | bytes32 | The deposit contracts deposit root which MUST match the current beacon deposit contract deposit data root otherwise the contract will revert due to the risk of the front-running vulnerability. |

### getWithdrawalCredentials

```solidity
function getWithdrawalCredentials() public view returns (bytes withdrawalCredentials)
```

_Formats ETH1 the withdrawal credentials according to the following standard: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/validator.md#eth1_address_withdrawal_prefix
It doesn't outline the withdrawal prefixes, they can be found here: https://eth2book.info/altair/part3/config/constants#withdrawal-prefixes
As the DepositManager on the execution layer is going to be the withdrawal contract, we will be doing ETH1 withdrawals. The standard for this is a 32 byte response where; the first byte stores the withdrawal prefix (0x01), the following 11 bytes are empty and the last 20 bytes are the address_

## NodeOperatorRegistry

This contract will hold all the node operators and any associated validator details. This contract will be used when fetching the next validators to setup and allows management of node operators.

### AccessControlManager

```solidity
contract IAccessControlManager AccessControlManager
```

_Returns the address of the AccessControlManager contract_

### numOperators

```solidity
uint128 numOperators
```

_Returns the number of operators in the registry_

### getOperatorForOperatorId

```solidity
mapping(uint128 => struct INodeOperatorRegistry.Operator) getOperatorForOperatorId
```

### getOperatorIdForAddress

```solidity
mapping(address => uint128) getOperatorIdForAddress
```

Throws NoOperatorFound if the operator address is not found in the registry

_Returns the operator ID for a given operator address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |

### operatorIdToValidatorDetails

```solidity
mapping(uint128 => struct EnumberableSetValidatorDetails.ValidatorDetailsSet) operatorIdToValidatorDetails
```

### numPendingValidators

```solidity
uint256 numPendingValidators
```

_Returns the amount of pending validator keys in the registry_

### activeValidatorIndexes

```solidity
struct EnumerableSetUpgradeable.Bytes32Set activeValidatorIndexes
```

### getOperatorIdForPubKey

```solidity
mapping(bytes => uint128) getOperatorIdForPubKey
```

Returns 0 if no operatorId controls the pubKey

_Returns the `operatorId` associated with the given `pubKey`._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |

### constructor

```solidity
constructor() public
```

### checkRole

```solidity
modifier checkRole(bytes32 role)
```

### checkZeroAddress

```solidity
modifier checkZeroAddress(address _address)
```

_Modifier to check for empty addresses_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _address | address | The address to check |

### fallback

```solidity
fallback() external
```

### initialize

```solidity
function initialize(contract IAccessControlManager _accessControlManager) external
```

### withdrawERC20

```solidity
function withdrawERC20(contract IERC20 _token) external
```

_This method withdraws contract's _token balance to a platform admin_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _token | contract IERC20 | The ERC20 token to withdraw from the contract |

### getNextValidatorDetails

```solidity
function getNextValidatorDetails(uint256 _numNewValidators) external view returns (struct INodeOperatorRegistry.ValidatorDetails[] validatorDetails, uint256 foundValidators)
```

This method tries to return enough validator details to equal the provided _numNewValidators, but if there aren't enough validator details to find, it will simply return what it found, and the caller will need to check for empty values.

_Gets the next available validator details, ordered by operators with the least amount of active validators. There may be less available validators then the provided _numNewValidators amount, in that case the function will return an array of length equal to _numNewValidators but all indexes after the second return value; foundValidators, will be 0x0 values_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _numNewValidators | uint256 | The number of new validators to get details for. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| validatorDetails | struct INodeOperatorRegistry.ValidatorDetails[] | An array of ValidatorDetails and the length of the array of non-zero validator details |
| foundValidators | uint256 |  |

### usePubKeysForValidatorSetup

```solidity
function usePubKeysForValidatorSetup(bytes[] _pubKeys) external returns (struct INodeOperatorRegistry.ValidatorDetails[] validatorDetails)
```

This method will be called when the DepositManager is setting up new validators.

_Allows the DepositManager to move provided _pubKeys from the pending validator details arrays into the active validator details array. It also returns the validator details, so that the DepositManager can pass the signature along to the ETH2 deposit contract._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKeys | bytes[] | Array of public keys to use for validator setup. |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| validatorDetails | struct INodeOperatorRegistry.ValidatorDetails[] | The associated validator details for the given public keys |

### addNewValidatorDetails

```solidity
function addNewValidatorDetails(struct INodeOperatorRegistry.ValidatorDetails[] _validatorDetails) external
```

_Adds new validator details to the registry.
  /**
 Callable by node operator's to add their validator details to the setup queue_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _validatorDetails | struct INodeOperatorRegistry.ValidatorDetails[] | Array of ValidatorDetails to add. |

### addOperator

```solidity
function addOperator(string _name, address _operatorAddress, address _rewardAddress) external
```

Throws if an operator already exists with the given _operatorAddress

_Adds a new operator to the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _name | string | Name of the operator. |
| _operatorAddress | address | Address of the operator. |
| _rewardAddress | address | Address of the reward recipient for this operator. |

### enableOperator

```solidity
function enableOperator(address _operatorAddress) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Enables an operator in the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | Address of the operator to enable. |

### disableOperator

```solidity
function disableOperator(address _operatorAddress) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Disables an operator in the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | Address of the operator to disable. |

### updateOperatorControllingAddress

```solidity
function updateOperatorControllingAddress(address _operatorAddress, address _newOperatorAddress) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Updates the controlling address of an operator in the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | Current address of the operator. |
| _newOperatorAddress | address | New address of the operator. |

### updateOperatorRewardAddress

```solidity
function updateOperatorRewardAddress(address _operatorAddress, address _newRewardAddress) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Updates the reward address of an operator in the registry._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | Address of the operator to update. |
| _newRewardAddress | address | New reward address for the operator. |

### updateOperatorName

```solidity
function updateOperatorName(address _operatorAddress, string _name) external
```

Throws NoOperatorFound if the operator address is not found in the registry

_Updates the name of an operator in the registry_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The address of the operator to update |
| _name | string | The new name for the operator |

### deletePendingValidators

```solidity
function deletePendingValidators(bytes[] _pubKeys) external
```

Throws InvalidArrayLengthOfZero if the length of _pubKeys is 0
Throws NoPubKeyFound if any of the provided pubKeys is not found in the pending validators set

_Allows the PLATFORM_ADMIN to delete validators that are pending. This is likely to be called via an admin if a public key fails the front-running checks_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKeys | bytes[] | The public keys of the pending validators to delete |

### deleteActiveValidators

```solidity
function deleteActiveValidators(bytes[] _pubKeys) external
```

Throws NoPubKeyFound if any of the provided pubKeys is not found in the active validators set
Throws InvalidArrayLengthOfZero if the length of _pubKeys is 0

_Allows the PLATFORM_ADMIN to delete validator public keys that have been used to setup a validator and that validator has now exited_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKeys | bytes[] | The public keys of the active validators to delete |

### getPoRAddressListLength

```solidity
function getPoRAddressListLength() external view returns (uint256)
```

Get total number of addresses in the list.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | uint256 | The array length |

### _parsePubKeyToString

```solidity
function _parsePubKeyToString(bytes pubKey) internal pure returns (string)
```

_This method parses a pure bytes array into it's string equivalent. We must loop through the pubKey to safely convert each byte into its string equivalent, if we cast it directly it causes the response to be corrupted_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubKey | bytes | The pubKey to parse |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | string | The string equivalent |

### getPoRAddressList

```solidity
function getPoRAddressList(uint256 _startIndex, uint256 _endIndex) external view returns (string[])
```

### _getOperatorSafe

```solidity
function _getOperatorSafe(address _operatorAddress) internal view returns (struct INodeOperatorRegistry.Operator operator)
```

Throws if an operator cannot be found for the provided address.

_This method safely returns an Operator struct from the provided _operatorAddress._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The controlling address of the given operator |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | struct INodeOperatorRegistry.Operator | The Operator struct |

### _getOperatorIdSafe

```solidity
function _getOperatorIdSafe(address _operatorAddress) internal view returns (uint128 operatorId)
```

Throws an error if the given _operatorAddress doesn't exist

_This method safely returns the operatorId of the given _operatorAddress_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The controlling address of the given operator |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| operatorId | uint128 | The operator's ID |

### _getOperatorIdForPubKeySafe

```solidity
function _getOperatorIdForPubKeySafe(bytes _pubKey) internal view returns (uint128 operatorId)
```

Throws if there is no found operatorId for the given _pubKey

_This method safely returns the operatorId of the given _pubKey_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKey | bytes | The public key to find an operator with |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| operatorId | uint128 | The operator ID that controls the given pubKey |

### _encodeOperatorIdAndKeyIndex

```solidity
function _encodeOperatorIdAndKeyIndex(uint128 operatorId, uint128 nextKey) internal pure returns (bytes32)
```

_This method encodes the provided operatorId and nextKey into a single bytes32 variable. This is used in the activeValidatorIndexes array_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| operatorId | uint128 | The operator id to encode |
| nextKey | uint128 | The key index to encode |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The encoded bytes32 variable |

### getOperator

```solidity
function getOperator(address _operatorAddress) external view returns (struct INodeOperatorRegistry.Operator operator, uint128 totalValidatorDetails, uint128 operatorId)
```

Throws NoOperatorFound if the operator address is not found in the registry

_Returns the operator details for a given operator address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The address of the operator to retrieve |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| operator | struct INodeOperatorRegistry.Operator | The operator details, including name, reward address, and enabled status |
| totalValidatorDetails | uint128 | The total amount of validator details for an operator |
| operatorId | uint128 | The operator's Id |

### getOperatorsPendingValidatorDetails

```solidity
function getOperatorsPendingValidatorDetails(address _operatorAddress) external view returns (struct INodeOperatorRegistry.ValidatorDetails[] validatorDetails)
```

Throws NoOperatorFound if the operator address is not found in the registry

_Returns the pending validator details for a given operator address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The address of the operator to retrieve pending validator details for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| validatorDetails | struct INodeOperatorRegistry.ValidatorDetails[] | validatorDetails The pending validator details for the given operator |

### getRewardDetailsForOperatorId

```solidity
function getRewardDetailsForOperatorId(uint128 _operatorId) external view returns (address rewardAddress, uint128 activeValidators)
```

_Returns the reward details for a given operator Id, this method is used in the swETH contract when paying swETH rewards_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorId | uint128 | The operator Id to get the reward details for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| rewardAddress | address | The reward address of the operator |
| activeValidators | uint128 | The amount of active validators for the operator |

### getOperatorsActiveValidatorDetails

```solidity
function getOperatorsActiveValidatorDetails(address _operatorAddress) external view returns (struct INodeOperatorRegistry.ValidatorDetails[] validatorDetails)
```

Throws NoOperatorFound if the operator address is not found in the registry

_Returns the active validator details for a given operator address_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _operatorAddress | address | The address of the operator to retrieve active validator details for |

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| validatorDetails | struct INodeOperatorRegistry.ValidatorDetails[] | The active validator details for the given operator |

## DepositDataRoot

This library helps to format the deposit data root for new validator setup

### _toLittleEndian64

```solidity
function _toLittleEndian64(uint64 value) internal pure returns (bytes ret)
```

_This method converts a uint64 value into a LE bytes array, this is required for compatibility with the beacon deposit contract
Code was taken from: https://github.com/ethereum/consensus-specs/blob/dev/solidity_deposit_contract/deposit_contract.sol#L165_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| value | uint64 | The value to convert to the LE bytes array |

### formatDepositDataRoot

```solidity
function formatDepositDataRoot(bytes _pubKey, bytes _withdrawalCredentials, bytes _signature, uint256 _amount) internal pure returns (bytes32 node)
```

_This method formats the deposit data root for setting up a new validator in the deposit contract. Logic was token from the deposit contract: https://github.com/ethereum/consensus-specs/blob/dev/solidity_deposit_contract/deposit_contract.sol#L128_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| _pubKey | bytes | The pubKey to use in the deposit data root |
| _withdrawalCredentials | bytes | The withdrawal credentials |
| _signature | bytes | The signature |
| _amount | uint256 | The amount, will always be 32 ETH |

## EnumberableSetValidatorDetails

This library enables the usage of an enumerable set of INodeOperatorRegistry.ValidatorDetails. We store an array of INodeOperatorRegistry.ValidatorDetails and a mapping of bytes -> uint256. The mapping uses the public key from the validator details as we only ever index for ValidatorDetails for a given pubKey
Within the array are both the pending and active validator details. From index 0 up to the operator's active validator details count (stored inside the Operator struct) are all the active validator's for an operator. The remaining details are all pending. Validator details are only ever selected sequentially and storing it in this way prevents having to move the data around which is costly
Heavily influenced by: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol

### ValidatorDetailsSet

```solidity
struct ValidatorDetailsSet {
  struct INodeOperatorRegistry.ValidatorDetails[] _values;
  mapping(bytes => uint256) _indexes;
}
```

### range

```solidity
function range(struct EnumberableSetValidatorDetails.ValidatorDetailsSet set, uint256 startIndex, uint256 endIndex) internal view returns (struct INodeOperatorRegistry.ValidatorDetails[] validatorDetails)
```

### add

```solidity
function add(struct EnumberableSetValidatorDetails.ValidatorDetailsSet set, struct INodeOperatorRegistry.ValidatorDetails value) internal returns (bool)
```

_Add a value to a set. O(1).

Returns true if the value was added to the set, that is if it was not
already present._

### contains

```solidity
function contains(struct EnumberableSetValidatorDetails.ValidatorDetailsSet set, bytes pubKey) internal view returns (bool)
```

_Returns true if the value is in the set. O(1)._

### removePendingDetails

```solidity
function removePendingDetails(struct EnumberableSetValidatorDetails.ValidatorDetailsSet set, bytes pubKey, uint128 operatorActiveValidators) internal returns (bool)
```

_This method deletes a given pending pubKey from the set. It also checks whether the pubKey is pending by ensuring that it's index is greater than the active validator details count._

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| set | struct EnumberableSetValidatorDetails.ValidatorDetailsSet | The set to delete the pending details from |
| pubKey | bytes | The pubKey to remove from the pending details |
| operatorActiveValidators | uint128 | The operator's active validator details count |

### removeActiveDetails

```solidity
function removeActiveDetails(struct EnumberableSetValidatorDetails.ValidatorDetailsSet set, bytes pubKey, uint128 operatorActiveValidators) internal returns (bool)
```

_This method deletes a given pubKey from the provided validator details set, but only deletes it if the index of the item is less than the operator's active validators.
Due to the separation in the array of active and pending details, in order to safely handle deleting an active item we must take the last active item, place it where the active item we are deleting is, then get the last pending item and place it where the last active item is. Once we do that we can safely .pop() the last item and have kept the array separation_

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| set | struct EnumberableSetValidatorDetails.ValidatorDetailsSet | An operator's validator details set |
| pubKey | bytes | The pubKey to delete |
| operatorActiveValidators | uint128 | The amount of active validator's for the operator |

### length

```solidity
function length(struct EnumberableSetValidatorDetails.ValidatorDetailsSet set) internal view returns (uint256)
```

_Returns the number of values on the set. O(1)._

### at

```solidity
function at(struct EnumberableSetValidatorDetails.ValidatorDetailsSet set, uint256 index) internal view returns (struct INodeOperatorRegistry.ValidatorDetails)
```

_Returns the value stored at position `index` in the set. O(1).

Note that there are no guarantees on the ordering of values inside the
array, and it may change when more values are added or removed.

Requirements:

- `index` must be strictly less than {length}._

## IDepositContract

This is the Ethereum 2.0 deposit contract interface.

_Implementation can be found here: https://github.com/ethereum/consensus-specs/blob/dev/solidity_deposit_contract/deposit_contract.sol_

### DepositEvent

```solidity
event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index)
```

A processed deposit event.

### deposit

```solidity
function deposit(bytes pubkey, bytes withdrawal_credentials, bytes signature, bytes32 deposit_data_root) external payable
```

Submit a Phase 0 DepositData object.

#### Parameters

| Name | Type | Description |
| ---- | ---- | ----------- |
| pubkey | bytes | A BLS12-381 public key. |
| withdrawal_credentials | bytes | Commitment to a public key for withdrawals. |
| signature | bytes | A BLS12-381 signature. |
| deposit_data_root | bytes32 | The SHA-256 hash of the SSZ-encoded DepositData object, used as a protection against malformed input. |

### get_deposit_root

```solidity
function get_deposit_root() external view returns (bytes32)
```

Query the current deposit root hash.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes32 | The deposit root hash. |

### get_deposit_count

```solidity
function get_deposit_count() external view returns (bytes)
```

Query the current deposit count.

#### Return Values

| Name | Type | Description |
| ---- | ---- | ----------- |
| [0] | bytes | The deposit count encoded as a little endian 64-bit number. |

