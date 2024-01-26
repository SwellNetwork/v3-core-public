// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";

import {IPoRAddresses} from "../vendors/IPoRAddresses.sol";

/**
 * @title INodeOperatorRegistry
 * @author https://github.com/max-taylor
 * @notice Interface for the Node Operator Registry contract.
 */
interface INodeOperatorRegistry is IPoRAddresses {
  /**
   * @dev  Struct containing the required details to setup a validator on the beacon chain
   * @param pubKey Public key of the validator
   * @param signature The signature of the validator
   */
  struct ValidatorDetails {
    bytes pubKey;
    bytes signature;
  }

  /**
   * @dev  Struct containing operator details
   * @param enabled Flag indicating if the operator is enabled or disabled
   * @param rewardAddress Address to sending repricing rewards to
   * @param controllingAddress The address that can control the operator account
   * @param name The name of the operator
   * @param activeValidators The amount of active validators for the operator
   */
  struct Operator {
    bool enabled;
    address rewardAddress;
    address controllingAddress;
    string name;
    uint128 activeValidators;
  }

  // ***** Events *****
  /**
   * @dev  Emitted when a new operator is added.
   * @param operatorAddress  The address of the newly added operator.
   * @param rewardAddress    The address associated with the reward for the operator.
   */
  event OperatorAdded(address operatorAddress, address rewardAddress);

  /**
   * @dev  Emitted when an operator is enabled.
   * @param operator  The address of the operator that was enabled.
   */
  event OperatorEnabled(address indexed operator);

  /**
   * @dev  Emitted when an operator is disabled.
   * @param operator  The address of the operator that was disabled.
   */
  event OperatorDisabled(address indexed operator);

  /**
   * @dev  Emitted when the validator details for an operator are added.
   * @param operator  The address of the operator for which the validator details were added.
   * @param pubKeys   An array of `ValidatorDetails` for the operator.
   */
  event OperatorAddedValidatorDetails(
    address indexed operator,
    ValidatorDetails[] pubKeys
  );

  /**
   * @dev  Emitted when active public keys are deleted.
   * @param pubKeys  An array of public keys that were deleted.
   */
  event ActivePubKeysDeleted(bytes[] pubKeys);

  /**
   * @dev  Emitted when pending public keys are deleted.
   * @param pubKeys  An array of public keys that were deleted.
   */
  event PendingPubKeysDeleted(bytes[] pubKeys);

  /**
   * @dev  Emitted when public keys are used for validator setup.
   * @param pubKeys  An array of public keys that were used for validator setup.
   */
  event PubKeysUsedForValidatorSetup(bytes[] pubKeys);

  // ***** Errors *****
  /**
   * @dev Thrown when an operator is not found.
   * @param operator  The address of the operator that was not found.
   */
  error NoOperatorFound(address operator);

  /**
   * @dev Thrown when an operator already exists.
   * @param operator The address of the operator that already exists.
   */
  error OperatorAlreadyExists(address operator);

  /**
   * @dev Thrown when an operator is already enabled.
   */
  error OperatorAlreadyEnabled();

  /**
   * @dev Thrown when an operator is already disabled.
   */
  error OperatorAlreadyDisabled();

  /**
   * @dev Thrown when an array length of zero is invalid.
   */
  error InvalidArrayLengthOfZero();

  /**
   * @dev Thrown when an operator is adding new validator details and this causes the total amount of operator's validator details to exceed uint128
   */
  error AmountOfValidatorDetailsExceedsLimit();

  /**
   * @dev Thrown during setup of new validators, when comparing the next operator's public key to the provided public key they should match. This ensures consistency in the tracking of the active and pending validator details.
   * @param foundPubKey The operator's next available public key
   * @param providedPubKey The public key that was passed in as an argument
   */
  error NextOperatorPubKeyMismatch(bytes foundPubKey, bytes providedPubKey);

  /**
   * @dev Thrown during the setup of new validators and when the operator that has no pending details left to use
   */
  error OperatorOutOfPendingKeys();

  /**
   * @dev Thrown when the given pubKey hasn't been added to the registry and cannot be found
   * @param pubKey  The public key that was not found.
   */
  error NoPubKeyFound(bytes pubKey);

  /**
   * @dev Thrown when an operator tries to use the node operator registry whilst they are disabled
   */
  error CannotUseDisabledOperator();

