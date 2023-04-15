// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SwETH Interface
 * @author https://github.com/max-taylor
 * @dev This interface provides the methods to interact with the SwETH contract.
 */
interface IswETH is IERC20Upgradeable {
  // ***** Errors ******

  /**
   * @dev Error thrown when attempting to reprice with zero SwETH supply.
   */
  error CannotRepriceWithZeroSwETHSupply();

  /**
   * @dev Error thrown when passing a preRewardETHReserves value equal to 0 into the repricing function
   */
  error InvalidPreRewardETHReserves();

  /**
   * @dev Error thrown when repricing the rate and distributing rewards to NOs when they are no active validators. This condition should never happen; it means that no active validators were running but we still have rewards, despite this it's still here for security
   */
  error NoActiveValidators();

  /**
   * @dev Error thrown when updating the reward percentage for either the NOs or the swell treasury and the update will cause the NO percentage + swell treasury percentage to exceed 100%.
   */
  error RewardPercentageTotalOverflow();

  /**
   * @dev Thrown when calling the reprice function and not enough time has elapsed between the previous repriace and the current reprice.
   * @param remainingTime Remaining time until reprice can be called
   */
  error NotEnoughTimeElapsedForReprice(uint256 remainingTime);

  /**
   * @dev Thrown when repricing the rate and the difference in reserves values is greater than expected
   * @param repriceDiff The difference between the previous swETH rate and what would be the updated rate
   * @param maximumRepriceDiff The maximum allowed difference in swETH rate
   */
  error RepriceDifferenceTooLarge(
    uint256 repriceDiff,
    uint256 maximumRepriceDiff
  );

  /**
   * @dev Thrown during repricing when the difference in swETH supplied to repricing compared to the actual supply is too great
   * @param repriceswETHDiff The difference between the swETH supplied to repricing and actual supply
   * @param maximumswETHRepriceDiff The maximum allowed difference in swETH supply
   */
  error RepriceswETHDifferenceTooLarge(
    uint256 repriceswETHDiff,
    uint256 maximumswETHRepriceDiff
  );

  // ***** Events *****

  /**
   * @dev Event emitted when a user withdraws ETH for swETH
   * @param to Address of the recipient.
   * @param swETHBurned Amount of SwETH burned in the transaction.
   * @param ethReturned Amount of ETH returned in the transaction.
   */
  event ETHWithdrawn(
    address indexed to,
    uint256 swETHBurned,
    uint256 ethReturned
  );

  /**
   * @dev Event emitted when the swell treasury reward percentage is updated.
   * @dev Only callable by the platform admin
   * @param oldPercentage The previous swell treasury reward percentage.
   * @param newPercentage The new swell treasury reward percentage.
   */
  event SwellTreasuryRewardPercentageUpdate(
    uint256 oldPercentage,
    uint256 newPercentage
  );

  /**
   * @dev Event emitted when the node operator reward percentage is updated.
   * @dev Only callable by the platform admin
   * @param oldPercentage The previous node operator reward percentage.
   * @param newPercentage The new node operator reward percentage.
   */
  event NodeOperatorRewardPercentageUpdate(
    uint256 oldPercentage,
    uint256 newPercentage
  );

  /**
   * @dev Event emitted when the swETH - ETH rate is updated
   * @param newEthReserves The new ETH reserves for the swell protocol
   * @param newSwETHToETHRate The new SwETH to ETH rate.
   * @param nodeOperatorRewards The rewards for the node operator's.
   * @param swellTreasuryRewards The rewards for the swell treasury.
   * @param totalETHDeposited Current total ETH staked at time of reprice.
   */
  event Reprice(
    uint256 newEthReserves,
    uint256 newSwETHToETHRate,
    uint256 nodeOperatorRewards,
    uint256 swellTreasuryRewards,
    uint256 totalETHDeposited
  );

  /**
   * @dev Event is fired when some contracts receive ETH
   * @param from The account that sent the ETH
   * @param swETHMinted The amount of swETH minted to the caller
   * @param amount The amount of ETH received
   */
  event ETHDepositReceived(
    address indexed from,
    uint256 amount,
    uint256 swETHMinted,
    uint256 newTotalETHDeposited
  );

  /**
   * @dev Event emitted on a successful call to setMinimumRepriceTime
   * @param _oldMinimumRepriceTime The old reprice time
   * @param _newMinimumRepriceTime The new updated reprice time
   */
  event MinimumRepriceTimeUpdated(
    uint256 _oldMinimumRepriceTime,
    uint256 _newMinimumRepriceTime
  );

  /**
   * @dev Event emitted on a successful call to setMaximumRepriceswETHDifferencePercentage
   * @param _oldMaximumRepriceswETHDifferencePercentage The old maximum swETH supply difference
   * @param _newMaximumRepriceswETHDifferencePercentage The new updated swETH supply difference
   */
  event MaximumRepriceswETHDifferencePercentageUpdated(
    uint256 _oldMaximumRepriceswETHDifferencePercentage,
    uint256 _newMaximumRepriceswETHDifferencePercentage
  );

  /**
   * @dev Event emitted on a successful call to setMaximumRepriceDifferencePercentage
   * @param _oldMaximumRepriceDifferencePercentage The old maximum reprice difference
   * @param _newMaximumRepriceDifferencePercentage The new updated maximum reprice difference
   */
  event MaximumRepriceDifferencePercentageUpdated(
    uint256 _oldMaximumRepriceDifferencePercentage,
    uint256 _newMaximumRepriceDifferencePercentage
  );

