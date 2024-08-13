// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.16;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {SwellLib} from "../libraries/SwellLib.sol";
import {StakerProxy} from "../implementations/StakerProxy.sol";
import {IEigenLayerManager} from "../interfaces/IEigenLayerManager.sol";
import {INodeOperatorRegistry} from "../interfaces/INodeOperatorRegistry.sol";
import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {IDelegationManager} from "../vendors/contracts/interfaces/IDelegationManager.sol";
import {BeaconChainProofs} from "../vendors/contracts/libraries/BeaconChainProofs.sol";
import {IDelayedWithdrawalRouter} from "../vendors/contracts/interfaces/IDelayedWithdrawalRouter.sol";
import {IEigenPodManager} from "../vendors/contracts/interfaces/IEigenPodManager.sol";
import {IStrategy} from "../vendors/contracts/interfaces/IStrategy.sol";

/**
 * @title EigenLayerManager
 * @dev This contract facilitates interaction with EigenLayer via StakerProxies.
 * @dev StakerProxies manage an EigenPod and are the accounts which ultimately stake funds in EigenLayer.
 * @dev This contract manages the delegation of stakers to operators.
 * @dev This contract also manages the upgrade of StakerProxies via Beacon proxy pattern.
 */
contract EigenLayerManager is IEigenLayerManager, ReentrancyGuardUpgradeable {
  IAccessControlManager public AccessControlManager;

  uint256 public stakeId;
  IDelayedWithdrawalRouter public DelayedWithdrawalRouter;
  IDelegationManager public DelegationManager;
  IEigenPodManager public EigenPodManager;
  address public strategyManagerAddress;
  address public adminSigner;
  address public upgradableBeacon;
  mapping(address => uint256[]) public operatorToStakers;
  mapping(uint256 => address) public stakerProxyAddresses;
  mapping(address => address) public tokenToStrategy;

  // Validator setup in the deposit contract requires 32 ETH
  uint256 internal constant DEPOSIT_AMOUNT = 32 ether;

  modifier checkRole(bytes32 role) {
    AccessControlManager.checkRole(role, msg.sender);
    _;
  }

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

  fallback() external {
    revert SwellLib.InvalidMethodCall();
  }

  receive() external payable {
    if (msg.sender != address(AccessControlManager.DepositManager())) {
      revert SwellLib.InvalidMethodCall();
    }

    emit ETHReceived(msg.sender, msg.value);
  }

  function initialize(
    IAccessControlManager _accessControlManager,
    address _eigenPodManager,
    address _adminSigner,
    address _delayedWithdrawalRouter,
    address _strategyManager,
    address _delegationManager
  )
    external
    initializer
    checkZeroAddress(address(_accessControlManager))
    checkZeroAddress(_eigenPodManager)
    checkZeroAddress(_adminSigner)
    checkZeroAddress(_delayedWithdrawalRouter)
    checkZeroAddress(_strategyManager)
    checkZeroAddress(_delegationManager)
  {
    __ReentrancyGuard_init();

    AccessControlManager = _accessControlManager;
    EigenPodManager = IEigenPodManager(_eigenPodManager);
    adminSigner = _adminSigner;
    DelayedWithdrawalRouter = IDelayedWithdrawalRouter(
      _delayedWithdrawalRouter
    );
    strategyManagerAddress = _strategyManager;
    DelegationManager = IDelegationManager(_delegationManager);
  }

  function isValidStaker(uint256 stakerId) public view returns (address) {
    return _isValidStaker(stakerId);
  }

  function stakeOnEigenLayer(
    uint256[] calldata _stakerIds,
    bytes[] calldata _pubKeys,
    bytes32 _depositDataRoot
  ) external checkRole(SwellLib.BOT) nonReentrant {
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }

    if (_stakerIds.length != _pubKeys.length) {
      revert ArrayLengthMismatch();
    }

    // prepares validator details and transfers required ETH
    INodeOperatorRegistry.ValidatorDetails[]
      memory validatorDetails = AccessControlManager
        .DepositManager()
        .transferETHForEigenLayerDeposits(_pubKeys, _depositDataRoot);

    uint256 validatorDetailsLength = validatorDetails.length;
    for (uint256 i; i < validatorDetailsLength; ) {
      uint256 stakerId = _stakerIds[i];
      address stakerProxyAddress = _isValidStaker(stakerId);

      StakerProxy(payable(stakerProxyAddress)).stakeOnEigenLayer{
        value: DEPOSIT_AMOUNT
      }(validatorDetails[i].pubKey, validatorDetails[i].signature);
      unchecked {
        ++i;
      }
    }

    emit ValidatorsSetupOnEigenLayer(_stakerIds, _pubKeys);
  }

  function depositIntoEigenLayerStrategy(
    uint256 _stakerId,
    uint256 _amount,
    address _token
  ) external checkRole(SwellLib.BOT) checkZeroAddress(_token) nonReentrant {
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }
    if (_amount == 0) {
      revert CannotDepositZero();
    }

    address stakerProxyAddress = _isValidStaker(_stakerId);

    IERC20 token = IERC20(_token);

    IStrategy currentStrategy = IStrategy(tokenToStrategy[_token]);
    if (address(currentStrategy) == address(0)) {
      revert StrategyNotSet();
    }

    // DepositManager transfers ERC20s to the stakerProxy so that it can complete the deposit
    AccessControlManager.DepositManager().transferTokenForDepositIntoStrategy(
      _token,
      _amount,
      stakerProxyAddress
    );

    StakerProxy(payable(stakerProxyAddress)).depositIntoStrategy(
      currentStrategy,
      token,
      _amount
    );

    emit DepositedIntoStrategy(_amount, _token, currentStrategy);
  }

  function setEigenLayerStrategy(
    address _token,
    address _strategy
  )
    external
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_token)
    checkZeroAddress(_strategy)
  {
    if (address(IStrategy(_strategy).underlyingToken()) != _token) {
      revert StrategyTokenMismatch();
    }
    tokenToStrategy[_token] = _strategy;

    emit StrategySetAndApproved(_token, _strategy);
  }

  function getDelegatedStakers(
    address _operator
  ) public view returns (uint256[] memory) {
    return operatorToStakers[_operator];
  }

  function createStakerAndPod(
    uint256 _batchSize
  ) external checkRole(SwellLib.PLATFORM_ADMIN) {
    if (_batchSize == 0) {
      revert BatchSizeCannotBeZero();
    }

    for (uint256 i; i < _batchSize; ) {
      address stakerProxyAddress = _createStakerProxy();
      ++stakeId;
      stakerProxyAddresses[stakeId] = stakerProxyAddress;
      unchecked {
        ++i;
      }
    }
  }

  function setAdminSigner(
    address _adminSigner
  ) external checkRole(SwellLib.PLATFORM_ADMIN) checkZeroAddress(_adminSigner) {
    address oldSigner = adminSigner;
    adminSigner = _adminSigner;
    emit AdminSignerUpdated(oldSigner, _adminSigner);
  }

  function setDelayedWithdrawalRouter(
    address _delayedWithdrawalRouter
  )
    external
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_delayedWithdrawalRouter)
  {
    DelayedWithdrawalRouter = IDelayedWithdrawalRouter(
      _delayedWithdrawalRouter
    );
    emit DelayedWithdrawalRouterSet(_delayedWithdrawalRouter);
  }

  function setStrategyManager(
    address _strategyManager
  )
    external
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_strategyManager)
  {
    strategyManagerAddress = _strategyManager;
    emit StrategyManagerAddressSet(_strategyManager);
  }

  function setDelegationManager(
    address _delegationManager
  )
    external
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(address(_delegationManager))
  {
    DelegationManager = IDelegationManager(_delegationManager);
    emit DelegationManagerSet(_delegationManager);
  }

  function delegateToWithSignature(
    uint256 _stakerId,
    address _operator,
    IDelegationManager.SignatureWithExpiry calldata _stakerSignatureAndExpiry,
    IDelegationManager.SignatureWithExpiry calldata _approverSignatureAndExpiry,
    bytes32 _approverSalt
  ) external checkRole(SwellLib.EIGENLAYER_DELEGATOR) {
    address _staker = _isValidStaker(_stakerId);
    uint256[] storage delegatedStakers = operatorToStakers[_operator];

    _delegateToWithSignature(
      _staker,
      _operator,
      _stakerSignatureAndExpiry,
      _approverSignatureAndExpiry,
      _approverSalt
    );
    delegatedStakers.push(_stakerId);
  }

  function batchDelegateToWithSignature(
    uint256[] calldata stakerIds,
    address[] calldata operatorArray,
    IDelegationManager.SignatureWithExpiry[]
      calldata stakerSignatureAndExpiryArray,
    IDelegationManager.SignatureWithExpiry[]
      calldata approverSignatureAndExpiryArray,
    bytes32[] calldata approverSaltArray
  ) external checkRole(SwellLib.EIGENLAYER_DELEGATOR) {
    if (stakerIds.length != operatorArray.length) {
      revert ArrayLengthMismatch();
    }
    if (stakerIds.length != stakerSignatureAndExpiryArray.length) {
      revert ArrayLengthMismatch();
    }
    if (stakerIds.length != approverSignatureAndExpiryArray.length) {
      revert ArrayLengthMismatch();
    }
    if (stakerIds.length != approverSaltArray.length) {
      revert ArrayLengthMismatch();
    }

    for (uint256 i; i < stakerIds.length; ) {
      address staker = _isValidStaker(stakerIds[i]);
      address operator = operatorArray[i];
      uint256[] storage stakers = operatorToStakers[operator];

      _delegateToWithSignature(
        staker,
        operator,
        stakerSignatureAndExpiryArray[i],
        approverSignatureAndExpiryArray[i],
        approverSaltArray[i]
      );
      stakers.push(stakerIds[i]);
      unchecked {
        ++i;
      }
    }
  }

  function unassignStakerFromOperator(
    uint256 _stakerId,
    address _operator
  ) external checkRole(SwellLib.EIGENLAYER_DELEGATOR) {
    address staker = _isValidStaker(_stakerId);
    address operator = DelegationManager.delegatedTo(staker);
    if (operator == _operator) {
      revert StakerIsStillDelegatedToOperator();
    }
    uint256 found = _deleteStakerFromOperatorMapping(_operator, _stakerId);
    if (found == 0) {
      revert StakerNotFoundInOperatorStakerList();
    }
    emit StakerUnassignedFromOperator(_stakerId, _operator);
  }

  function assignStakerToOperator(
    uint256 _stakerId,
    address _operator
  ) external checkRole(SwellLib.EIGENLAYER_DELEGATOR) {
    address staker = _isValidStaker(_stakerId);
    address delegatedOperator = DelegationManager.delegatedTo(staker);
    if (_operator != delegatedOperator) {
      revert StakerIsNotDelegatedToOperator();
    }

    uint256[] storage stakers = operatorToStakers[_operator];

    uint256 cachedStakersLength = stakers.length;
    for (uint256 i; i < cachedStakersLength; ) {
      if (stakers[i] == _stakerId) {
        revert StakerIsAlreadyAssignedToOperator();
      }
      unchecked {
        ++i;
      }
    }

    stakers.push(_stakerId);
    emit StakerAssignedToOperator(_stakerId, _operator);
  }

  /// @dev This function is used to queue a full withdrawal after a validator exit.
  function queueWithdrawals(
    uint256 _stakerProxyId,
    IDelegationManager.QueuedWithdrawalParams[] calldata _queuedWithdrawalParams
  )
    external
    checkRole(SwellLib.EIGENLAYER_WITHDRAWALS)
    returns (bytes32[] memory)
  {
    address staker = _isValidStaker(_stakerProxyId);
    bytes32[] memory withdrawalRoots = StakerProxy(payable(staker))
      .queueWithdrawals(_queuedWithdrawalParams);
    return withdrawalRoots;
  }

  /// @dev This function is used to claim a full withdrawal after the withdrawal delay has passed
  function completeQueuedWithdrawal(
    uint256 _stakerProxyId,
    IDelegationManager.Withdrawal calldata _withdrawal,
    IERC20[] calldata _tokens,
    uint256 _middlewareTimesIndex,
    bool _receiveAsTokens
  ) external checkRole(SwellLib.EIGENLAYER_WITHDRAWALS) {
    address staker = _isValidStaker(_stakerProxyId);
    StakerProxy(payable(staker)).completeQueuedWithdrawal(
      _withdrawal,
      _tokens,
      _middlewareTimesIndex,
      _receiveAsTokens
    );
  }

  function claimDelayedWithdrawals(
    address _recipient,
    uint256 _maxNumberOfWithdrawalsToClaim
  )
    external
    checkRole(SwellLib.EIGENLAYER_WITHDRAWALS)
    checkZeroAddress(_recipient)
  {
    DelayedWithdrawalRouter.claimDelayedWithdrawals(
      _recipient,
      _maxNumberOfWithdrawalsToClaim
    );
  }

  /// @dev This function is called after a validator is created to update the stakers Beacon Chain ETH shares in the EigenPodManager
  function verifyPodWithdrawalCredentials(
    uint256 _stakerProxyId,
    uint64 _oracleTimestamp,
    BeaconChainProofs.StateRootProof calldata _stateRootProof,
    uint40[] calldata _validatorIndices,
    bytes[] calldata _validatorFieldsProofs,
    bytes32[][] calldata _validatorFields
  ) external checkRole(SwellLib.EIGENLAYER_WITHDRAWALS) {
    address staker = _isValidStaker(_stakerProxyId);
    StakerProxy(payable(staker)).verifyPodWithdrawalCredentials(
      _oracleTimestamp,
      _stateRootProof,
      _validatorIndices,
      _validatorFieldsProofs,
      _validatorFields
    );
  }

  /// @dev This function is used to withdraw beacon chain rewards as a partial withdrawal
  /// @dev This function is used in conjunction with queueWithdrawals and claimQueuedWithdrawals to process a full withdrawal
  /// @dev This function is used in conjunction with claimDelayedWithdrawals to process a partial withdrawal
  function verifyAndProcessWithdrawals(
    uint256 _stakerProxyId,
    uint64 _oracleTimestamp,
    BeaconChainProofs.StateRootProof calldata _stateRootProof,
    BeaconChainProofs.WithdrawalProof[] calldata _withdrawalProofs,
    bytes[] calldata _validatorFieldsProofs,
    bytes32[][] calldata _validatorFields,
    bytes32[][] calldata _withdrawalFields
  ) external checkRole(SwellLib.EIGENLAYER_WITHDRAWALS) {
    address staker = _isValidStaker(_stakerProxyId);
    StakerProxy(payable(staker)).verifyAndProcessWithdrawals(
      _oracleTimestamp,
      _stateRootProof,
      _withdrawalProofs,
      _validatorFieldsProofs,
      _validatorFields,
      _withdrawalFields
    );
  }

  function undelegateStakerFromOperator(
    uint256 _stakerId
  ) external checkRole(SwellLib.EIGENLAYER_DELEGATOR) {
    _undelegateStakerFromOperator(_stakerId);
  }

  function batchUndelegateStakerFromOperator(
    uint256[] calldata _stakerIdArray
  ) external checkRole(SwellLib.EIGENLAYER_DELEGATOR) {
    for (uint256 i; i < _stakerIdArray.length; ) {
      _undelegateStakerFromOperator(_stakerIdArray[i]);
      unchecked {
        ++i;
      }
    }
  }

  function batchWithdrawERC20(
    uint256 _stakeId,
    IERC20[] memory _tokens,
    uint256[] memory _amounts,
    address _recipient
  ) external checkRole(SwellLib.PLATFORM_ADMIN) {
    if (_recipient == address(0)) {
      revert CannotSendToZeroAddress();
    }
    if (_tokens.length != _amounts.length) {
      revert ArrayLengthMismatch();
    }

    address staker = _isValidStaker(_stakeId);
    StakerProxy(payable(staker)).withdrawERC20FromPod(
      _tokens,
      _amounts,
      _recipient
    );
  }

  function registerStakerProxyImplementation(
    address _beacon
  ) external checkRole(SwellLib.PLATFORM_ADMIN) checkZeroAddress(_beacon) {
    if (address(upgradableBeacon) != address(0)) {
      revert AddressAlreadySet();
    }
    upgradableBeacon = _beacon;

    emit StakerProxyRegistered(_beacon);
  }

  function upgradeStakerProxy(
    address _newImplementation
  )
    external
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_newImplementation)
  {
    UpgradeableBeacon(upgradableBeacon).upgradeTo(address(_newImplementation));
    emit StakerProxyUpgraded(_newImplementation);
  }

  // ---

  function _delegateToWithSignature(
    address _staker,
    address _operator,
    IDelegationManager.SignatureWithExpiry calldata _stakerSignatureAndExpiry,
    IDelegationManager.SignatureWithExpiry calldata _approverSignatureAndExpiry,
    bytes32 _approverSalt
  ) internal checkZeroAddress(_staker) checkZeroAddress(_operator) {
    DelegationManager.delegateToBySignature(
      _staker,
      _operator,
      _stakerSignatureAndExpiry,
      _approverSignatureAndExpiry,
      _approverSalt
    );
  }

  function _undelegateStakerFromOperator(uint256 _stakerId) internal {
    address staker = _isValidStaker(_stakerId);
    address operator = DelegationManager.delegatedTo(staker);
    _deleteStakerFromOperatorMapping(operator, _stakerId);
    StakerProxy(payable(staker)).undelegateFromOperator();
  }

  function _createStakerProxy() internal returns (address) {
    BeaconProxy proxy = new BeaconProxy(
      address(upgradableBeacon),
      abi.encodeWithSelector(
        StakerProxy.initialize.selector,
        AccessControlManager,
        DelegationManager,
        EigenPodManager,
        AccessControlManager.DepositManager(),
        address(this)
      )
    );

    emit StakerCreated(address(proxy));

    return address(address(proxy));
  }

  function _isValidStaker(uint256 _id) internal view returns (address) {
    address stakerProxyAddress = stakerProxyAddresses[_id];
    if (stakerProxyAddress == address(0)) {
      revert InvalidStakerId();
    }
    return stakerProxyAddress;
  }

  function _deleteStakerFromOperatorMapping(
    address _operator,
    uint256 _stakerId
  ) internal returns (uint256 foundStakerId) {
    uint256[] storage delegatedStakers = operatorToStakers[_operator];
    for (uint256 i; i < delegatedStakers.length; ) {
      if (delegatedStakers[i] == _stakerId) {
        foundStakerId = delegatedStakers[i];
        delegatedStakers[i] = delegatedStakers[delegatedStakers.length - 1];
        delegatedStakers.pop();
      } else {
        unchecked {
          ++i;
        }
      }
    }
  }
}
