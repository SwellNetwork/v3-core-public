// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {IDepositManager} from "../interfaces/IDepositManager.sol";
import {ILstRateProvider} from "../interfaces/ILstRateProvider.sol";
import {INodeOperatorRegistry} from "../interfaces/INodeOperatorRegistry.sol";
import {IrswETH} from "../interfaces/IrswETH.sol";
import {IswETH} from "../interfaces/IswETH.sol";
import {IWhitelist} from "../interfaces/IWhitelist.sol";
import {SwellLib} from "../libraries/SwellLib.sol";
import {DepositDataRoot} from "../libraries/DepositDataRoot.sol";
import {EigenLayerManager, IEigenLayerManager} from "./EigenLayerManager.sol";
import {IDepositContract} from "../vendors/IDepositContract.sol";
import {IEigenPodManager} from "../vendors/contracts/interfaces/IEigenPodManager.sol";
import {IEigenPod} from "../vendors/contracts/interfaces/IEigenPod.sol";
import {EigenPod} from "../vendors/contracts/pods/EigenPod.sol";

/**
 * @title DepositManager
 * @dev This contract is responsible for managing deposits of ETH into the ETH2 deposit contract, and ETH/ERC20s into EigenLayer.
 * @dev The following contracts are permissioned to withdraw from this contract: EigenLayerManager (ETH and tokens) for staking and rswEXIT (ETH) to satisfy withdrawals.
 */
