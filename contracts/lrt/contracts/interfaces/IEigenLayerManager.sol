// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IDelegationManager} from "../vendors/contracts/interfaces/IDelegationManager.sol";
import {IEigenPodManager} from "../vendors/contracts/interfaces/IEigenPodManager.sol";
import {BeaconChainProofs} from "../vendors/contracts/libraries/BeaconChainProofs.sol";
import {IDelayedWithdrawalRouter} from "../vendors/contracts/interfaces/IDelayedWithdrawalRouter.sol";
import {IStrategy} from "../vendors/contracts/interfaces/IStrategy.sol";

/**
 * @title IEigenLayerManager
 * @notice The interface for the EigenLayerManager contract
 */
interface IEigenLayerManager {
  // ***** Errors ******
  /**
   * @dev Error thrown when an admin passes an invalid staker Id
   */
  error InvalidStakerId();

  /**
   * @dev Error thrown when batch creating a staker and its pod with a batch size of zero.
   */
  error BatchSizeCannotBeZero();

  /**
   * @dev Error thrown when array lengths dont match.
   */
  error ArrayLengthMismatch();

  /**
   * @dev Error thrown when trying to send to the zero address.
   */
  error CannotSendToZeroAddress();

  /**
   * @dev Error thrown when stakerProxy implementation address already set.
   */
  error AddressAlreadySet();

  /**
   * @dev Error thrown when trying to deposit zero amount into a strategy
   */
  error CannotDepositZero();

  /**
   * @dev Error thrown when a token address does not match a Strategy's underlying token.
   */
  error StrategyTokenMismatch();

  /**
   * @dev Error thrown when a strategy is not set for a token.
   */
  error StrategyNotSet();

  /**
   * @dev Error thrown when a staker is still delegated to an operator during manual unassignment.
   */
  error StakerIsStillDelegatedToOperator();

  /**
   * @dev Error thrown when a staker was not found in an operator's staker list during manual unassignment.
   */
  error StakerNotFoundInOperatorStakerList();

  /**
   * @dev Error thrown when a staker is already assigned to an operator during manual assignment.
   */
  error StakerIsAlreadyAssignedToOperator();

  /**
   * @dev Error thrown when a staker is not delegated to an operator during manual assignment.
   */
  error StakerIsNotDelegatedToOperator();

  // ***** Events ******

  /**
   * @dev Event fired when an admin succesfully updates the signer address used for delegation
   * @param oldSigner The address of the old admin signer
   * @param newSigner The address of the new admin signer
   */
  event AdminSignerUpdated(address oldSigner, address newSigner);

  /**
   * @dev Event fired when a stakerProxy is successfully created
   * @param stakerProxyAddress The address of the created stakerProxy contract
   */
  event StakerCreated(address stakerProxyAddress);

  /**
   * @dev Event fired when the DelayedWithdrawalRouter is set.
   * @param delayedWithdrawalRouter The address of the DelayedWithdrawalRouter contract
   */
  event DelayedWithdrawalRouterSet(address delayedWithdrawalRouter);

  /**
   * @dev Event fired when the StrategyManager contract is set.
   * @param strategyManager The address of the StrategyManager contract
   */
  event StrategyManagerAddressSet(address strategyManager);

  /**
   * @dev Event fired when the DelegationManager contract is set.
   * @param _delegationManager The address of the DelegationManager contract
   */
  event DelegationManagerSet(address _delegationManager);

  /**
   * Emitted when new validators are setup on EigenLayer
   * @param stakerIds The IDs of the stakerProxy contracts used for validator setup
   * @param pubKeys The pubKeys that have been used for validator setup
   */
  event ValidatorsSetupOnEigenLayer(uint256[] stakerIds, bytes[] pubKeys);

  /**
   * @dev Event fired when the admin succesfully deposits LST's into an Eigen Layer Strategy
   * @param amount The amount of the LST deiposited into the Eigen Layer strategy
   * @param token The address of the LST deposited
   * @param currentStrategy The interface of the Eigen Layer strategy the LST was deposited into
   */
  event DepositedIntoStrategy(
    uint256 amount,
    address token,
    IStrategy currentStrategy
  );

  /**
   * Emitted when a stakerProxy contract is successfully registered
   * @param beacon The address of the beacon contract
   */
  event StakerProxyRegistered(address beacon);

  /**
   * Emitted when a stakerProxy contract is successfully upgraded to a new implementation
   * @param newImplementation The address of the new implementation contract
   */
  event StakerProxyUpgraded(address newImplementation);

