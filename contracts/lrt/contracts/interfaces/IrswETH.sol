// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RswETH Interface
 * @dev This interface provides the methods to interact with the RswETH contract.
 */
interface IrswETH is IERC20Upgradeable {
  // ***** Errors ******

  /**
   * @dev Error thrown when attempting to reprice with zero RswETH supply.
   */
  error CannotRepriceWithZeroRswETHSupply();

  /**
   * @dev Error thrown when passing a preRewardETHReserves value equal to 0 into the repricing function
   */
  error InvalidPreRewardETHReserves();

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
   * @param repriceDiff The difference between the previous rswETH rate and what would be the updated rate
   * @param maximumRepriceDiff The maximum allowed difference in rswETH rate
   */
  error RepriceDifferenceTooLarge(
    uint256 repriceDiff,
    uint256 maximumRepriceDiff
  );

  /**
   * @dev Thrown during repricing when the difference in rswETH supplied to repricing compared to the actual supply is too great
   * @param repriceRswETHDiff The difference between the rswETH supplied to repricing and actual supply
   * @param maximumRswETHRepriceDiff The maximum allowed difference in rswETH supply
   */
  error RepriceRswETHDifferenceTooLarge(
    uint256 repriceRswETHDiff,
    uint256 maximumRswETHRepriceDiff
  );

  /**
   * @dev Throw when the caller tries to burn 0 rswETH
   */
  error CannotBurnZeroRswETH();

  /**
   * @dev Error thrown when attempting to call a method that is only callable by the DepositManager contract.
   */
  error OnlyDepositManager();

  /**
   * @dev Error thrown when the amount of rswETH received in exchange for ETH is less than the minimum amount specified.
   * @dev This can occur during depositViaDepositManager, as the flow must account for slippage.
   * @param rswETHAmount The amount of rswETH resulting from the exchange rate conversion
   * @param minRswETH The minimum amount of rswETH required
   */
  error InsufficientRswETHReceived(
    uint256 rswETHAmount,
    uint256 minRswETH
  );

  // ***** Events *****

