// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IDepositManager
 * @author https://github.com/max-taylor
 * @notice The interface for the deposit manager contract
 */
interface IDepositManager {
  // ***** Errors ******

  /**
   * @dev Error thrown when delegating to an operator who is not registered correctly for EigenLayer
   */
  error OperatorNotVerified();

  /**
   * @dev Error thrown when calling the withdrawETH method from an account that isn't the rswETH contract
   */
  error InvalidETHWithdrawCaller();

  /**
   * @dev Error thrown when the depositDataRoot parameter in the setupValidators contract doesn't match the onchain deposit data root from the deposit contract
   */
  error InvalidDepositDataRoot();

  /**
   * @dev Error thrown when setting up new validators and the contract doesn't hold enough ETH to be able to set them up.
   */
  error InsufficientETHBalance();

  /**
   * @dev Error thrown when an eigen pod has already been created for a user
   */
  error EigenPodMaxLimitReached();

  /**
   * @dev Error thrown when an eigen pod has not already been created
   */
  error EigenPodNotCreated();

  /**
   * @dev Error thrown when no public keys are provided to setupValidators
   */
  error NoPubKeysProvided();

  // ***** Events ******

  /**
   * Emitted when the new EigenLayerPod is created
   * @param eigenPod The address of the new EigenPod
   */
  event EigenPodCreated(address eigenPod);

  /**
   * Emitted when new validators are setup
   * @param pubKeys The pubKeys that have been used for validator setup
   */
  event ValidatorsSetup(bytes[] pubKeys);

  /**
   * @dev Event is fired when some contracts receive ETH
   * @param from The account that sent the ETH
   * @param amount The amount of ETH received
   */
  event ETHReceived(address indexed from, uint256 amount);

  // ************************************
  // ***** External methods ******

  /**
   * @dev This method withdraws contract's _token balance to a platform admin
   * @param _token The ERC20 token to withdraw from the contract
   */
  function withdrawERC20(IERC20 _token) external;

  /**
   * @dev Formats ETH1 the withdrawal credentials according to the following standard: https://github.com/ethereum/consensus-specs/blob/dev/specs/phase0/validator.md#eth1_address_withdrawal_prefix
   * @dev It doesn't outline the withdrawal prefixes, they can be found here: https://eth2book.info/altair/part3/config/constants#withdrawal-prefixes
   * @dev As the EigenPod is going to be the withdrawal contract, we will be doing ETH1 withdrawals. The standard for this is a 32 byte response where; the first byte stores the withdrawal prefix (0x01), the following 11 bytes are empty and the last 20 bytes are the address
   */
  function generateWithdrawalCredentialsForEigenPod() external view returns (bytes memory);
  
  /**
   * @dev This method allows setting up of new validators in the beacon deposit contract, it ensures the provided pubKeys are unused in the NO registry
   * @notice An off-chain service provides front-running protection by validating each pubKey ensuring that it hasn't been used for a validator setup. This service snapshots the depositDataRoot of the deposit contract, then this value is re-read from the deposit contract within setupValdiators() and ensures that they match, this consistency provides the front-running protection. Read more here: https://research.lido.fi/t/mitigations-for-deposit-front-running-vulnerability/1239
   * @param _pubKeys The pubKeys to setup
   * @param _depositDataRoot The deposit contracts deposit root which MUST match the current beacon deposit contract deposit data root otherwise the contract will revert due to the risk of the front-running vulnerability.
   */
  function setupValidators(
    bytes[] calldata _pubKeys,
    bytes32 _depositDataRoot
  ) external;
}