  /**
   * @dev Event is fired when some contracts receive ETH
   * @param from The account that sent the ETH
   * @param amount The amount of ETH received
   */
  event ETHReceived(address indexed from, uint256 amount);

  /**
   * @dev Event fired when the admin succesfully sets the Eigen Layer strategy for a LST
   * @param token The address of the LST for which corresponds to the Eigen Layer strategy
   * @param strategy The address Eigen Layer strategy contract for the above LST
   */
  event StrategySetAndApproved(address indexed token, address indexed strategy);

  /**
   * @dev Event fired when a staker is manually unassigned from an operator.
   * @param stakerId The ID of the stakerProxy contract
   * @param operator The address of the operator
   */
  event StakerUnassignedFromOperator(uint256 stakerId, address operator);

  /**
   * @dev Event fired when a staker is manually assigned to an operator.
   * @param stakerId The ID of the stakerProxy contract
   * @param operator The address of the operator
   */
  event StakerAssignedToOperator(uint256 stakerId, address operator);

  // ************************************
  // ***** External methods ******

  /**
   * @dev Returns the address of the EigenLayer DelegationManager contract.
   * @return The address of the DelegationManager contract.
   */
  function DelegationManager() external view returns (IDelegationManager);

  /**
   * @dev Returns the address of the DelayedWithdrawalRouter contract.
   * @return The address of the DelayedWithdrawalRouter contract.
   */
  function DelayedWithdrawalRouter()
    external
    view
    returns (IDelayedWithdrawalRouter);

  /**
   * @dev Returns the address of the EigenPodManager contract.
   * @return The address of the EigenPodManager contract.
   */
  function EigenPodManager() external view returns (IEigenPodManager);

  /**
   * @dev Returns the address of the StrategyManager contract.
   * @return The address of the StrategyManager contract.
   */
  function strategyManagerAddress() external view returns (address);

  /**
   * @dev Returns the address of the admin signer.
   * @return The address of the admin signer.
   */
  function adminSigner() external view returns (address);

  /**
   * @dev Returns the latest stakeId assigned to a stakerProxy contract.
   * @return The latest stakeId.
   */
  function stakeId() external view returns (uint256);

  /**
   * @dev A mapping of token addresses to their corresponding EigenLayer strategy.
   * @param _token The address of the token.
   * @return The address of the strategy.
   */
  function tokenToStrategy(address _token) external view returns (address);

  /**
   * @dev A mapping of operator addresses to associated stakerProxy Ids.
   * @param _operator The address of the operator.
   * @return An array of stakerProxy Ids.
   */
  function getDelegatedStakers(
    address _operator
  ) external view returns (uint256[] memory);

  /**
   * @dev Returns the stakerProxy address for a given staker ID.
   * @notice Reverts if the staker ID is invalid.
   * @param _stakerId The ID of the staker.
   * @return stakerProxy The address of the stakerProxy contract.
   */
  function isValidStaker(
    uint256 _stakerId
  ) external view returns (address stakerProxy);

  /**
   * @dev Returns the stakerProxy address for a given staker ID.
   * @param _stakerId The ID of the staker.
   * @return stakerProxy The address of the stakerProxy contract.
   */
  function stakerProxyAddresses(
    uint256 _stakerId
  ) external view returns (address stakerProxy);

  /**
   * @dev Sets the StrategyManager contract address.
   * @param _strategyManager The address of the StrategyManager contract.
   */
  function setStrategyManager(address _strategyManager) external;

  /**
   * @dev Sets the admin signer address.
   * @param _adminSigner The address of the admin signer.
   */
  function setAdminSigner(address _adminSigner) external;

  /**
   * @dev Sets the DelayedWithdrawalRouter contract address.
   * @param _delayedWithdrawalRouter The address of the DelayedWithdrawalRouter contract.
   */
  function setDelayedWithdrawalRouter(
    address _delayedWithdrawalRouter
  ) external;

  /**
   * @dev Sets the DelegationManager contract address.
   * @param _delegationManager The address of the DelegationManager contract.
   */
  function setDelegationManager(address _delegationManager) external;

  /**
   * @dev Allows a Swell Admin to set the Eigen Layer Strategy for a given token.
   * @param _token The address of the token.
   * @param _strategy The address of the strategy.
   */
  function setEigenLayerStrategy(address _token, address _strategy) external;

  /**
   * @dev Stake on the EigenLayer network.
   * @param _stakerIds An array of stakerProxy Ids.
   * @param _pubKeys An array of public keys for operators registered on the Swell Network.
   * @param _depositDataRoot The deposit data root.
   */
  function stakeOnEigenLayer(
    uint256[] calldata _stakerIds,
    bytes[] calldata _pubKeys,
    bytes32 _depositDataRoot
  ) external;