  /**
   * @dev Thrown when a duplicate public key is added.
   * @param existingKey  The public key that already exists.
   */
  error CannotAddDuplicatePubKey(bytes existingKey);

  /**
   * @dev Thrown when the given pubKey doesn't exist in the pending validator details sets
   * @param pubKey  The missing pubKey
   */
  error MissingPendingValidatorDetails(bytes pubKey);

  /**
   * @dev Thrown when the pubKey doesn't exist in the active validator details set
   * @param pubKey  The missing pubKey
   */
  error MissingActiveValidatorDetails(bytes pubKey);

  /**
   * @dev Throw when the msg.sender isn't the Deposit Manager contract
   */
  error InvalidPubKeySetupCaller();

  /**
   * @dev Thrown when an operator is trying to add validator details and a provided pubKey isn't the correct length
   */
  error InvalidPubKeyLength();

  /**
   * @dev Thrown when an operator is trying to add validator details and a provided signature isn't the correct length
   */
  error InvalidSignatureLength();

  // ************************************
  // ***** External  methods ******

  /**
   * @dev This method withdraws contract's _token balance to a platform admin
   * @param _token The ERC20 token to withdraw from the contract
   */
  function withdrawERC20(IERC20 _token) external;

  /**
   * @dev  Gets the next available validator details, ordered by operators with the least amount of active validators. There may be less available validators then the provided _numNewValidators amount, in that case the function will return an array of length equal to _numNewValidators but all indexes after the second return value; foundValidators, will be 0x0 values
   * @param _numNewValidators The number of new validators to get details for.
   * @return An array of ValidatorDetails and the length of the array of non-zero validator details
   * @notice This method tries to return enough validator details to equal the provided _numNewValidators, but if there aren't enough validator details to find, it will simply return what it found, and the caller will need to check for empty values.
   */
  function getNextValidatorDetails(
    uint256 _numNewValidators
  ) external view returns (ValidatorDetails[] memory, uint256 foundValidators);

  /**
   * @dev  Allows the DepositManager to move provided _pubKeys from the pending validator details arrays into the active validator details array. It also returns the validator details, so that the DepositManager can pass the signature along to the ETH2 deposit contract.
   * @param _pubKeys Array of public keys to use for validator setup.
   * @return validatorDetails The associated validator details for the given public keys
   * @notice This method will be called when the DepositManager is setting up new validators.
   */
  function usePubKeysForValidatorSetup(
    bytes[] calldata _pubKeys
  ) external returns (ValidatorDetails[] memory validatorDetails);

  // ** Operator management methods **

  /**
   * @dev  Adds new validator details to the registry.
  /**
   * @dev  Callable by node operator's to add their validator details to the setup queue
   * @param _validatorDetails Array of ValidatorDetails to add.
  */
  function addNewValidatorDetails(
    ValidatorDetails[] calldata _validatorDetails
  ) external;

  // ** PLATFORM_ADMIN management methods **

  /**
   * @dev  Adds a new operator to the registry.
   * @param _name Name of the operator.
   * @param _operatorAddress Address of the operator.
   * @param _rewardAddress Address of the reward recipient for this operator.
   * @notice Throws if an operator already exists with the given _operatorAddress
   */
  function addOperator(
    string calldata _name,
    address _operatorAddress,
    address _rewardAddress
  ) external;

  /**
   * @dev  Enables an operator in the registry.
   * @param _operatorAddress Address of the operator to enable.
   * @notice Throws NoOperatorFound if the operator address is not found in the registry
   */
  function enableOperator(address _operatorAddress) external;

  /**
   * @dev  Disables an operator in the registry.
   * @param _operatorAddress Address of the operator to disable.
   * @notice Throws NoOperatorFound if the operator address is not found in the registry
   */
  function disableOperator(address _operatorAddress) external;

  /**
   * @dev  Updates the controlling address of an operator in the registry.
   * @param _operatorAddress Current address of the operator.
   * @param _newOperatorAddress New address of the operator.
   * @notice Throws NoOperatorFound if the operator address is not found in the registry
   */
  function updateOperatorControllingAddress(
    address _operatorAddress,
    address _newOperatorAddress
  ) external;

