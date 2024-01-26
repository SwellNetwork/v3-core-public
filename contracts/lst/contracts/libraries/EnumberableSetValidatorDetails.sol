// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {INodeOperatorRegistry} from "../interfaces/INodeOperatorRegistry.sol";

/**
 * @title EnumberableSetValidatorDetails
 * @author https://github.com/max-taylor
 * @notice This library enables the usage of an enumerable set of INodeOperatorRegistry.ValidatorDetails. We store an array of INodeOperatorRegistry.ValidatorDetails and a mapping of bytes -> uint256. The mapping uses the public key from the validator details as we only ever index for ValidatorDetails for a given pubKey
 * @notice Within the array are both the pending and active validator details. From index 0 up to the operator's active validator details count (stored inside the Operator struct) are all the active validator's for an operator. The remaining details are all pending. Validator details are only ever selected sequentially and storing it in this way prevents having to move the data around which is costly
 * @notice Heavily influenced by: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol
 */
library EnumberableSetValidatorDetails {
  struct ValidatorDetailsSet {
    INodeOperatorRegistry.ValidatorDetails[] _values;
    // Mapping of validator public keys to indexes. Using the public keys inside the mapping as we will never use the signature directly in this way
    mapping(bytes => uint256) _indexes;
  }

  function range(
    ValidatorDetailsSet storage set,
    uint256 startIndex,
    uint256 endIndex
  )
    internal
    view
    returns (INodeOperatorRegistry.ValidatorDetails[] memory validatorDetails)
  {
    uint256 lastValuesIndex = set._values.length - 1;

    if (startIndex > lastValuesIndex) {
      return validatorDetails;
    }

    if (endIndex > lastValuesIndex) {
      endIndex = lastValuesIndex;
    }

    validatorDetails = new INodeOperatorRegistry.ValidatorDetails[](
      // Inclusive of the lastIndex, so add 1
      endIndex - startIndex + 1
    );

    for (uint256 i; i < validatorDetails.length; i++) {
      validatorDetails[i] = set._values[startIndex + i];
    }
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(
    ValidatorDetailsSet storage set,
    INodeOperatorRegistry.ValidatorDetails memory value
  ) internal returns (bool) {
    if (!contains(set, value.pubKey)) {
      set._values.push(value);
      // The value is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      set._indexes[value.pubKey] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(
    ValidatorDetailsSet storage set,
    bytes memory pubKey
  ) internal view returns (bool) {
    return set._indexes[pubKey] != 0;
  }

  /**
   * @dev This method deletes a given pending pubKey from the set. It also checks whether the pubKey is pending by ensuring that it's index is greater than the active validator details count.
   * @param set The set to delete the pending details from
   * @param pubKey The pubKey to remove from the pending details
   * @param operatorActiveValidators The operator's active validator details count
   */
  function removePendingDetails(
    ValidatorDetailsSet storage set,
    bytes memory pubKey,
    uint128 operatorActiveValidators
  ) internal returns (bool) {
    uint256 pubKeyIndex = set._indexes[pubKey];

    if (pubKeyIndex != 0) {
      uint256 toDeleteIndex = pubKeyIndex - 1;

      // If the given index is within the active validators, return false
      if (toDeleteIndex < operatorActiveValidators) {
        return false;
      }

      uint256 lastIndex = set._values.length - 1;

      // Replace the item we are deleting with the last item
      if (lastIndex != toDeleteIndex) {
        INodeOperatorRegistry.ValidatorDetails memory lastValue = set._values[
          lastIndex
        ];

        set._values[toDeleteIndex] = lastValue;
        set._indexes[lastValue.pubKey] = pubKeyIndex;
      }

      // Delete the slot where the moved value was stored
      set._values.pop();

      // Delete the index for the deleted slot
      delete set._indexes[pubKey];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev This method deletes a given pubKey from the provided validator details set, but only deletes it if the index of the item is less than the operator's active validators.
   * @dev Due to the separation in the array of active and pending details, in order to safely handle deleting an active item we must take the last active item, place it where the active item we are deleting is, then get the last pending item and place it where the last active item is. Once we do that we can safely .pop() the last item and have kept the array separation
   * @param set An operator's validator details set
   * @param pubKey The pubKey to delete
   * @param operatorActiveValidators The amount of active validator's for the operator
   */
  function removeActiveDetails(
    ValidatorDetailsSet storage set,
    bytes memory pubKey,
    uint128 operatorActiveValidators
  ) internal returns (bool) {
    uint256 pubKeyIndex = set._indexes[pubKey];

    if (pubKeyIndex != 0 && operatorActiveValidators != 0) {
      uint256 toDeleteIndex = pubKeyIndex - 1;
      uint256 lastActiveValidatorIndex = operatorActiveValidators - 1;
      uint256 lastIndex = set._values.length - 1;

      // If the given index is out of range it means it's pending and cannot be deleted
      if (toDeleteIndex > lastActiveValidatorIndex) {
        return false;
      }

      // If the item isn't the last active validator details for the operator, then we need to replace it with the last active validator details item
      if (toDeleteIndex != lastActiveValidatorIndex) {
        INodeOperatorRegistry.ValidatorDetails memory lastValue = set._values[
          lastActiveValidatorIndex
        ];

        set._values[toDeleteIndex] = lastValue;
        set._indexes[lastValue.pubKey] = toDeleteIndex + 1;
      }

      // If there are still pending validator details, then we need to take the last pending item and put it where the last active validator details was
      if (lastIndex > lastActiveValidatorIndex) {
        INodeOperatorRegistry.ValidatorDetails memory lastValue = set._values[
          lastIndex
        ];

        set._values[lastActiveValidatorIndex] = lastValue;
        set._indexes[lastValue.pubKey] = lastActiveValidatorIndex + 1;
      }

      // Now we can delete the last item in the array
      set._values.pop();

      // Delete the index
      delete set._indexes[pubKey];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function length(
    ValidatorDetailsSet storage set
  ) internal view returns (uint256) {
    return set._values.length;
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(
    ValidatorDetailsSet storage set,
    uint256 index
  ) internal view returns (INodeOperatorRegistry.ValidatorDetails memory) {
    return set._values[index];
  }
}