  // ************************************
  // ***** External Methods ******

  /**
   * @dev This method withdraws contract's _token balance to a platform admin
   * @param _token The ERC20 token to withdraw from the contract
   */
  function withdrawERC20(IERC20 _token) external;

  /**
   * @dev Returns the ETH reserves that were provided in the most recent call to the reprice function
   * @return The last recorded ETH reserves
   */
  function lastRepriceETHReserves() external returns (uint256);

  /**
   * @dev Returns the last time the reprice method was called in UNIX
   * @return The UNIX timestamp of the last time reprice was called
   */
  function lastRepriceUNIX() external returns (uint256);

  /**
   * @dev Returns the total ETH that has been deposited over the protocols lifespan
   * @return The current total amount of ETH that has been deposited
   */
  function totalETHDeposited() external returns (uint256);

  /**
   * @dev Returns the current swell treasury reward percentage.
   * @return The current swell treasury reward percentage.
   */
  function swellTreasuryRewardPercentage() external returns (uint256);

  /**
   * @dev Returns the current node operator reward percentage.
   * @return The current node operator reward percentage.
   */
  function nodeOperatorRewardPercentage() external returns (uint256);

  /**
   * @dev Returns the current SwETH to ETH rate, returns 1:1 if no reprice has occurred otherwise it returns the swETHToETHRateFixed rate.
   * @return The current SwETH to ETH rate.
   */
  function swETHToETHRate() external returns (uint256);

  /**
   * @dev Returns the current ETH to SwETH rate.
   * @return The current ETH to SwETH rate.
   */
  function ethToSwETHRate() external returns (uint256);

  /**
   * @dev Returns the minimum reprice time
   * @return The minimum reprice time
   */
  function minimumRepriceTime() external returns (uint256);

  /**
   * @dev Returns the maximum percentage difference with 1e18 precision
   * @return The maximum percentage difference
   */
  function maximumRepriceDifferencePercentage() external returns (uint256);

  /**
   * @dev Returns the maximum percentage difference with 1e18 precision
   * @return The maximum percentage difference in suppled and actual swETH supply
   */
  function maximumRepriceswETHDifferencePercentage() external returns (uint256);

  /**
   * @dev Sets the new swell treasury reward percentage.
   * @notice Only a platform admin can call this function.
   * @param _newSwellTreasuryRewardPercentage The new swell treasury reward percentage to set.
   */
  function setSwellTreasuryRewardPercentage(
    uint256 _newSwellTreasuryRewardPercentage
  ) external;

  /**
   * @dev Sets the new node operator reward percentage.
   * @notice Only a platform admin can call this function.
   * @param _newNodeOperatorRewardPercentage The new node operator reward percentage to set.
   */
  function setNodeOperatorRewardPercentage(
    uint256 _newNodeOperatorRewardPercentage
  ) external;

  /**
   * @dev Sets the minimum permitted time between successful repricing calls using the block timestamp.
   * @notice Only a platform admin can call this function.
   * @param _minimumRepriceTime The new minimum time between successful repricing calls
   */
  function setMinimumRepriceTime(uint256 _minimumRepriceTime) external;

  /**
   * @dev Sets the maximum percentage allowable difference in swETH supplied to repricing compared to current swETH supply.
   * @notice Only a platform admin can call this function.
   * @param _maximumRepriceswETHDifferencePercentage The new maximum percentage swETH supply difference allowed.
   */
  function setMaximumRepriceswETHDifferencePercentage(
    uint256 _maximumRepriceswETHDifferencePercentage
  ) external;

  /**
   * @dev Sets the maximum percentage allowable difference in swETH to ETH price changes for a repricing call.
   * @notice Only a platform admin can call this function.
   * @param _maximumRepriceDifferencePercentage The new maximum percentage difference in repricing rate.
   */
  function setMaximumRepriceDifferencePercentage(
    uint256 _maximumRepriceDifferencePercentage
  ) external;

  /**
   * @dev Deposits ETH into the contract
   * @notice The amount of ETH deposited will be converted to SwETH at the current SwETH to ETH rate
   */
  function deposit() external payable;

  /**
  //  * TODO: Reword
   * @dev This method reprices the swETH -> ETH rate, this will be called via an offchain service on a regular interval, likely ~1 day. The swETH total supply is passed as an argument to avoid a potential race conditions between the off-chain reserve calculations and the on-chain repricing
   * @dev This method also mints a percentage of swETH as rewards to be claimed by NO's and the swell treasury. The formula for determining the amount of swETH to mint is the following: swETHToMint = (swETHSupply * newETHRewards * feeRate) / (preRewardETHReserves - newETHRewards * feeRate + newETHRewards)
   * @dev The formula is quite complicated because it needs to factor in the updated exchange rate whilst it calculates the amount of swETH rewards to mint. This ensures the rewards aren't double-minted and are backed by ETH.
   * @param _preRewardETHReserves The PoR value exclusive of the new ETH rewards earned
   * @param _newETHRewards The total amount of new ETH earnt over the period.
   * @param _swETHTotalSupply The total swETH supply at the time of off-chain reprice calculation
   */
  function reprice(
    uint256 _preRewardETHReserves,
    uint256 _newETHRewards,
    uint256 _swETHTotalSupply
  ) external;
}
