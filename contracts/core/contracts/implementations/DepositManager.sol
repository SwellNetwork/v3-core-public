// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {IDepositManager} from "../interfaces/IDepositManager.sol";
import {INodeOperatorRegistry} from "../interfaces/INodeOperatorRegistry.sol";

import {SwellLib} from "../libraries/SwellLib.sol";
import {DepositDataRoot} from "../libraries/DepositDataRoot.sol";

import {IDepositContract} from "../vendors/IDepositContract.sol";

/**
 * @title DepositManager
 * @author https://github.com/max-taylor
 * @notice This contract will hold the ETH while awaiting new validator setup. This contract will also be used as the withdrawal_credentials when setting up new validators, so that any exited validator ETH and rewards will be sent here.
 */
contract DepositManager is IDepositManager, Initializable {
  using SafeERC20 for IERC20;

  IAccessControlManager public AccessControlManager;
  IDepositContract public DepositContract;

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

  receive() external payable {
    emit ETHReceived(msg.sender, msg.value);
  }

  function initialize(
    IAccessControlManager _accessControlManager
  ) external initializer checkZeroAddress(address(_accessControlManager)) {
    DepositContract = IDepositContract(
      // Hardcoded address for the ETH2 deposit contract
      // Mainnet - 0x00000000219ab540356cBB839Cbe05303d7705Fa
      // Goerli - 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b
      0x00000000219ab540356cBB839Cbe05303d7705Fa
    );

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

  function setupValidators(
    bytes[] calldata _pubKeys,
    bytes32 _depositDataRoot
  ) external override checkRole(SwellLib.BOT) {
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }

    // Protect against this method being front-ran by an operator
    if (_depositDataRoot != DepositContract.get_deposit_root()) {
      revert InvalidDepositDataRoot();
    }

    // Validator setup in the deposit contract requires 32 ETH
    uint256 depositAmount = 32 ether;

    if (address(this).balance < _pubKeys.length * depositAmount) {
      revert InsufficientETHBalance();
    }

    // Validates all the provided pubKeys have been registered by the Node operator registry and are pending validator keys, also return the signatures for each
    INodeOperatorRegistry.ValidatorDetails[]
      memory validatorDetails = AccessControlManager
        .NodeOperatorRegistry()
        .usePubKeysForValidatorSetup(_pubKeys);

    // Cache the withdrawal credentials
    bytes memory withdrawalCredentials = getWithdrawalCredentials();

    for (uint256 i; i < validatorDetails.length; i++) {
      bytes32 depositDataRoot = DepositDataRoot.formatDepositDataRoot(
        validatorDetails[i].pubKey,
        withdrawalCredentials,
        validatorDetails[i].signature,
        depositAmount
      );

      DepositContract.deposit{value: depositAmount}(
        validatorDetails[i].pubKey,
        withdrawalCredentials,
        validatorDetails[i].signature,
        depositDataRoot
      );
    }

    emit ValidatorsSetup(_pubKeys);
  }

  function getWithdrawalCredentials()
    public
    view
    override
    returns (bytes memory withdrawalCredentials)
  {
    // Create the bytes array which will contain the withdrawal credentials, this must be a dynamic bytes array of 32 length in order to work with the deposit contract
    withdrawalCredentials = new bytes(32);

    // Store the ETH1 withdrawal prefix, see IDepositManager.sol for more details
    withdrawalCredentials[0] = 0x01;

    assembly {
      // Add 44 bytes to the withdrawalCredentials memory address; 32 bytes to skip over the length storage slot and another 12 (the prefix + 11 empty bytes)
      // The remaining 20 bytes are to store the address of the contract. To enable this we must bit shift left the address() variable by 96 bits (12 bytes), so that instead of address() taking up the last 20 bytes it will instead take up the first 20 so that it can be copied into the remaining 20 bytes in the withdrawalCredentials
      mstore(add(withdrawalCredentials, 44), shl(96, address()))
    }
  }
}
