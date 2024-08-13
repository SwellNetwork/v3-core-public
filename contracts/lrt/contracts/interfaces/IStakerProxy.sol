// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IStrategy} from "../vendors/contracts/interfaces/IStrategy.sol";
import {BeaconChainProofs} from "../vendors/contracts/libraries/BeaconChainProofs.sol";
import {IDelegationManager} from "../vendors/contracts/interfaces/IDelegationManager.sol";

interface IStakerProxy {
  // ***** Errors ******

  /**
   * @dev Error thrown when caller is not the Swell Deposit Manager
   */
  error NotDepositManager();

  /**
   * @dev Error thrown when array lengths dont match
   */
  error ArrayLengthMismatch();

  /**
   * @dev Error thrown when ETH transfer to the Deposit Manager fails
   */
  error ETHTransferFailed();

  /**
   * @dev Error thrown when ERC20 token transfer to the Deposit Manager fails
   */
  error ERC20TransferFailed();

  /**
   * @dev Error thrown when caller is not the EigenLayerManager
   */
  error NotEigenLayerManager();

  // ***** Functions ******

  /**
   * @return The address of the EigenPod owned by this contract
   */
  function eigenPod() external view returns (address);

  /**
   * @dev Generate withdrawal credentials for the EigenPod
   * @return The withdrawal credentials (concat of 0x01 prefix and the address of the eigenpod)
   */
  function generateWithdrawalCredentialsForEigenPod()
    external
    view
    returns (bytes memory);

  /**
   * @dev Get the amount of non-staked ETH on the Beacon Chain
   * @return The amount of non-staked ETH
   */
  function getAmountOfNonBeaconChainEth() external view returns (uint256);

  /**
   * @dev Stake ETH on the EigenLayer
   * @param _pubKeys The public keys of the validators
   * @param _signatures The signatures of the validators
   */
  function stakeOnEigenLayer(
    bytes calldata _pubKeys,
    bytes calldata _signatures
  ) external payable;

  /**
   * @dev Deposit ERC20 tokens into a strategy
   * @param currentStrategy The current strategy
   * @param token The token to deposit
   * @param _amount The amount to deposit
   */
  function depositIntoStrategy(
    IStrategy currentStrategy,
    IERC20 token,
    uint256 _amount
  ) external;

  /**
   * @dev Undelegate from the operator
   * @return withdrawalRoots The withdrawal roots
   */
  function undelegateFromOperator()
    external
    returns (bytes32[] memory withdrawalRoots);

  /**
   * @dev Withdraw non-staked ETH from the Beacon Chain
   * @param _recipient The recipient of the ETH
   * @param _amount The amount of ETH to withdraw
   */
  function withdrawNonStakedBeaconChainEth(
    address _recipient,
    uint256 _amount
  ) external;

  /**
   * @dev Withdraw ERC20 tokens from the EigenPod
   * @param _tokens The tokens to withdraw
   * @param _amounts The amounts to withdraw
   * @param _recipient The recipient of the tokens
   */
  function withdrawERC20FromPod(
    IERC20[] memory _tokens,
    uint256[] memory _amounts,
    address _recipient
  ) external;

  /**
   * @dev Verify the withdrawal credentials of validator(s) owned by the pod owner are pointing to the eigenpod.
   * @param _oracleTimestamp is the Beacon Chain timestamp whose state root the `proof` will be proven against.
   * @param _stateRootProof proves a `beaconStateRoot` against a block root fetched from the oracle
   * @param _validatorIndices is the list of indices of the validators being proven, refer to consensus specs
   * @param _validatorFieldsProofs proofs against the `beaconStateRoot` for each validator in `validatorFields`
   * @param _validatorFields are the fields of the "Validator Container", refer to consensus specs
   * for details: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/beacon-chain.md#validator
   */
  function verifyPodWithdrawalCredentials(
    uint64 _oracleTimestamp,
    BeaconChainProofs.StateRootProof calldata _stateRootProof,
    uint40[] calldata _validatorIndices,
    bytes[] calldata _validatorFieldsProofs,
    bytes32[][] calldata _validatorFields
  ) external;

  /**
   * @dev Verify and process withdrawals
   * @param _oracleTimestamp is the timestamp of the oracle slot that the withdrawal is being proven against
   * @param _stateRootProof proves a `beaconStateRoot` against a block root fetched from the oracle
   * @param _withdrawalProofs proves several withdrawal-related values against the `beaconStateRoot`
   * @param _validatorFieldsProofs proves `validatorFields` against the `beaconStateRoot`
   * @param _withdrawalFields are the fields of the withdrawals being proven
   * @param _validatorFields are the fields of the validators being proven
   */
  function verifyAndProcessWithdrawals(
    uint64 _oracleTimestamp,
    BeaconChainProofs.StateRootProof calldata _stateRootProof,
    BeaconChainProofs.WithdrawalProof[] calldata _withdrawalProofs,
    bytes[] calldata _validatorFieldsProofs,
    bytes32[][] calldata _validatorFields,
    bytes32[][] calldata _withdrawalFields
  ) external;

  /**
   * @dev Queue withdrawal of shares from a strategy
   * @param _queuedWithdrawalParams The queued withdrawal params (struct containing array of strategies, array of shares and the address of the withdrawer).
   * @return withdrawalRoots The withdrawal roots
   */
  function queueWithdrawals(
    IDelegationManager.QueuedWithdrawalParams[] calldata _queuedWithdrawalParams
  ) external returns (bytes32[] memory);

  /**
   * @dev Complete a queued withdrawal
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
    IDelegationManager.Withdrawal calldata _withdrawal,
    IERC20[] calldata _tokens,
    uint256 _middlewareTimesIndex,
    bool _receiveAsTokens
  ) external;

  /**
   * @dev Send funds to the Deposit Manager
   * @notice Only callable by the BOT
   */
  function sendFundsToDepositManager() external;

  /**
   * @dev Send ERC20 tokens to the Deposit Manager
   * @param _token The token to send
   * @notice Only callable by the BOT
   */
  function sendTokenBalanceToDepositManager(IERC20 _token) external;
}
