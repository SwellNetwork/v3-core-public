// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {IDepositManager} from "../interfaces/IDepositManager.sol";
import {IrswETH} from "../interfaces/IrswETH.sol";
import {IrswEXIT} from "../interfaces/IrswEXIT.sol";
import {INodeOperatorRegistry} from "../interfaces/INodeOperatorRegistry.sol";

import {SwellLib} from "../libraries/SwellLib.sol";

/**
 * @title AccessControlManager
 * @author https://github.com/max-taylor
 * @notice This contract will act as the centralized access control registry to use throughout the protocol. It also manages the pausing of protocol functionality.
 */
contract AccessControlManager is
  IAccessControlManager,
  AccessControlEnumerableUpgradeable
{
  using SafeERC20 for IERC20;

  address public override SwellTreasury;

  IrswETH public override rswETH;
  IDepositManager public override DepositManager;
  INodeOperatorRegistry public override NodeOperatorRegistry;

  bool public override coreMethodsPaused;
  bool public override botMethodsPaused;
  bool public override operatorMethodsPaused;
  bool public override withdrawalsPaused;

  IrswEXIT public override rswEXIT;

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
   * @dev Modifier to help paused status updates and throwing of errors when the paused status' are equal
   * @param _currentStatus The current paused status
   * @param _newStatus The new status to update to
   */
  modifier alreadyPausedStatus(bool _currentStatus, bool _newStatus) {
    if (_currentStatus == _newStatus) {
      if (_currentStatus) {
        revert AlreadyPaused();
      } else {
        revert AlreadyUnpaused();
      }
    }

    _;
  }

  function initialize(
    InitializeParams calldata _initializeParams
  )
    external
    initializer
    checkZeroAddress(_initializeParams.admin)
    checkZeroAddress(_initializeParams.swellTreasury)
  {
    __AccessControlEnumerable_init();

    _grantRole(DEFAULT_ADMIN_ROLE, _initializeParams.admin);
    // Grant platform admin to the deployer, this simplifies the deployment process
    _grantRole(SwellLib.PLATFORM_ADMIN, msg.sender);

    _setRoleAdmin(SwellLib.BOT, SwellLib.PLATFORM_ADMIN);

    coreMethodsPaused = true;
    botMethodsPaused = true;
    operatorMethodsPaused = true;
    withdrawalsPaused = true;

    SwellTreasury = _initializeParams.swellTreasury;
  }

  // ************************************
  // ***** External Methods ******

  function withdrawERC20(
    IERC20 _token
  ) external override onlyRole(SwellLib.PLATFORM_ADMIN) {
    uint256 contractBalance = _token.balanceOf(address(this));
    if (contractBalance == 0) {
      revert SwellLib.NoTokensToWithdraw();
    }

    _token.safeTransfer(msg.sender, contractBalance);
  }

  function checkRole(bytes32 role, address account) external view override {
    _checkRole(role, account);
  }

  function setRswETH(
    IrswETH _rswETH
  )
    external
    override
    onlyRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(address(_rswETH))
  {
    emit UpdatedRswETH(address(_rswETH), address(rswETH));

    rswETH = _rswETH;
  }

  function setDepositManager(
    IDepositManager _depositManager
  )
    external
    override
    onlyRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(address(_depositManager))
  {
    emit UpdatedDepositManager(
      address(_depositManager),
      address(DepositManager)
    );

    DepositManager = _depositManager;
  }

  function setNodeOperatorRegistry(
    INodeOperatorRegistry _NodeOperatorRegistry
  )
    external
    override
    onlyRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(address(_NodeOperatorRegistry))
  {
    emit UpdatedNodeOperatorRegistry(
      address(_NodeOperatorRegistry),
      address(NodeOperatorRegistry)
    );

    NodeOperatorRegistry = _NodeOperatorRegistry;
  }

  function setSwellTreasury(
    address _swellTreasury
  )
    external
    override
    onlyRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_swellTreasury)
  {
    emit UpdatedSwellTreasury(address(_swellTreasury), address(SwellTreasury));

    SwellTreasury = _swellTreasury;
  }

  function setRswEXIT(
    IrswEXIT _rswEXIT
  )
    external
    override
    onlyRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(address(_rswEXIT))
  {
    emit UpdatedRswEXIT(address(_rswEXIT), address(rswEXIT));

    rswEXIT = _rswEXIT;
  }

  // ***** Pausable methods ******

  function pauseCoreMethods()
    external
    override
    onlyRole(SwellLib.PAUSER)
    alreadyPausedStatus(coreMethodsPaused, true)
  {
    _pauseCoreMethods();
  }

  function unpauseCoreMethods()
    external
    override
    onlyRole(SwellLib.UNPAUSER)
    alreadyPausedStatus(coreMethodsPaused, false)
  {
    coreMethodsPaused = false;

    emit CoreMethodsPause(false);
  }

  function pauseBotMethods()
    external
    override
    onlyRole(SwellLib.PAUSER)
    alreadyPausedStatus(botMethodsPaused, true)
  {
    _pauseBotMethods();
  }

  function unpauseBotMethods()
    external
    override
    onlyRole(SwellLib.UNPAUSER)
    alreadyPausedStatus(botMethodsPaused, false)
  {
    botMethodsPaused = false;

    emit BotMethodsPause(false);
  }

  function pauseOperatorMethods()
    external
    override
    onlyRole(SwellLib.PAUSER)
    alreadyPausedStatus(operatorMethodsPaused, true)
  {
    _pauseOperatorMethods();
  }

  function unpauseOperatorMethods()
    external
    override
    onlyRole(SwellLib.UNPAUSER)
    alreadyPausedStatus(operatorMethodsPaused, false)
  {
    operatorMethodsPaused = false;

    emit OperatorMethodsPause(false);
  }

  function pauseWithdrawals()
    external
    override
    onlyRole(SwellLib.PAUSER)
    alreadyPausedStatus(withdrawalsPaused, true)
  {
    _pauseWithdrawals();
  }

  function unpauseWithdrawals()
    external
    override
    onlyRole(SwellLib.UNPAUSER)
    alreadyPausedStatus(withdrawalsPaused, false)
  {
    withdrawalsPaused = false;

    emit WithdrawalsPause(false);
  }

  function lockdown() external override onlyRole(SwellLib.PAUSER) {
    _pauseCoreMethods();
    _pauseBotMethods();
    _pauseOperatorMethods();
    _pauseWithdrawals();

    emit Lockdown();
  }

  // ************************************
  // ***** External - view ******

  function PLATFORM_ADMIN() external pure override returns (bytes32) {
    return SwellLib.PLATFORM_ADMIN;
  }

  // ************************************
  // ***** Internal ******

  function _pauseCoreMethods() internal {
    coreMethodsPaused = true;

    emit CoreMethodsPause(true);
  }

  function _pauseBotMethods() internal {
    botMethodsPaused = true;

    emit BotMethodsPause(true);
  }

  function _pauseOperatorMethods() internal {
    operatorMethodsPaused = true;

    emit OperatorMethodsPause(true);
  }

  function _pauseWithdrawals() internal {
    withdrawalsPaused = true;

    emit WithdrawalsPause(true);
  }
}