  /**
   * @dev Allows a Swell Admin to Deposit liquid staking tokens into an Eigen Layer Strategy.
   * @param _stakerId The Id if the stakerProxy contract to deposit on behalf of.
   * @param _amount The amount of LST's to deposit.
   * @param _token The LST token address.
   */
  function depositIntoEigenLayerStrategy(
    uint256 _stakerId,
    uint256 _amount,
    address _token
  ) external;

  /**
   * @dev Delegates the staker's Eigen Layer shares to the specified operator using the provided signatures and expiry times.
   * @param _stakerId The Id of the stakerProxy contract.
   * @param _operator The address of the operator.
   * @param _stakerSignatureAndExpiry A struct containing the staker's signature and expiry time.
   * @param _approverSignatureAndExpiry A struct containing the approver's signature and expiry time.
   * @param _approverSalt A unique salt value used for the approver's signature.
   */
  function delegateToWithSignature(
    uint256 _stakerId,
    address _operator,
    IDelegationManager.SignatureWithExpiry calldata _stakerSignatureAndExpiry,
    IDelegationManager.SignatureWithExpiry calldata _approverSignatureAndExpiry,
    bytes32 _approverSalt
  ) external;

  /**
   * @dev Batch delegates multiple stakers to multiple operators using their signatures and expiry times.
   * @param stakerIds An array of stakerProxy Ids.
   * @param operatorArray An array of operator addresses.
   * @param stakerSignatureAndExpiryArray An array of SignatureWithExpiry structs containing staker signatures and expiry times.
   * @param approverSignatureAndExpiryArray An array of SignatureWithExpiry structs containing approver signatures and expiry times.
   * @param approverSaltArray An array of salts used for the approver signatures.
   */
  function batchDelegateToWithSignature(
    uint256[] calldata stakerIds,
    address[] calldata operatorArray,
    IDelegationManager.SignatureWithExpiry[]
      calldata stakerSignatureAndExpiryArray,
    IDelegationManager.SignatureWithExpiry[]
      calldata approverSignatureAndExpiryArray,
    bytes32[] calldata approverSaltArray
  ) external;

  /**
   * @dev Manually unassigns a staker from an operator.
   * @dev This is a cleanup function which requires that the staker is undelegated on EigenLayer. This can occur when the operator or their delegation approver forces one of their delegated stakers to undelegate.
   * @param _stakerId The ID of the staker to unassign.
   * @param _operator The address of the operator.
   */
  function unassignStakerFromOperator(
    uint256 _stakerId,
    address _operator
  ) external;

  /**
   * @dev Manually assigns a staker to an operator.
   * @dev This is a cleanup function which requires that the staker is delegated on EigenLayer. This can occur when a staker is delegated to an operator directly via DelegationManager.
   * @param stakerId The ID of the staker to assign.
   * @param operator The address of the operator.
   */
  function assignStakerToOperator(uint256 stakerId, address operator) external;

  /**
   * @dev Queues multiple withdrawals for a staker proxy.
   * @param _stakerProxyId The ID of the staker proxy.
   * @param _queuedWithdrawalParams An array of QueuedWithdrawalParams struct containing withdrawal details.
   * @return An array of bytes32 representing the withdrawal roots.
   */
  function queueWithdrawals(
    uint256 _stakerProxyId,
    IDelegationManager.QueuedWithdrawalParams[] calldata _queuedWithdrawalParams
  ) external returns (bytes32[] memory);

  /**
   * @dev Complete a queued withdrawal via a StakerProxy
   * @param _stakerProxyId The ID of the staker proxy.
   * @param _withdrawal The Withdrawal to complete.
   * @param _tokens Array in which the i-th entry specifies the `token` input to the 'withdraw' function of the i-th Strategy in the `withdrawal.strategies` array.
   * This input can be provided with zero length if `receiveAsTokens` is set to 'false' (since in that case, this input will be unused)
   * @param _middlewareTimesIndex is the index in the operator that the staker who triggered the withdrawal was delegated to's middleware times array
   * @param _receiveAsTokens If true, the shares specified in the withdrawal will be withdrawn from the specified strategies themselves
   * and sent to the caller, through calls to `withdrawal.strategies[i].withdraw`. If false, then the shares in the specified strategies
   * will simply be transferred to the caller directly.
   * @dev middlewareTimesIndex should be calculated off chain before calling this function by finding the first index that satisfies `slasher.canWithdraw`
   * @dev beaconChainETHStrategy shares are non-transferrable, so if `receiveAsTokens = false` and `withdrawal.withdrawer != withdrawal.staker`, note that
   * any beaconChainETHStrategy shares in the `withdrawal` will be _returned to the staker_, rather than transferred to the withdrawer, unlike shares in
   * any other strategies, which will be transferred to the withdrawer.
   */
  function completeQueuedWithdrawal(
    uint256 _stakerProxyId,
    IDelegationManager.Withdrawal calldata _withdrawal,
    IERC20[] calldata _tokens,
    uint256 _middlewareTimesIndex,
    bool _receiveAsTokens
  ) external;

