// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IAccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IDepositManager} from "./IDepositManager.sol";
import {IswETH} from "./IswETH.sol";
import {INodeOperatorRegistry} from "./INodeOperatorRegistry.sol";

/**
  @title IAccessControlManager
  @author https://github.com/max-taylor 
  @dev The interface for the Access Control Manager, which manages roles and permissions for contracts within the Swell ecosystem
*/
interface IAccessControlManager is IAccessControlEnumerableUpgradeable {
  // ***** Structs ******

  /**
    @dev Parameters for initializing the contract.
    @param admin The admin address
    @param swellTreasury The swell treasury address
  */
  struct InitializeParams {
    address admin;
    address swellTreasury;
  }

  // ***** Errors ******

  /**
    @dev Error thrown when attempting to pause an already-paused boolean
  */
  error AlreadyPaused();

  /**
    @dev Error thrown when attempting to unpause an already-unpaused boolean
  */
  error AlreadyUnpaused();

  // ***** Events ******

  /**
    @dev Emitted when a new DepositManager contract address is set.
    @param newAddress The new DepositManager contract address.
    @param oldAddress The old DepositManager contract address.
  */
  event UpdatedDepositManager(address newAddress, address oldAddress);

  /**
    @dev Emitted when a new NodeOperatorRegistry contract address is set.
    @param newAddress The new NodeOperatorRegistry contract address.
    @param oldAddress The old NodeOperatorRegistry contract address.
  */
  event UpdatedNodeOperatorRegistry(address newAddress, address oldAddress);

  /**
    @dev Emitted when a new SwellTreasury contract address is set.
    @param newAddress The new SwellTreasury contract address.
    @param oldAddress The old SwellTreasury contract address.
  */
  event UpdatedSwellTreasury(address newAddress, address oldAddress);

  /**
    @dev Emitted when a new SwETH contract address is set.
    @param newAddress The new SwETH contract address.
    @param oldAddress The old SwETH contract address.
  */
  event UpdatedSwETH(address newAddress, address oldAddress);

  /**
    @dev Emitted when core methods functionality is paused or unpaused.
    @param newPausedStatus The new paused status.
  */
  event CoreMethodsPause(bool newPausedStatus);

  /**
    @dev Emitted when bot methods functionality is paused or unpaused.
    @param newPausedStatus The new paused status.
  */
  event BotMethodsPause(bool newPausedStatus);

  /**
    @dev Emitted when operator methods functionality is paused or unpaused.
    @param newPausedStatus The new paused status.
  */
  event OperatorMethodsPause(bool newPausedStatus);

  /**
    @dev Emitted when withdrawals functionality is paused or unpaused.
    @param newPausedStatus The new paused status.
  */
  event WithdrawalsPause(bool newPausedStatus);

  // ************************************
  // ***** External Methods ******

  /**
   * @dev Pass-through method to call the _checkRole method on the inherited access control contract. This method is to be used by external contracts that are using this centralised access control manager, this ensures that if the check fails it reverts with the correct access control error message
   * @param role The role to check
   * @param account The account to check for
   */
  function checkRole(bytes32 role, address account) external view;

  // ***** Setters ******

  /**
   * @notice Sets the `swETH` address to `_swETH`.
   * @dev This function is only callable by the `PLATFORM_ADMIN` role.
   * @param _swETH The address of the `swETH` contract.
   */
  function setSwETH(IswETH _swETH) external;

  /**
   * @notice Sets the `DepositManager` address to `_depositManager`.
   * @dev This function is only callable by the `PLATFORM_ADMIN` role.
   * @param _depositManager The address of the `DepositManager` contract.
   */
  function setDepositManager(IDepositManager _depositManager) external;

  /**
   * @notice Sets the `NodeOperatorRegistry` address to `_NodeOperatorRegistry`.
   * @dev This function is only callable by the `PLATFORM_ADMIN` role.
   * @param _NodeOperatorRegistry The address of the `NodeOperatorRegistry` contract.
   */
  function setNodeOperatorRegistry(
    INodeOperatorRegistry _NodeOperatorRegistry
  ) external;

  /**
   * @notice Sets the `SwellTreasury` address to `_swellTreasury`.
   * @dev This function is only callable by the `PLATFORM_ADMIN` role.
   * @param _swellTreasury The new address of the `SwellTreasury` contract.
   */
  function setSwellTreasury(address _swellTreasury) external;

  // ***** Getters ******

  /**
    @dev Returns the PLATFORM_ADMIN role.
    @return The bytes32 representation of the PLATFORM_ADMIN role.
  */
  function PLATFORM_ADMIN() external pure returns (bytes32);

  /**
    @dev Returns the Swell ETH contract.
    @return The Swell ETH contract.
  */
  function swETH() external returns (IswETH);

  /**
    @dev Returns the address of the Swell Treasury contract.
    @return The address of the Swell Treasury contract.
  */
  function SwellTreasury() external returns (address);

  /**
    @dev Returns the Deposit Manager contract.
    @return The Deposit Manager contract.
  */
  function DepositManager() external returns (IDepositManager);

  /**
    @dev Returns the Node Operator Registry contract.
    @return The Node Operator Registry contract.
  */
  function NodeOperatorRegistry() external returns (INodeOperatorRegistry);

  /**
    @dev Returns true if core methods are currently paused.
    @return Whether core methods are paused.
  */
  function coreMethodsPaused() external returns (bool);

  /**
    @dev Returns true if bot methods are currently paused.
    @return Whether bot methods are paused.
  */
  function botMethodsPaused() external returns (bool);

  /**
    @dev Returns true if operator methods are currently paused.
    @return Whether operator methods are paused.
  */
  function operatorMethodsPaused() external returns (bool);

  /**
    @dev Returns true if withdrawals are currently paused.
    @dev ! Note that this is completely unused in the current implementation and is a placeholder that will be used once the withdrawals are implemented.
    @return Whether withdrawals are paused.
  */
  function withdrawalsPaused() external returns (bool);

  // ***** Pausable methods ******

  /**
    @dev Pauses the core methods of the Swell ecosystem, only callable by the PLATFORM_ADMIN
  */
  function pauseCoreMethods() external;

  /**
    @dev Unpauses the core methods of the Swell ecosystem, only callable by the PLATFORM_ADMIN
  */
  function unpauseCoreMethods() external;

  /**
    @dev Pauses the bot specific methods, only callable by the PLATFORM_ADMIN
  */
  function pauseBotMethods() external;

  /**
    @dev Unpauses the bot specific methods, only callable by the PLATFORM_ADMIN
  */
  function unpauseBotMethods() external;

  /**
    @dev Pauses the operator methods in the NO registry contract, only callable by the PLATFORM_ADMIN
  */
  function pauseOperatorMethods() external;

  /**
    @dev Unpauses the operator methods in the NO registry contract, only callable by the PLATFORM_ADMIN
  */
  function unpauseOperatorMethods() external;

  /**
    @dev Pauses the withdrawals of the Swell ecosystem, only callable by the PLATFORM_ADMIN
  */
  function pauseWithdrawals() external;

  /**
    @dev Unpauses the withdrawals of the Swell ecosystem, only callable by the PLATFORM_ADMIN
  */
  function unpauseWithdrawals() external;

  /**
   * @dev This method withdraws contract's _token balance to a platform admin
   * @param _token The ERC20 token to withdraw from the contract
   */
  function withdrawERC20(IERC20 _token) external;
}
