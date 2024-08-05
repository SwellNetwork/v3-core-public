// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {INodeOperatorRegistry} from "./INodeOperatorRegistry.sol";
import {IEigenLayerManager} from "./IEigenLayerManager.sol";

/**
 * @title IDepositManager
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
   * @dev Error thrown when the transferETHForWithdrawRequests method is called from an account other than rswEXIT
   */
  error OnlyRswEXITCanWithdrawETH();

  /**
   * @dev Error thrown when the transferETHForEigenLayerDeposits method is called from an account other than the EigenLayerManager
   */
  error OnlyEigenLayerManagerCanWithdrawETH();

  /**
   * @dev Error thrown when the transferTokenForDepositIntoStrategy method is called from an account other than the EigenLayerManager
   * @notice This method can only be called by the EigenLayerManager contract
   */
  error OnlyEigenLayerManagerCanWithdrawTokens();

  /**
   * @dev Error thrown when the admin has not set a LST Rate Provider
   */
  error NoRateProviderSet();

  /**
   * @dev Error thrown when a user tries to deposit an amount of zero
   */
  error CannotDepositZero();

  /**
   * @dev Error thrown when no public keys have been provided for validator setup
   */
  error NoPubKeysProvided();

  /**
   * @dev Error thrown when the EigenPod has not been created
   */
  error EigenPodNotCreated();

  // ***** Events ******
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

  /**
   * @dev Event fired when the admin succesfully sets an exchange rate provider
   * @param token The address of the LST for which the exchange rate provider provides a rate
   * @param exchangeRateProvider The address of the exchange rate provider contract
   */
  event ExchangeRateProviderSet(
    address indexed token,
    address indexed exchangeRateProvider
  );

  /**
   * @dev Event is fired when the DepositManager sends ETH, this will currently only happen when rswEXIT calls transferETHForWithdrawRequests to get ETH for fulfill withdraw requests
   * @param to The account that is receiving the ETH
   * @param amount The amount of ETH sent
   */
  event EthSent(address indexed to, uint256 amount);

  /**
   * @dev Event fired when a user succesfully deposits an LST's into the Swell Deposit Manager
   * @param token The address of the LST deposited
   * @param tokenAmount The amount of the LST deposited
   */
  event LSTDeposited(address indexed token, uint256 tokenAmount);

  /**
   * @dev Event fired when the admin succesfully sets the EigenLayerManager contract
   * @param eigenLayerManager The address of the EigenLayerManager contract
   */
  event EigenLayerManagerSet(address eigenLayerManager);

  // ************************************

  // ***** External methods ******


  /**
   * @return The address of the EigenLayerManager contract
   */
  function eigenLayerManager() external view returns (IEigenLayerManager);

  /**
   * @dev Allows the admin to set the EigenLayer staking admin contract
   * @param _eigenLayerManager The address of the EigenLayerManager contract
   * @notice This method can only be called by the admin
   */
  function setEigenLayerManager(address _eigenLayerManager) external;
  
  /**
   * @dev This method is called by rswEXIT when it needs ETH to fulfill withdraw requests
   * @param _amount The amount of ETH to transfer to rswEXIT
   */
  function transferETHForWithdrawRequests(uint256 _amount) external;

  /**
   * @dev This method is called by the EigenLayerManager contract when it needs ETH to fulfill deposit requests onto EigenLayer
   * @param _pubKeys An array of public keys for operators registered on the Swell Network
   * @param _depositDataRoot The deposit data root
   * @return An array of ValidatorDetails
   */
  function transferETHForEigenLayerDeposits(
    bytes[] calldata _pubKeys,
    bytes32 _depositDataRoot
  ) external returns (INodeOperatorRegistry.ValidatorDetails[] memory);

  /**
   * @dev This method is called by the EigenLayerManager contract when it needs to transfer tokens to a StakerProxy to deposit into a strategy
   * @param _token The ERC20 token to transfer
   * @param _amount The amount of tokens to transfer
   * @param _stakerProxyAddress The address of the staker proxy contract who will receive the tokens to deposit
   */
  function transferTokenForDepositIntoStrategy(
    address _token,
    uint256 _amount,
    address _stakerProxyAddress
  ) external;

  /**
   * @dev This method withdraws the Deposit Manager contract's _token balance to a platform admin
   * @param _token The ERC20 token to withdraw from the contract
   */
  function withdrawERC20(IERC20 _token) external;

  /**
   * @dev Allows Users to Deposit liquid staking tokens into Swell Deposit Manager.
   * @param _token The LST token address.
   * @param _amount The amount of LST to deposit.
   * @param _minRswETH The minimum amount of RswETH to receive for the LST deposited.
   */
  function depositLST(address _token, uint256 _amount, uint256 _minRswETH) external;
}