  /**
   * @dev  Updates the reward address of an operator in the registry.
   * @param _operatorAddress Address of the operator to update.
   * @param _newRewardAddress New reward address for the operator.
   * @notice Throws NoOperatorFound if the operator address is not found in the registry
   */
  function updateOperatorRewardAddress(
    address _operatorAddress,
    address _newRewardAddress
  ) external;

  /**
   * @dev  Updates the name of an operator in the registry
   * @param _operatorAddress The address of the operator to update
   * @param _name The new name for the operator
   * @notice Throws NoOperatorFound if the operator address is not found in the registry
   */
  function updateOperatorName(
    address _operatorAddress,
    string calldata _name
  ) external;

  /**
   * @dev  Allows the PLATFORM_ADMIN to delete validators that are pending. This is likely to be called via an admin if a public key fails the front-running checks
   * @notice Throws InvalidArrayLengthOfZero if the length of _pubKeys is 0
   * @notice Throws NoPubKeyFound if any of the provided pubKeys is not found in the pending validators set
   * @param _pubKeys The public keys of the pending validators to delete
   */
  function deletePendingValidators(bytes[] calldata _pubKeys) external;

  /**
   * @dev  Allows the PLATFORM_ADMIN to delete validator public keys that have been used to setup a validator and that validator has now exited
   * @notice Throws NoPubKeyFound if any of the provided pubKeys is not found in the active validators set
   * @notice Throws InvalidArrayLengthOfZero if the length of _pubKeys is 0
   * @param _pubKeys The public keys of the active validators to delete
   */
  function deleteActiveValidators(bytes[] calldata _pubKeys) external;

  /**
   * @dev  Returns the address of the AccessControlManager contract
   */
  function AccessControlManager() external returns (IAccessControlManager);

  /**
   * @dev  Returns the operator details for a given operator address
   * @notice Throws NoOperatorFound if the operator address is not found in the registry
   * @param _operatorAddress The address of the operator to retrieve
   * @return operator The operator details, including name, reward address, and enabled status
   * @return totalValidatorDetails The total amount of validator details for an operator
   * @return operatorId The operator's Id
   */
  function getOperator(
    address _operatorAddress
  )
    external
    view
    returns (
      Operator memory operator,
      uint128 totalValidatorDetails,
      uint128 operatorId
    );

  /**
   * @dev  Returns the pending validator details for a given operator address
   * @notice Throws NoOperatorFound if the operator address is not found in the registry
   * @param _operatorAddress The address of the operator to retrieve pending validator details for
   * @return validatorDetails The pending validator details for the given operator
   */
  function getOperatorsPendingValidatorDetails(
    address _operatorAddress
  ) external returns (ValidatorDetails[] memory);

  /**
   * @dev  Returns the active validator details for a given operator address
   * @notice Throws NoOperatorFound if the operator address is not found in the registry
   * @param _operatorAddress The address of the operator to retrieve active validator details for
   * @return validatorDetails The active validator details for the given operator
   */
  function getOperatorsActiveValidatorDetails(
    address _operatorAddress
  ) external returns (ValidatorDetails[] memory validatorDetails);

  /**
   * @dev  Returns the reward details for a given operator Id, this method is used in the swETH contract when paying swETH rewards
   * @param _operatorId The operator Id to get the reward details for
   * @return rewardAddress The reward address of the operator
   * @return activeValidators The amount of active validators for the operator
   */
  function getRewardDetailsForOperatorId(
    uint128 _operatorId
  ) external returns (address rewardAddress, uint128 activeValidators);

  /**
   * @dev  Returns the number of operators in the registry
   */
  function numOperators() external returns (uint128);

  /**
   * @dev  Returns the amount of pending validator keys in the registry
   */
  function numPendingValidators() external returns (uint256);

  /**
   * @dev  Returns the operator ID for a given operator address
   * @notice Throws NoOperatorFound if the operator address is not found in the registry
   * @param _operator The address of the operator to retrieve the operator ID for
   * @return _operatorId The operator ID for the given operator
   */
  function getOperatorIdForAddress(
    address _operator
  ) external returns (uint128 _operatorId);

  /**
   * @dev Returns the `operatorId` associated with the given `pubKey`.
   * @param pubKey  The public key to lookup the `operatorId` for.
   * @notice Returns 0 if no operatorId controls the pubKey
   */
  function getOperatorIdForPubKey(
    bytes calldata pubKey
  ) external returns (uint128);
}
