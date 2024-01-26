// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {BytesLib} from "solidity-bytes-utils/contracts/BytesLib.sol";

/**
 * @title DepositDataRoot
 * @author https://github.com/max-taylor
 * @notice This library helps to format the deposit data root for new validator setup
 */
library DepositDataRoot {
  using BytesLib for bytes;

  /**
   * @dev This method converts a uint64 value into a LE bytes array, this is required for compatibility with the beacon deposit contract
   * @dev Code was taken from: https://github.com/ethereum/consensus-specs/blob/dev/solidity_deposit_contract/deposit_contract.sol#L165
   * @param value The value to convert to the LE bytes array
   */
  function _toLittleEndian64(
    uint64 value
  ) internal pure returns (bytes memory ret) {
    ret = new bytes(8);
    bytes8 bytesValue = bytes8(value);

    // Byte swap each item so it's LE not BE
    ret[0] = bytesValue[7];
    ret[1] = bytesValue[6];
    ret[2] = bytesValue[5];
    ret[3] = bytesValue[4];
    ret[4] = bytesValue[3];
    ret[5] = bytesValue[2];
    ret[6] = bytesValue[1];
    ret[7] = bytesValue[0];
  }

  /**
   * @dev This method formats the deposit data root for setting up a new validator in the deposit contract. Logic was token from the deposit contract: https://github.com/ethereum/consensus-specs/blob/dev/solidity_deposit_contract/deposit_contract.sol#L128
   * @param _pubKey The pubKey to use in the deposit data root
   * @param _withdrawalCredentials The withdrawal credentials
   * @param _signature The signature
   * @param _amount The amount, will always be 32 ETH
   */
  function formatDepositDataRoot(
    bytes memory _pubKey,
    bytes memory _withdrawalCredentials,
    bytes memory _signature,
    uint256 _amount
  ) internal pure returns (bytes32 node) {
    uint256 deposit_amount = _amount / 1 gwei;

    bytes memory amount = _toLittleEndian64(uint64(deposit_amount));

    bytes32 pubKeyRoot = sha256(abi.encodePacked(_pubKey, bytes16(0)));

    bytes32 signature_root = sha256(
      abi.encodePacked(
        sha256(abi.encodePacked(_signature.slice(0, 64))),
        sha256(abi.encodePacked(_signature.slice(64, 32), bytes32(0)))
      )
    );

    node = sha256(
      abi.encodePacked(
        sha256(abi.encodePacked(pubKeyRoot, _withdrawalCredentials)),
        sha256(abi.encodePacked(amount, bytes24(0), signature_root))
      )
    );
  }
}
