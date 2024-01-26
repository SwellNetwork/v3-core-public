// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {IDepositManager} from "../interfaces/IDepositManager.sol";
import {INodeOperatorRegistry} from "../interfaces/INodeOperatorRegistry.sol";

import {SwellLib} from "../libraries/SwellLib.sol";
import {DepositDataRoot} from "../libraries/DepositDataRoot.sol";

import {IDepositContract} from "../vendors/IDepositContract.sol";
import {IEigenPodManager, IEigenPod} from "../vendors/EigenLayer.sol";


/**
 * @title DepositManager
 * @author https://github.com/max-taylor
 * @notice This contract will hold the ETH while awaiting new validator setup. This contract will also be used as the withdrawal_credentials when setting up new validators, so that any exited validator ETH and rewards will be sent here.
 */
contract DepositManager is IDepositManager, Initializable {
  using SafeERC20 for IERC20;

  IAccessControlManager public AccessControlManager;
  IDepositContract public constant DEPOSIT_CONTRACT = IDepositContract(
    // Hardcoded address for the ETH2 deposit contract
    // Mainnet - 0x00000000219ab540356cBB839Cbe05303d7705Fa
    // Goerli - 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b
    0x00000000219ab540356cBB839Cbe05303d7705Fa
  );
  IEigenPodManager public EigenPodManager;

  IEigenPod public eigenPod;

  // Validator setup in the deposit contract requires 32 ETH
  uint256 internal constant DEPOSIT_AMOUNT = 32 ether;

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
    IAccessControlManager _accessControlManager,
    address _eigenManager
  ) external initializer checkZeroAddress(address(_accessControlManager)) checkZeroAddress(_eigenManager) {
    AccessControlManager = _accessControlManager;
    EigenPodManager = IEigenPodManager(_eigenManager);
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
    if (_pubKeys.length == 0) {
      revert NoPubKeysProvided();
    }
    
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }

    // Protect against this method being front-ran by an operator
    if (_depositDataRoot != DEPOSIT_CONTRACT.get_deposit_root()) {
      revert InvalidDepositDataRoot();
    }

    if (address(this).balance < _pubKeys.length * DEPOSIT_AMOUNT) {
      revert InsufficientETHBalance();
    }

    if (address(eigenPod) == address(0)) {
      revert EigenPodNotCreated();
    }

    // Validates all the provided pubKeys have been registered by the Node operator registry and are pending validator keys, also return the signatures for each
    INodeOperatorRegistry.ValidatorDetails[]
      memory validatorDetails = AccessControlManager
        .NodeOperatorRegistry()
        .usePubKeysForValidatorSetup(_pubKeys);

    // Cache the withdrawal credentials
    bytes memory withdrawalCredentials = generateWithdrawalCredentialsForEigenPod();

    for (uint256 i; i < validatorDetails.length; i++) {
      bytes32 depositDataRoot = DepositDataRoot.formatDepositDataRoot(
        validatorDetails[i].pubKey,
        withdrawalCredentials,
        validatorDetails[i].signature,
        DEPOSIT_AMOUNT
      );

      DEPOSIT_CONTRACT.deposit{value: DEPOSIT_AMOUNT}(
        validatorDetails[i].pubKey,
        withdrawalCredentials,
        validatorDetails[i].signature,
        depositDataRoot
      );
    }

    emit ValidatorsSetup(_pubKeys);
  }

  //The DepositManager will be the pod owner in the EigenPodManager contract
  function createEigenPod() public checkRole(SwellLib.PLATFORM_ADMIN) {
    if (address(eigenPod) != address(0)) {
      revert EigenPodMaxLimitReached();
    }
    EigenPodManager.createPod();

    eigenPod = EigenPodManager.getPod(address(this));

    emit EigenPodCreated(address(eigenPod));
  }

  function generateWithdrawalCredentialsForEigenPod() public view returns (bytes memory){
    return abi.encodePacked(bytes1(0x01), bytes11(0x0), address(eigenPod));
  }
}