  /**
   * @dev Event emitted when a user withdraws ETH for swETH
   * @param to Address of the recipient.
   * @param rswETHBurned Amount of RswETH burned in the transaction.
   * @param ethReturned Amount of ETH returned in the transaction.
   */
  event ETHWithdrawn(
    address indexed to,
    uint256 rswETHBurned,
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
   * @dev Event emitted when the rswETH - ETH rate is updated
   * @param newEthReserves The new ETH reserves for the swell protocol
   * @param newRswETHToETHRate The new RswETH to ETH rate.
   * @param nodeOperatorRewards The rewards for the node operator's.
   * @param swellTreasuryRewards The rewards for the swell treasury.
   * @param totalETHDeposited Current total ETH staked at time of reprice.
   */
  event Reprice(
    uint256 newEthReserves,
    uint256 newRswETHToETHRate,
    uint256 nodeOperatorRewards,
    uint256 swellTreasuryRewards,
    uint256 totalETHDeposited
  );

  /**
   * @dev Event is fired when some contracts receive ETH
   * @param from The account that sent the ETH
   * @param rswETHMinted The amount of rswETH minted to the caller
   * @param amount The amount of ETH received
   * @param referral The referrer's address
   */
  event ETHDepositReceived(
    address indexed from,
    uint256 amount,
    uint256 rswETHMinted,
    uint256 newTotalETHDeposited,
    address indexed referral
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
   * @dev Event emitted on a successful call to setMaximumRepriceRswETHDifferencePercentage
   * @param _oldMaximumRepriceRswETHDifferencePercentage The old maximum rswETH supply difference
   * @param _newMaximumRepriceRswETHDifferencePercentage The new updated rswETH supply difference
   */
  event MaximumRepriceRswETHDifferencePercentageUpdated(
    uint256 _oldMaximumRepriceRswETHDifferencePercentage,
    uint256 _newMaximumRepriceRswETHDifferencePercentage
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

  /**
   * @dev Event emitted on successful call from the DepositManager to mint rswETH to a LST depositor
   * @param _receiver The person receiving the rswETH. Should be the same person who deposited their LST's in the DepositManager
   * @param _ethSpent The amount of ETH their LST's were worth at the time of deposit. Used to mint rswETH.
   * @param _rswETHReceived The amount of rswETH received by the user
   */
  event DepoistManagerDeposit(
    address _receiver,
    uint256 _ethSpent,
    uint256 _rswETHReceived
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
  function lastRepriceETHReserves() external view returns (uint256);

  /**
   * @dev Returns the last time the reprice method was called in UNIX
   * @return The UNIX timestamp of the last time reprice was called
   */
  function lastRepriceUNIX() external view returns (uint256);

  /**
   * @dev Returns the total ETH that has been deposited over the protocols lifespan
   * @return The current total amount of ETH that has been deposited
   */
  function totalETHDeposited() external view returns (uint256);

  /**
   * @dev Returns the current swell treasury reward percentage.
   * @return The current swell treasury reward percentage.
   */
  function swellTreasuryRewardPercentage() external view returns (uint256);

  /**
   * @dev Returns the current node operator reward percentage.
   * @return The current node operator reward percentage.
   */
  function nodeOperatorRewardPercentage() external view returns (uint256);

  /**
   * @dev Returns the current RswETH to ETH rate, returns 1:1 if no reprice has occurred otherwise it returns the rswETHToETHRateFixed rate.
   * @return The current RswETH to ETH rate.
   */
  function rswETHToETHRate() external view returns (uint256);

  /**
   * @dev Returns the current ETH to RswETH rate.
   * @return The current ETH to RswETH rate.
   */
  function ethToRswETHRate() external view returns (uint256);

  /**
   * @dev Returns the minimum reprice time
   * @return The minimum reprice time
   */
  function minimumRepriceTime() external view returns (uint256);

  /**
   * @dev Returns the maximum percentage difference with 1e18 precision
   * @return The maximum percentage difference
   */
  function maximumRepriceDifferencePercentage() external view returns (uint256);

  /**
   * @dev Returns the maximum percentage difference with 1e18 precision
   * @return The maximum percentage difference in suppled and actual swETH supply
   */
  function maximumRepriceRswETHDifferencePercentage()
    external
    view
    returns (uint256);

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
   * @dev Sets the maximum percentage allowable difference in rswETH supplied to repricing compared to current rswETH supply.
   * @notice Only a platform admin can call this function.
   * @param _maximumRepriceRswETHDifferencePercentage The new maximum percentage rswETH supply difference allowed.
   */
  function setMaximumRepriceRswETHDifferencePercentage(
    uint256 _maximumRepriceRswETHDifferencePercentage
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
   * @notice The amount of ETH deposited will be converted to RswETH at the current RswETH to ETH rate
   */
  function deposit() external payable;

  /**
   * @dev Deposits ETH into the contract
   * @param referral The referrer's address
   * @notice The amount of ETH deposited will be converted to RswETH at the current RswETH to ETH rate
   */
  function depositWithReferral(address referral) external payable;

  /**
   * @dev Called when a user deposits a LST into the deposit manager.
   * @param _amount The amount of ETH to mint rswETH for.
   * @param _to The address to mint rswETH for.
   * @param _minRsweTH The minimum amount of rswETH to mint.
   * @notice Calculates the current LST -> ETH exhange rate and mints the equivalent amount of rswETH to the depositor.
   * @notice Does not actually deposit ETH into the DepositManager.
   */
  function depositViaDepositManager(
    uint256 _amount,
    address _to,
    uint256 _minRsweTH
  ) external;

  /**
   * @dev Burns the requested amount of rswETH, it does not return any ETH to the caller
   * @param amount The amount of rswETH to burn
   */
  function burn(uint256 amount) external;

  /**
   * @dev This method reprices the rswETH -> ETH rate, this will be called via an offchain service on a regular interval, likely ~1 day. The rswETH total supply is passed as an argument to avoid a potential race conditions between the off-chain reserve calculations and the on-chain repricing
   * @dev This method also mints a percentage of rswETH as rewards to be claimed by NO's and the swell treasury. The formula for determining the amount of rswETH to mint is the following: rswETHToMint = (rswETHSupply * newETHRewards * feeRate) / (preRewardETHReserves - newETHRewards * feeRate + newETHRewards)
   * @dev The formula is quite complicated because it needs to factor in the updated exchange rate whilst it calculates the amount of rswETH rewards to mint. This ensures the rewards aren't double-minted and are backed by ETH.
   * @param _preRewardETHReserves The PoR value exclusive of the new ETH rewards earned
   * @param _newETHRewards The total amount of new ETH earnt over the period.
   * @param _rswETHTotalSupply The total rswETH supply at the time of off-chain reprice calculation
   */
  function reprice(
    uint256 _preRewardETHReserves,
    uint256 _newETHRewards,
    uint256 _rswETHTotalSupply
  ) external;
}
