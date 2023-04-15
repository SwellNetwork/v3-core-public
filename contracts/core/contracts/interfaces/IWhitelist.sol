// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/**
 * @title IWhitelist
 * @author https://github.com/max-taylor
 * @dev Interface for managing a whitelist of addresses.
 */
interface IWhitelist {
  // ***** Events ******
  /**
   * @dev Emitted when an address is added to the whitelist.
   * @param _address The address that was added to the whitelist.
   */
  event AddedToWhitelist(address indexed _address);

  /**
   * @dev Emitted when an address is removed from the whitelist.
   * @param _address The address that was removed from the whitelist.
   */
  event RemovedFromWhitelist(address indexed _address);

  /**
   * @dev Emitted when the whitelist is enabled.
   */
  event WhitelistEnabled();

  /**
   * @dev Emitted when the whitelist is disabled.
   */
  event WhitelistDisabled();

  // ***** Errors ******
  /**
   * @dev Throws an error indicating that the address is already in the whitelist.
   * @param _address The address that already exists in the whitelist.
   */
  error AddressAlreadyInWhitelist(address _address);

  /**
   * @dev Throws an error indicating that the address is missing from the whitelist.
   * @param _address The address that is missing from the whitelist.
   */
  error AddressMissingFromWhitelist(address _address);

  /**
   * @dev Throws an error indicating that the whitelist is already enabled.
   */
  error WhitelistAlreadyEnabled();

  /**
   * @dev Throws an error indicating that the whitelist is already disabled.
   */
  error WhitelistAlreadyDisabled();

  /**
   * @dev Throws an error indicating that the address is not in the whitelist.
   */
  error NotInWhitelist();

  // ************************************
  // ***** External Methods ******

  /**
   * @dev Returns true if the whitelist is enabled, false otherwise.
    @return bool representing whether the whitelist is enabled.
  */
  function whitelistEnabled() external returns (bool);

  /**
   * @dev Returns true if the address is in the whitelist, false otherwise.

   * @param _address The address to check.
    @return bool representing whether the address is in the whitelist.
  */
  function whitelistedAddresses(address _address) external returns (bool);

  /**
   * @dev Adds the specified address to the whitelist, reverts if not the platform admin
   * @param _address The address to add.
   */
  function addToWhitelist(address _address) external;

  /**
   * @dev Adds the array of addresses to the whitelist, reverts if not the platform admin.
   * @param _addresses The address to add.
   */
  function batchAddToWhitelist(address[] calldata _addresses) external;

  /**
   * @dev Removes the specified address from the whitelist, reverts if not the platform admin
   * @param _address The address to remove.
   */
  function removeFromWhitelist(address _address) external;

  /**
   * @dev Removes the array of addresses from the whitelist, reverts if not the platform admin
   * @param _addresses The array of addresses to remove.
   */
  function batchRemoveFromWhitelist(address[] calldata _addresses) external;

  /**
   * @dev Enables the whitelist, allowing only whitelisted addresses to interact with the contract. Reverts if the caller is not the platform admin
   */
  function enableWhitelist() external;

  /**
   * @dev Disables the whitelist, allowing all addresses to interact with the contract. Reverts if the caller is not the platform admin
   */
  function disableWhitelist() external;
}