  /**
   * @dev This function is used to claim partial withdrawals on behalf of the recipient after the withdrawal delay has passed.
   * @param _recipient The address of the recipient to claim the withdrawals for.
   * @param _maxNumberOfWithdrawalsToClaim The maximum number of withdrawals to claim.
   */
  function claimDelayedWithdrawals(
    address _recipient,
    uint256 _maxNumberOfWithdrawalsToClaim
  ) external;

  /**
   * @dev  For a staker proxy: Verify the withdrawal credentials of validator(s) owned by the pod owner are pointing to the eigenpod.
   * @param _stakerProxyId is the ID of the staker proxy contract
   * @param _oracleTimestamp is the Beacon Chain timestamp whose state root the `proof` will be proven against.
   * @param _stateRootProof proves a `beaconStateRoot` against a block root fetched from the oracle
   * @param _validatorIndices is the list of indices of the validators being proven, refer to consensus specs
   * @param _validatorFieldsProofs proofs against the `beaconStateRoot` for each validator in `validatorFields`
   * @param _validatorFields are the fields of the "Validator Container", refer to consensus specs
   * for details: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#validator
   */
  function verifyPodWithdrawalCredentials(
    uint256 _stakerProxyId,
    uint64 _oracleTimestamp,
    BeaconChainProofs.StateRootProof calldata _stateRootProof,
    uint40[] calldata _validatorIndices,
    bytes[] calldata _validatorFieldsProofs,
    bytes32[][] calldata _validatorFields
  ) external;

  /**
   * @dev Verifies and processes withdrawals for a staker proxy.
   * @param _stakerProxyId The ID of the staker proxy.
   * @param _oracleTimestamp The timestamp provided by the oracle.
   * @param _stateRootProof The proof of the state root.
   * @param _withdrawalProofs An array of withdrawal proofs.
   * @param _validatorFieldsProofs An array of validator fields proofs.
   * @param _validatorFields An array of validator fields.
   * @param _withdrawalFields An array of withdrawal fields.
   */
  function verifyAndProcessWithdrawals(
    uint256 _stakerProxyId,
    uint64 _oracleTimestamp,
    BeaconChainProofs.StateRootProof calldata _stateRootProof,
    BeaconChainProofs.WithdrawalProof[] calldata _withdrawalProofs,
    bytes[] calldata _validatorFieldsProofs,
    bytes32[][] calldata _validatorFields,
    bytes32[][] calldata _withdrawalFields
  ) external;

  /**
   * @dev Undelegates a staker from an operator.
   * @param _stakerId The ID of the staker to undelegate.
   */
  function undelegateStakerFromOperator(uint256 _stakerId) external;

  /**
   * @dev Batch undelegates multiple stakers from their associated operators.
   * @param _stakerIdArray An array of staker IDs to undelegate.
   */
  function batchUndelegateStakerFromOperator(
    uint256[] calldata _stakerIdArray
  ) external;

  /**
   * @dev Batch withdraws ERC20 tokens from a specific staker's pod.
   * @param _stakeId The ID of the stake.
   * @param _tokens An array of ERC20 tokens to withdraw.
   * @param _amounts An array of amounts to withdraw for each token.
   * @param _recipient The address to receive the withdrawn tokens.
   */
  function batchWithdrawERC20(
    uint256 _stakeId,
    IERC20[] memory _tokens,
    uint256[] memory _amounts,
    address _recipient
  ) external;

  /**
   * @dev Allows a Swell Admin to create a batch of stakerProxy contracts with associated Eigen Pods.
   * @param _batchSize The amount of stakerProxy contracts to create.
   */
  function createStakerAndPod(uint256 _batchSize) external;

  /**
   * @dev Registers the implementation of the StakerProxy contract.
   * @param _beacon The address of the beacon contract.
   */
  function registerStakerProxyImplementation(address _beacon) external;

  /**
   * @dev Upgrades the StakerProxy contract to a new implementation.
   * @param _newImplementation The address of the new implementation contract.
   */
  function upgradeStakerProxy(address _newImplementation) external;
}