contract DepositManager is IDepositManager, Initializable {
  using SafeERC20 for IERC20;

  IAccessControlManager public AccessControlManager;
  IDepositContract public constant DEPOSIT_CONTRACT =
    IDepositContract(
      // Hardcoded address for the ETH2 deposit contract
      // Mainnet - 0x00000000219ab540356cBB839Cbe05303d7705Fa
      // Goerli - 0xff50ed3d0ec03aC01D4C79aAd74928BFF48a7b2b
      0x00000000219ab540356cBB839Cbe05303d7705Fa
    );
  IEigenPodManager public EigenPodManager;
  IEigenPod public eigenPodDeprecated;

  // Validator setup in the deposit contract requires 32 ETH
  uint256 internal constant DEPOSIT_AMOUNT = 32 ether;

  IEigenLayerManager public eigenLayerManager;

  // LST Token Address => Rate contract address
  mapping(address => address) public exchangeRateProviders;

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

  /**
   * @dev Checks if the rswETH whitelist is enabled, and whether the address is whitelisted
   * @param _address The address to check in the whitelist
   */
  modifier checkWhitelist(address _address) {
    IWhitelist whitelist = IWhitelist(address(AccessControlManager.rswETH()));
    if (
      whitelist.whitelistEnabled() && !whitelist.whitelistedAddresses(_address)
    ) {
      revert IWhitelist.NotInWhitelist();
    }

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
  )
    external
    initializer
    checkZeroAddress(address(_accessControlManager))
    checkZeroAddress(_eigenManager)
  {
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

  function setEigenLayerManager(
    address _eigenLayerManager
  )
    external
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_eigenLayerManager)
  {
    eigenLayerManager = EigenLayerManager(payable(_eigenLayerManager));
    emit EigenLayerManagerSet(_eigenLayerManager);
  }

  function setupValidators(
    bytes[] calldata _pubKeys,
    bytes32 _depositRoot
  ) external checkRole(SwellLib.BOT) {
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }

    if (_pubKeys.length == 0) {
      revert NoPubKeysProvided();
    }

    // Protect against this method being front-ran by an operator
    if (_depositRoot != DEPOSIT_CONTRACT.get_deposit_root()) {
      revert InvalidDepositDataRoot();
    }

    uint256 exitingETH = AccessControlManager.rswEXIT().exitingETH();

    if (address(this).balance < _pubKeys.length * DEPOSIT_AMOUNT + exitingETH) {
      revert InsufficientETHBalance();
    }

    if (address(eigenPodDeprecated) == address(0)) {
      revert EigenPodNotCreated();
    }

    // Validates all the provided pubKeys have been registered by the Node operator registry and are pending validator keys, also return the signatures for each
    INodeOperatorRegistry.ValidatorDetails[]
      memory validatorDetails = AccessControlManager
        .NodeOperatorRegistry()
        .usePubKeysForValidatorSetup(_pubKeys);

    // Cache the withdrawal credentials
    bytes
      memory withdrawalCredentials = generateWithdrawalCredentialsForEigenPod();

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

  function depositLST(
    address _token,
    uint256 _amount,
    uint256 _minRswETH
  ) external checkWhitelist(msg.sender) checkZeroAddress(_token) {
    if (_amount == 0) {
      revert CannotDepositZero();
    }

    if (exchangeRateProviders[_token] == address(0)) {
      revert NoRateProviderSet();
    }

    IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

    uint256 rate = ILstRateProvider(exchangeRateProviders[_token]).getRate();
    uint256 ETHAmount = (_amount * rate) / 1e18;

    IrswETH rswETH = AccessControlManager.rswETH();
    rswETH.depositViaDepositManager(ETHAmount, msg.sender, _minRswETH);

    emit LSTDeposited(_token, _amount);
  }

  function transferETHForWithdrawRequests(uint256 _amount) external override {
    if (msg.sender != address(AccessControlManager.rswEXIT())) {
      revert OnlyRswEXITCanWithdrawETH();
    }

    AddressUpgradeable.sendValue(payable(msg.sender), _amount);

    emit EthSent(msg.sender, _amount);
  }

  function transferTokenForDepositIntoStrategy(
    address _token,
    uint256 _amount,
    address _stakerProxyAddress
  ) external override {
    if (msg.sender != address(eigenLayerManager)) {
      revert OnlyEigenLayerManagerCanWithdrawTokens();
    }
    IERC20 token = IERC20(_token);
    token.safeTransfer(_stakerProxyAddress, _amount);
  }

  function transferETHForEigenLayerDeposits(
    bytes[] calldata _pubKeys,
    bytes32 _depositDataRoot
  )
    external
    override
    returns (INodeOperatorRegistry.ValidatorDetails[] memory)
  {
    if (msg.sender != address(eigenLayerManager)) {
      revert OnlyEigenLayerManagerCanWithdrawETH();
    }

    if (_pubKeys.length == 0) {
      revert NoPubKeysProvided();
    }

    // Protect against this method being front-ran by an operator
    if (_depositDataRoot != DEPOSIT_CONTRACT.get_deposit_root()) {
      revert InvalidDepositDataRoot();
    }

    uint256 amount = _pubKeys.length * DEPOSIT_AMOUNT;

    uint256 exitingETH = AccessControlManager.rswEXIT().exitingETH();
    if (address(this).balance < amount + exitingETH) {
      revert InsufficientETHBalance();
    }

    INodeOperatorRegistry.ValidatorDetails[]
      memory validatorDetails = AccessControlManager
        .NodeOperatorRegistry()
        .usePubKeysForValidatorSetup(_pubKeys);

    AddressUpgradeable.sendValue(payable(msg.sender), amount);
    emit EthSent(msg.sender, amount);

    return validatorDetails;
  }

  /* ------ ADMIN METHODS ------*/

  function setExchangeRateProvider(
    address _token,
    address _exchangeRateProvider
  )
    external
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_token)
    checkZeroAddress(_exchangeRateProvider)
  {
    exchangeRateProviders[_token] = _exchangeRateProvider;
    emit ExchangeRateProviderSet(_token, _exchangeRateProvider);
  }

  function eigenPodWithdrawBeforeRestaking()
    external
    checkRole(SwellLib.PLATFORM_ADMIN)
  {
    eigenPodDeprecated.withdrawBeforeRestaking();
  }

  /// @dev This function is used to claim partial withdrawals on behalf of the recipient after the withdrawal delay has passed.
  /// The recipent will still receive the funds, not the msg.sender
  function claimDelayedWithdrawals(
    address _recipient,
    uint256 _maxNumberOfWithdrawalsToClaim
  )
    external
    checkRole(SwellLib.EIGENLAYER_WITHDRAWALS)
    checkZeroAddress(_recipient)
  {
    EigenPod(payable(address(eigenPodDeprecated)))
      .delayedWithdrawalRouter()
      .claimDelayedWithdrawals(_recipient, _maxNumberOfWithdrawalsToClaim);
  }

  /*------ View Functions ------*/

  function generateWithdrawalCredentialsForEigenPod()
    public
    view
    returns (bytes memory)
  {
    return
      abi.encodePacked(bytes1(0x01), bytes11(0x0), address(eigenPodDeprecated));
  }
}
