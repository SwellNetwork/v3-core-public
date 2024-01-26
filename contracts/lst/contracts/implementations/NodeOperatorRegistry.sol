// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {INodeOperatorRegistry} from "../interfaces/INodeOperatorRegistry.sol";

import {SwellLib} from "../libraries/SwellLib.sol";
import {EnumberableSetValidatorDetails} from "../libraries/EnumberableSetValidatorDetails.sol";

/**
 * @title NodeOperatorRegistry
 * @author https://github.com/max-taylor
 * @notice This contract will hold all the node operators and any associated validator details. This contract will be used when fetching the next validators to setup and allows management of node operators.
 */
contract NodeOperatorRegistry is INodeOperatorRegistry, Initializable {
  using SafeERC20 for IERC20;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;
  using EnumberableSetValidatorDetails for EnumberableSetValidatorDetails.ValidatorDetailsSet;

  IAccessControlManager public AccessControlManager;

  // ** Operators **

  // Incrementing count of node operators
  uint128 public override numOperators;

  // Using a mapping of operatorId's to operators to allow for cheap fetching when we need to iterate over the operators
  mapping(uint128 => Operator) public getOperatorForOperatorId;

  // Returns operatorId for the controlling address
  mapping(address => uint128) public override getOperatorIdForAddress;

  // ** Validator details **

  // Maps the operatorId to their validator details, this set allows for cheap removal from the array when needed. This set contains all the validator details to an operator, the set is divided into active and pending validators based on the activeValidators count stored in the Operator struct. From index 0 -> activeValidators count are active and the remaining are pending.
  mapping(uint128 => EnumberableSetValidatorDetails.ValidatorDetailsSet) operatorIdToValidatorDetails;

  uint256 public override numPendingValidators;

  // The active validator indexes are a bytes32 object containing 2 uint128's. They are encoded together to reduce storage costs. The first uint128 is the operator's ID and the second is the index of the key in their operatorIdToValidatorDetails array
  EnumerableSetUpgradeable.Bytes32Set activeValidatorIndexes;

  // Allows efficient access to an operator Id based on a validator public key
  mapping(bytes => uint128) public override getOperatorIdForPubKey;

  // The avaiable HEX symbols, used in converting the public key in bytes to string
  bytes16 private constant _SYMBOLS = "0123456789abcdef";

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  modifier checkRole(bytes32 role) {
    AccessControlManager.checkRole(role, msg.sender);

    _;
  }

  /**
   * @dev Modifier to check for empty addresses
   * @param _address The address to check
   */
  modifier checkZeroAddress(address _address) {
    SwellLib._checkZeroAddress(_address);

    _;
  }

  fallback() external {
    revert SwellLib.InvalidMethodCall();
  }

  function initialize(
    IAccessControlManager _accessControlManager
  ) external initializer checkZeroAddress(address(_accessControlManager)) {
    AccessControlManager = _accessControlManager;
  }

  // ************************************
  // ***** External methods ******

  function withdrawERC20(
    IERC20 _token
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    uint256 contractBalance = _token.balanceOf(address(this));
    if (contractBalance == 0) {
      revert SwellLib.NoTokensToWithdraw();
    }

    _token.safeTransfer(msg.sender, contractBalance);
  }

  function getNextValidatorDetails(
    uint256 _numNewValidators
  )
    external
    view
    override
    returns (
      ValidatorDetails[] memory validatorDetails,
      uint256 foundValidators
    )
  {
    validatorDetails = new ValidatorDetails[](_numNewValidators);

    // Cache the amount of validator details operators have assigned in this method, this prevents accidentally only assigning from the operator with the least active validators
    uint128[] memory operatorAssignedDetails = new uint128[](numOperators + 1);

    uint128 smallestOperatorActiveKeys;

    for (
      foundValidators;
      foundValidators < _numNewValidators;
      foundValidators++
    ) {
      uint128 foundOperatorId;

      // Iterate over each operator and find the operator with the least amount of active keys, starting from the first operator
      for (uint128 operatorId = 1; operatorId <= numOperators; operatorId++) {
        // If the operator is disabled, skip
        if (!getOperatorForOperatorId[operatorId].enabled) {
          continue;
        }

        // The operator's active keys is the amount of active validator details + the validator details the operator has assigned in this method
        uint128 operatorActiveKeys = getOperatorForOperatorId[operatorId]
          .activeValidators + operatorAssignedDetails[operatorId];

        if (
          operatorIdToValidatorDetails[operatorId].length() ==
          operatorActiveKeys
        ) {
          continue;
        }

        // Early find if the given operator has no active keys and hasn't had validator details selected yet
        if (
          operatorActiveKeys == 0 && operatorAssignedDetails[operatorId] == 0
        ) {
          foundOperatorId = operatorId;

          smallestOperatorActiveKeys = 0;

          break;
        } else if (foundOperatorId == 0) {
          // If no operator has been found yet set the smallest operator active keys to the current operator
          smallestOperatorActiveKeys = operatorActiveKeys;

          foundOperatorId = operatorId;

          // If the current operator has less keys than the smallest operator active keys, then we want to use this operator
        } else if (smallestOperatorActiveKeys > operatorActiveKeys) {
          smallestOperatorActiveKeys = operatorActiveKeys;

          foundOperatorId = operatorId;
        }
      }

      // If an operator was found in the loop
      if (foundOperatorId != 0) {
        // If there was an operator found, get an un-assigned public key and add it to the return array
        validatorDetails[foundValidators] = operatorIdToValidatorDetails[
          foundOperatorId
        ].at(smallestOperatorActiveKeys);

        operatorAssignedDetails[foundOperatorId] += 1;

        foundOperatorId = 0;
      } else {
        // If no eligible operator's are found exit the loop and return what exists of the array
        break;
      }
    }
  }

  function usePubKeysForValidatorSetup(
    bytes[] calldata _pubKeys
  ) external override returns (ValidatorDetails[] memory validatorDetails) {
    if (msg.sender != address(AccessControlManager.DepositManager())) {
      revert InvalidPubKeySetupCaller();
    }

    validatorDetails = new ValidatorDetails[](_pubKeys.length);

    for (uint256 i; i < _pubKeys.length; i++) {
      uint128 operatorId = _getOperatorIdForPubKeySafe(_pubKeys[i]);

      if (!getOperatorForOperatorId[operatorId].enabled) {
        revert CannotUseDisabledOperator();
      }

      uint128 nextKeyIndex = getOperatorForOperatorId[operatorId]
        .activeValidators;

      if (nextKeyIndex == operatorIdToValidatorDetails[operatorId].length()) {
        revert OperatorOutOfPendingKeys();
      }

      ValidatorDetails
        memory deletedValidatorDetails = operatorIdToValidatorDetails[
          operatorId
        ].at(nextKeyIndex);

      if (keccak256(deletedValidatorDetails.pubKey) != keccak256(_pubKeys[i])) {
        revert NextOperatorPubKeyMismatch(
          deletedValidatorDetails.pubKey,
          _pubKeys[i]
        );
      }

      getOperatorForOperatorId[operatorId].activeValidators += 1;

      validatorDetails[i] = deletedValidatorDetails;

      // Encode the operatorId and the key together so we can just store the single value
      bytes32 encoded = _encodeOperatorIdAndKeyIndex(operatorId, nextKeyIndex);

      activeValidatorIndexes.add(encoded);
    }

    numPendingValidators -= _pubKeys.length;

    emit PubKeysUsedForValidatorSetup(_pubKeys);

    return validatorDetails;
  }

  // ** Operator management methods **

  function addNewValidatorDetails(
    ValidatorDetails[] calldata _validatorDetails
  ) external override {
    if (AccessControlManager.operatorMethodsPaused()) {
      revert SwellLib.OperatorMethodsPaused();
    }

    if (_validatorDetails.length == 0) {
      revert InvalidArrayLengthOfZero();
    }

    uint128 operatorId = _getOperatorIdSafe(msg.sender);

    if (!getOperatorForOperatorId[operatorId].enabled) {
      revert CannotUseDisabledOperator();
    }

    // Enforcing the limit on validator details to uint128 here
    // ! I was unable to figure out a way to test this condition, javascript cannot handle an array this size and the array size it can handle requires that the method be called 1000s of times
    if (
      operatorIdToValidatorDetails[operatorId].length() +
        _validatorDetails.length >
      type(uint128).max
    ) {
      revert AmountOfValidatorDetailsExceedsLimit();
    }

    for (uint128 i; i < _validatorDetails.length; i++) {
      // NOTE that no signature verification is conducted when validator details are added, this will instead be done via an off-chain service when new validators are getting setup
      if (_validatorDetails[i].pubKey.length != 48) {
        revert InvalidPubKeyLength();
      }

      if (_validatorDetails[i].signature.length != 96) {
        revert InvalidSignatureLength();
      }

      if (getOperatorIdForPubKey[_validatorDetails[i].pubKey] != 0) {
        revert CannotAddDuplicatePubKey(_validatorDetails[i].pubKey);
      }

      operatorIdToValidatorDetails[operatorId].add(_validatorDetails[i]);

      getOperatorIdForPubKey[_validatorDetails[i].pubKey] = operatorId;
    }

    numPendingValidators += _validatorDetails.length;

    emit OperatorAddedValidatorDetails(msg.sender, _validatorDetails);
  }

  // ** PLATFORM_ADMIN management methods **

  function addOperator(
    string calldata _name,
    address _operatorAddress,
    address _rewardAddress
  )
    external
    override
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_operatorAddress)
    checkZeroAddress(_rewardAddress)
  {
    if (getOperatorIdForAddress[_operatorAddress] != 0) {
      revert OperatorAlreadyExists(_operatorAddress);
    }

    // Increment numOperators before the assignment, so that the operatorIds start from 1
    numOperators += 1;

    Operator memory operator;

    operator.name = _name;
    operator.enabled = true;
    operator.rewardAddress = _rewardAddress;
    operator.controllingAddress = _operatorAddress;

    getOperatorIdForAddress[_operatorAddress] = numOperators;
    getOperatorForOperatorId[numOperators] = operator;

    emit OperatorAdded(_operatorAddress, _rewardAddress);
  }

  function enableOperator(
    address _operatorAddress
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    Operator storage operator = _getOperatorSafe(_operatorAddress);

    if (operator.enabled) {
      revert OperatorAlreadyEnabled();
    }

    operator.enabled = true;

    emit OperatorEnabled(_operatorAddress);
  }

  function disableOperator(
    address _operatorAddress
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    Operator storage operator = _getOperatorSafe(_operatorAddress);

    if (!operator.enabled) {
      revert OperatorAlreadyDisabled();
    }

    operator.enabled = false;

    emit OperatorDisabled(_operatorAddress);
  }

  function updateOperatorControllingAddress(
    address _operatorAddress,
    address _newOperatorAddress
  )
    external
    override
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_newOperatorAddress)
  {
    uint128 operatorId = _getOperatorIdSafe(_operatorAddress);

    getOperatorIdForAddress[_newOperatorAddress] = operatorId;
    getOperatorForOperatorId[operatorId]
      .controllingAddress = _newOperatorAddress;

    delete getOperatorIdForAddress[_operatorAddress];
  }

  function updateOperatorRewardAddress(
    address _operatorAddress,
    address _newRewardAddress
  )
    external
    override
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_newRewardAddress)
  {
    Operator storage operator = _getOperatorSafe(_operatorAddress);

    operator.rewardAddress = _newRewardAddress;
  }

  function updateOperatorName(
    address _operatorAddress,
    string calldata _name
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    Operator storage operator = _getOperatorSafe(_operatorAddress);

    operator.name = _name;
  }

  function deletePendingValidators(
    bytes[] calldata _pubKeys
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    for (uint128 i; i < _pubKeys.length; i++) {
      uint128 operatorId = _getOperatorIdForPubKeySafe(_pubKeys[i]);

      uint128 operatorActiveValidators = getOperatorForOperatorId[operatorId]
        .activeValidators;

      bool removed = operatorIdToValidatorDetails[operatorId]
        .removePendingDetails(_pubKeys[i], operatorActiveValidators);

      if (!removed) {
        revert MissingPendingValidatorDetails(_pubKeys[i]);
      }

      delete getOperatorIdForPubKey[_pubKeys[i]];
    }

    numPendingValidators -= _pubKeys.length;

    emit PendingPubKeysDeleted(_pubKeys);
  }

  function deleteActiveValidators(
    bytes[] calldata _pubKeys
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    for (uint256 i; i < _pubKeys.length; i++) {
      uint128 operatorId = _getOperatorIdForPubKeySafe(_pubKeys[i]);

      uint128 operatorActiveValidators = getOperatorForOperatorId[operatorId]
        .activeValidators;

      if (operatorActiveValidators == 0) {
        revert MissingActiveValidatorDetails(_pubKeys[i]);
      }

      // Recreate the encoded value so it can be deleted, for this we use the last active validator index they have
      bytes32 encodedValue = _encodeOperatorIdAndKeyIndex(
        operatorId,
        operatorActiveValidators - 1
      );

      bool activeValidatorIndexRemoved = activeValidatorIndexes.remove(
        encodedValue
      );

      bool operatorIdRemoved = operatorIdToValidatorDetails[operatorId]
        .removeActiveDetails(_pubKeys[i], operatorActiveValidators);

      if (!operatorIdRemoved || !activeValidatorIndexRemoved) {
        revert MissingActiveValidatorDetails(_pubKeys[i]);
      }

      getOperatorForOperatorId[operatorId].activeValidators -= 1;

      delete getOperatorIdForPubKey[_pubKeys[i]];
    }

    emit ActivePubKeysDeleted(_pubKeys);
  }

  // ***** PoR Methods *****

  function getPoRAddressListLength() external view override returns (uint256) {
    return activeValidatorIndexes.length();
  }

  /**
   * @dev This method parses a pure bytes array into it's string equivalent. We must loop through the pubKey to safely convert each byte into its string equivalent, if we cast it directly it causes the response to be corrupted
   * @param pubKey The pubKey to parse
   * @return The string equivalent
   */
  function _parsePubKeyToString(
    bytes memory pubKey
  ) internal pure returns (string memory) {
    // Create the bytes that will hold the converted string
    bytes memory buffer = new bytes(pubKey.length * 2);

    bytes16 symbols = _SYMBOLS;

    // This conversion relies on taking the uint8 value of each byte, the first character in the byte is the uint8 value divided by 16 and the second character is modulo of the 16 division
    for (uint256 i; i < pubKey.length; i++) {
      buffer[i * 2] = symbols[uint8(pubKey[i]) / symbols.length];
      buffer[i * 2 + 1] = symbols[uint8(pubKey[i]) % symbols.length];
    }

    return string(abi.encodePacked("0x", buffer));
  }

  function getPoRAddressList(
    uint256 _startIndex,
    uint256 _endIndex
  ) external view override returns (string[] memory) {
    uint256 activeValidatorLength = activeValidatorIndexes.length();

    if (_endIndex < _startIndex || activeValidatorLength == 0) {
      return new string[](0);
    }

    uint256 activeValidatorsEndIndex = activeValidatorLength - 1;

    // If specifying a startIndex that is greater than the length, return an empty array as no items exist at this index
    if (_startIndex > activeValidatorsEndIndex) {
      return new string[](0);
    }

    // If the _endIndex is out of range, update it
    if (_endIndex > activeValidatorsEndIndex) {
      _endIndex = activeValidatorsEndIndex;
    }

    // Amount of addresses equal to the end - the start, adding 1 as we are inclusive of the item at the _endIndex
    uint256 numAddresses = _endIndex - _startIndex + 1;

    string[] memory addresses = new string[](numAddresses);

    for (uint256 i; i < numAddresses; i++) {
      uint256 values = uint256(activeValidatorIndexes.at(i + _startIndex));

      // Split the response to get the operatorId and keyIndex values
      uint128 operatorId = uint128(values >> 128);
      uint128 keyIndex = uint128(values);

      bytes memory pubKey = operatorIdToValidatorDetails[operatorId]
        .at(keyIndex)
        .pubKey;

      addresses[i] = _parsePubKeyToString(pubKey);
    }

    return addresses;
  }

  // ************************************
  // ***** Internal helpers *****

  /**
   * @dev This method safely returns an Operator struct from the provided _operatorAddress.
   * @notice Throws if an operator cannot be found for the provided address.
   * @param _operatorAddress The controlling address of the given operator
   * @return operator The Operator struct
   */
  function _getOperatorSafe(
    address _operatorAddress
  ) internal view returns (Operator storage operator) {
    uint128 operatorId = _getOperatorIdSafe(_operatorAddress);

    operator = getOperatorForOperatorId[operatorId];
  }

  /**
   * @dev This method safely returns the operatorId of the given _operatorAddress
   * @notice Throws an error if the given _operatorAddress doesn't exist
   * @param _operatorAddress The controlling address of the given operator
   * @return operatorId The operator's ID
   */
  function _getOperatorIdSafe(
    address _operatorAddress
  ) internal view returns (uint128 operatorId) {
    operatorId = getOperatorIdForAddress[_operatorAddress];

    // The core reasoning behind adding +1 to operatorId's
    if (operatorId == 0) {
      revert NoOperatorFound(_operatorAddress);
    }
  }

  /**
   * @dev This method safely returns the operatorId of the given _pubKey
   * @notice Throws if there is no found operatorId for the given _pubKey
   * @param _pubKey The public key to find an operator with
   * @return operatorId The operator ID that controls the given pubKey
   */
  function _getOperatorIdForPubKeySafe(
    bytes calldata _pubKey
  ) internal view returns (uint128 operatorId) {
    operatorId = getOperatorIdForPubKey[_pubKey];

    if (operatorId == 0) {
      revert NoPubKeyFound(_pubKey);
    }
  }

  /**
   * @dev This method encodes the provided operatorId and nextKey into a single bytes32 variable. This is used in the activeValidatorIndexes array
   * @param operatorId The operator id to encode
   * @param nextKey The key index to encode
   * @return The encoded bytes32 variable
   */
  function _encodeOperatorIdAndKeyIndex(
    uint128 operatorId,
    uint128 nextKey
  ) internal pure returns (bytes32) {
    return bytes32((uint256(operatorId) << 128) | (nextKey));
  }

  // ************************************
  // ***** External view methods *****

  function getOperator(
    address _operatorAddress
  )
    external
    view
    override
    returns (
      Operator memory operator,
      uint128 totalValidatorDetails,
      uint128 operatorId
    )
  {
    operatorId = _getOperatorIdSafe(_operatorAddress);
    operator = getOperatorForOperatorId[operatorId];
    // Safe downcast as the limit is enforced in the addNewValidatorDetails method
    totalValidatorDetails = uint128(
      operatorIdToValidatorDetails[operatorId].length()
    );
  }

  function getOperatorsPendingValidatorDetails(
    address _operatorAddress
  )
    external
    view
    override
    returns (ValidatorDetails[] memory validatorDetails)
  {
    uint128 operatorId = _getOperatorIdSafe(_operatorAddress);

    if (operatorIdToValidatorDetails[operatorId].length() == 0) {
      return validatorDetails;
    }

    validatorDetails = operatorIdToValidatorDetails[operatorId].range(
      getOperatorForOperatorId[operatorId].activeValidators,
      operatorIdToValidatorDetails[operatorId].length() - 1
    );
  }

  function getRewardDetailsForOperatorId(
    uint128 _operatorId
  )
    external
    view
    override
    returns (address rewardAddress, uint128 activeValidators)
  {
    activeValidators = getOperatorForOperatorId[_operatorId].activeValidators;
    rewardAddress = getOperatorForOperatorId[_operatorId].rewardAddress;
  }

  function getOperatorsActiveValidatorDetails(
    address _operatorAddress
  )
    external
    view
    override
    returns (ValidatorDetails[] memory validatorDetails)
  {
    uint128 operatorId = _getOperatorIdSafe(_operatorAddress);

    if (getOperatorForOperatorId[operatorId].activeValidators == 0) {
      return validatorDetails;
    }

    validatorDetails = operatorIdToValidatorDetails[operatorId].range(
      0,
      getOperatorForOperatorId[operatorId].activeValidators - 1
    );
  }
}
