// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";

import {SwellLib} from "../libraries/SwellLib.sol";

/**
  @title Whitelist
  @author https://github.com/max-taylor 
  @dev Contract to manage a whitelist, used in the swETH contract to handle allowed depositors
*/
contract Whitelist is Initializable, IWhitelist {
  IAccessControlManager public AccessControlManager;

  mapping(address => bool) public override whitelistedAddresses;

  bool public override whitelistEnabled;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /**
   * @dev Modifier to check for empty addresses
   * @param _address The address to check
   */
  modifier checkZeroAddress(address _address) {
    SwellLib._checkZeroAddress(_address);

    _;
  }

  /**
   * Helper to check the sender against the given role
   * @param role The role to check for the msg.sender
   */
  modifier checkRole(bytes32 role) {
    AccessControlManager.checkRole(role, msg.sender);

    _;
  }

  /**
   * @dev Method checks if the whitelist is enabled and also whether the address is in the whitelist, reverting if true.
   * @param _address The address to check in the whitelist
   */
  modifier checkWhitelist(address _address) {
    if (whitelistEnabled && !whitelistedAddresses[_address]) {
      revert NotInWhitelist();
    }

    _;
  }

  /**
   * @dev This contract is intended to be inherited from a parent contract, so using an onlyInitializing modifier to allow that.
   * @param _accessControlManager The access control manager to use for role management
   */
  function __Whitelist_init(
    IAccessControlManager _accessControlManager
  ) internal onlyInitializing checkZeroAddress(address(_accessControlManager)) {
    AccessControlManager = _accessControlManager;

    whitelistEnabled = true;
  }

  // ************************************
  // ***** External methods ******

  function addToWhitelist(
    address _address
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    _checkAndAddToWhitelist(_address);
  }

  function batchAddToWhitelist(
    address[] calldata _addresses
  ) external checkRole(SwellLib.PLATFORM_ADMIN) {
    for (uint256 i; i < _addresses.length; ) {
      _checkAndAddToWhitelist(_addresses[i]);

      unchecked {
        ++i;
      }
    }
  }

  function removeFromWhitelist(
    address _address
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    _checkAndRemoveFromWhitelist(_address);
  }

  function batchRemoveFromWhitelist(
    address[] calldata _addresses
  ) external checkRole(SwellLib.PLATFORM_ADMIN) {
    for (uint256 i; i < _addresses.length; ) {
      _checkAndRemoveFromWhitelist(_addresses[i]);

      unchecked {
        ++i;
      }
    }
  }

  function enableWhitelist()
    external
    override
    checkRole(SwellLib.PLATFORM_ADMIN)
  {
    if (whitelistEnabled) {
      revert WhitelistAlreadyEnabled();
    }

    whitelistEnabled = true;

    emit WhitelistEnabled();
  }

  function disableWhitelist()
    external
    override
    checkRole(SwellLib.PLATFORM_ADMIN)
  {
    if (!whitelistEnabled) {
      revert WhitelistAlreadyDisabled();
    }

    whitelistEnabled = false;

    emit WhitelistDisabled();
  }

  // ************************************
  // ***** Internal methods ******

  /**
   * @dev This method checks if the given address is the zero address or is in the whitelist already, reverting if true; otherwise the address is added and an event is emitted
   * @param _address The address to check and add to the whitelist
   */
  function _checkAndAddToWhitelist(address _address) internal {
    SwellLib._checkZeroAddress(_address);

    if (whitelistedAddresses[_address]) {
      revert AddressAlreadyInWhitelist(_address);
    }

    whitelistedAddresses[_address] = true;

    emit AddedToWhitelist(_address);
  }

  /**
   * @dev This method checks if the address doesn't exist within the whitelist and reverts if true, otherwise the address is removed from the whitelist and an event is emitted
   * @param _address The address to check and remove from the whitelist
   */
  function _checkAndRemoveFromWhitelist(address _address) internal {
    if (!whitelistedAddresses[_address]) {
      revert AddressMissingFromWhitelist(_address);
    }

    whitelistedAddresses[_address] = false;

    emit RemovedFromWhitelist(_address);
  }

  /**
   * @dev Gap for upgrades
   */
  uint256[45] private __gap;
}
