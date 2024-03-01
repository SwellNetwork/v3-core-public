// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UpgradeableRepriceSnapshot} from "../libraries/Repricing.sol";
import {AggregatorV3Interface} from "../vendors/AggregatorV3Interface.sol";
import {IswETH} from "../interfaces/IswETH.sol";

interface IRepricingOracle {
  // ***** Errors ******

  /**
   * @dev Error thrown when the blockOfLastSnapshot specified in the submitted RepriceSnapshot struct does not match the on-chain value.
   * @param blockOfLastSnapshotSupplied The blockOfLastSnapshot specified in the submitted RepriceSnapshot struct.
   * @param blockOfLastSnapshotOnChain The on-chain value for blockOfLastSnapshot in the lastRepriceSnapshot.
   */
  error RepriceBlockOfLastSnapshotMismatch(
    uint256 blockOfLastSnapshotSupplied,
    uint256 blockOfLastSnapshotOnChain
  );

  /**
   * @dev Error thrown when reprice blockAtSnapshot did not increase since the last snapshot.
   */
  error RepriceBlockAtSnapshotDidNotIncrease();

  /**
   * @dev Error thrown when reprice blockAtSnapshot is higher than current block on-chain.
   * @param snapshotBlockNumber The block number at the time of the snapshot.
   * @param currentBlockNumber The current block number on-chain.
   */
  error RepriceBlockAtSnapshotTooHigh(
    uint256 snapshotBlockNumber,
    uint256 currentBlockNumber
  );

  /**
   * @dev Error thrown when the block number supplied in a repricing report is older than the current block by some configurable threshold.
   * @param snapshotStalenessInBlocks The number of blocks by which the snapshot is stale.
   * @param maximumRepriceBlockAtSnapshotStaleness The threshold number of blocks by which the snapshot is allowed to be stale.
   */
  error RepriceBlockAtSnapshotIsStale(
    uint256 snapshotStalenessInBlocks,
    uint256 maximumRepriceBlockAtSnapshotStaleness
  );

  /**
   * @dev Error thrown when a repricing snapshot's v3 validator reserves differs from the value reported by the external PoR oracle by more than the allowed threshold.
   * @param v3ReservesExternalPoRDiff The difference between the repricing snapshot's v3 validator reserves and externally reported v3 validator reserves.
   * @param maximumV3ReservesExternalPoRDiff The maximum allowed difference between the repricing snapshot's v3 validator reserves and externally reported v3 validator reserves.
   */
  error RepriceV3ReservesExternalPoRDifferentialTooHigh(
    uint256 v3ReservesExternalPoRDiff,
    uint256 maximumV3ReservesExternalPoRDiff
  );

  /**
   * @dev Error thrown when round data is read from the oracle and the updatedAt time is greater than the block.timestamp + maximumRoundDataStalenessTime
   * @param latestRoundDataTime The round data time
   * @param secondsSinceExpiry The number of seconds since the round data expired
   */
  error RoundDataIsStale(
    uint256 latestRoundDataTime,
    uint256 secondsSinceExpiry
  );

  /**
   * @dev Error thrown when calling process withdrawals and the totalETHExited provided in the snapshot doesn't match swEXIT.totalETHExited after processWithdrawals is called
   */
  error ProcessWithdrawalsTotalETHExitedMismatch();

  /**
   * @dev Error thrown after calling process withdrawals and the exitingETH provided in the snapshot is less than swEXIT.exitingETH
   */
  error ProcessWithdrawalsExitingETHMustMonotonicallyIncrease();

  /**
   * @dev Error thrown when the reference price computed from on-chain values differs from the new price resulting from the snapshot submission by more than the allowed threshold.
   * @param referencePriceDiff The difference between the new price and the reference price
   * @param maximumReferencePriceDiffPercentage The maximum allowed difference between the new price and the on-chain reference price
   */
  error ReferencePriceDiffTooHigh(
    uint256 referencePriceDiff,
    uint256 maximumReferencePriceDiffPercentage
  );

  /**
   * @dev Error thrown when attempting to compute the reference price with a swETH supply of zero.
   */
  error CannotComputeReferencePriceWithZeroSwETHSupply();

  // ***** Events ******

  /**
   * @dev Event emitted on a successful call to update the address of the external Proof of Reserves (PoR) contract used for verifying v3 validators' reserves during repricing.
   * @param oldAddress The previous address of the PoR contract.
   * @param newAddress The new updated address of the PoR contract.
   */
  event ExternalV3ReservesPoROracleAddressUpdated(
    address oldAddress,
    address newAddress
  );

  /**
   * @dev Event emitted on a successful call to setMaximumRepriceBlockAtSnapshotStaleness
   * @param _oldMaximumRepriceBlockAtSnapshotStaleness The old staleness threshold, expressed in terms of number of blocks
   * @param _newMaximumRepriceBlockAtSnapshotStaleness The new staleness threshold, expressed in terms of number of blocks
   */
  event MaximumRepriceBlockAtSnapshotStalenessUpdated(
    uint256 _oldMaximumRepriceBlockAtSnapshotStaleness,
    uint256 _newMaximumRepriceBlockAtSnapshotStaleness
  );

  /**
   * @dev Event emitted on a successful call to update the maximum allowed percentage difference between a repricing snapshot's v3 reserves and the externally reported v3 reserves.
   * @param _oldMaximumRepriceV3ReservesExternalPoRDiffPercentage The previous maximum percentage difference.
   * @param _newMaximumRepriceV3ReservesExternalPoRDiffPercentage The new updated maximum percentage difference.
   */
  event MaximumRepriceV3ReservesExternalPoRDiffPercentageUpdated(
    uint256 _oldMaximumRepriceV3ReservesExternalPoRDiffPercentage,
    uint256 _newMaximumRepriceV3ReservesExternalPoRDiffPercentage
  );

  /**
   * @dev Event emitted when a reprice snapshot submitted to initiate the repricing process.
   * @param blockNumber The block number at the time of the snapshot.
   * @param slot The slot on the beacon chain associated with the snapshot block.
   * @param reportTimestamp A timestamp provided by the execution bot, indicating when it started calculations.
   * @param totalETHDeposited The total ETH deposited at the time of the snapshot.
   * @param swETHTotalSupply The total swETH supply at the time of the snapshot.
   */
  event SnapshotSubmitted(
    uint256 indexed blockNumber,
    uint256 slot,
    uint256 reportTimestamp,
    uint256 totalETHDeposited,
    uint256 swETHTotalSupply
  );

  /**
   * @dev Event emitted when a reprice snapshot submitted to initiate the repricing process.
   * @param blockNumber The block number at the time of the snapshot.
   * @param slot The slot on the beacon chain associated with the snapshot block.
   * @param reportTimestamp A timestamp provided by the execution bot, indicating when it started calculations.
   * @param totalETHDeposited The total ETH deposited at the time of the snapshot.
   * @param swETHTotalSupply The total swETH supply at the time of the snapshot.
   * @param totalETHExited The total ETH exited via processed withdrawal requests at the time of the snapshot.
   */
  event SnapshotSubmittedV2(
    uint256 indexed blockNumber,
    uint256 slot,
    uint256 reportTimestamp,
    uint256 totalETHDeposited,
    uint256 swETHTotalSupply,
    uint256 totalETHExited
  );

  /**
   * @dev Event emitted when reserves are recorded following a repricing snapshot submission.
   * @param blockAtSnapshot The block number at the time of the snapshot.
   * @param elBalance ETH in Swell controlled contracts on the execution layer at the time of the snapshot, which has not yet been deposited on the beacon chain.
   * @param clV3Balance The total sum of ETH held by v3 validators on the consensus layer at the moment of the snapshot's slot.
   * @param clV2Balance The total sum of ETH held by v2 validators on the consensus layer at the moment of the snapshot's slot.
   * @param transitioningBalance ETH Reserves held by validators transitioning to the beacon chain at the time of the snapshot.
   * @param newETHReserves Total ETH reserves at the time of snapshot.
   */
  event ReservesRecorded(
    uint256 indexed blockAtSnapshot,
    uint256 elBalance,
    uint256 clV3Balance,
    uint256 clV2Balance,
    uint256 transitioningBalance,
    uint256 newETHReserves
  );

  /**
   * @dev Event emitted when reserves are recorded following a repricing snapshot submission.
   * @param blockAtSnapshot The block number at the time of the snapshot.
   * @param elBalance ETH in Swell controlled contracts on the execution layer at the time of the snapshot, which has not yet been deposited on the beacon chain. Does not include swEXIT balance.
   * @param clV3Balance The total sum of ETH held by v3 validators on the consensus layer at the moment of the snapshot's slot.
   * @param clV2Balance The total sum of ETH held by v2 validators on the consensus layer at the moment of the snapshot's slot.
   * @param transitioningBalance ETH Reserves held by validators transitioning to the beacon chain at the time of the snapshot.
   * @param newETHReserves Reserve assets minus exiting ETH.
   * @param reserveAssets The sum of all balances in the snapshot.
   * @param exitingETH The current amount of exiting ETH, which is has not yet been processed for withdrawals. This value estimates the amount of ETH that will exit when withdrawals are processed.
   */
  event ReservesRecordedV2(
    uint256 indexed blockAtSnapshot,
    uint256 elBalance,
    uint256 clV3Balance,
    uint256 clV2Balance,
    uint256 transitioningBalance,
    uint256 newETHReserves,
    uint256 reserveAssets,
    uint256 exitingETH
  );

  /**
   * @dev Event emitted when rewards are calculated during reprice.
   * @param blockAtSnapshot The block number at the time of the repricing snapshot.
   * @param blockOfLastSnapshot The block number of the last repricing snapshot. In conjunction with blockAtSnapshot, this describes the period over which rewards were calculated.
   * @param reservesChange Change in ETH reserves since the last repricing.
   * @param ethDepositsChange Change in total ETH deposited by stakers since the last repricing.
   * @param rewardsPayableForFees The amount of rewards to be distributed among swETH holders, node operators, and the Swell Treasury, resulting from changes to total reserves and total ETH deposited.
   */
  event RewardsCalculated(
    uint256 indexed blockAtSnapshot,
    uint256 blockOfLastSnapshot,
    int256 reservesChange,
    uint256 ethDepositsChange,
    uint256 rewardsPayableForFees
  );

  /**
   * @dev Event emitted when rewards are calculated during reprice.
   * @param blockAtSnapshot The block number at the time of the repricing snapshot.
   * @param blockOfLastSnapshot The block number of the last repricing snapshot. In conjunction with blockAtSnapshot, this describes the period over which rewards were calculated.
   * @param reserveAssetsChange Change in reserve assets since the last repricing.
   * @param ethDepositsChange Change in total ETH deposited by stakers since the last repricing.
   * @param rewardsPayableForFees The amount of rewards to be distributed among swETH holders, node operators, and the Swell Treasury, resulting from changes to total reserves and total ETH deposited.
   * @param ethExitedChange Change in the total amount of ETH that has exited the protocol, due to processed withdrawals.
   */
  event RewardsCalculatedV2(
    uint256 indexed blockAtSnapshot,
    uint256 blockOfLastSnapshot,
    int256 reserveAssetsChange,
    uint256 ethDepositsChange,
    uint256 rewardsPayableForFees,
    uint256 ethExitedChange
  );

  /**
   * @dev Event emitted when the maximum round data staleness time is updated by the PLATFORM_ADMIN
   * @param _oldMaximumRoundDataStalenessTime The old maximum staleness time for chainlink data
   * @param _newMaximumRoundDataStalenessTime The new maximum staleness time for chainlink data
   */
  event MaximumRoundDataStalenessTimeUpdated(
    uint256 _oldMaximumRoundDataStalenessTime,
    uint256 _newMaximumRoundDataStalenessTime
  );

  /**
   * @dev Event emitted when the maximum reference price difference percentage is updated by the PLATFORM_ADMIN
   * @param _oldMaximumReferencePriceDiffPercentage The old maximum reference price difference percentage
   * @param _newMaximumReferencePriceDiffPercentage The new maximum reference price difference percentage
   */
  event MaximumReferencePriceDiffPercentageUpdated(
    uint256 _oldMaximumReferencePriceDiffPercentage,
    uint256 _newMaximumReferencePriceDiffPercentage
  );

  // ************************************
  // ***** External Methods ******

  /**
   * @dev This method withdraws contract's _token balance to a platform admin
   * @param _token The ERC20 token to withdraw from the contract
   */
  function withdrawERC20(IERC20 _token) external;

  /**
   * @dev Returns the maximum number of blocks that can elapse between block.number and blockAtSnapshot before data is considered stale.
   * @return The maximum number of blocks that can elapse between block.number and blockAtSnapshot.
   */
  function maximumRepriceBlockAtSnapshotStaleness()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the maximum length of time that can elapse between the last round data update and the current block timestamp before the chainlink data is considered stale, in which case the transaction will revert
   * @return The maximum staleness time for chainlink data
   */
  function maximumRoundDataStalenessTime() external view returns (uint256);

  /**
   * @dev Returns the maximum percentage difference allowed between a repricing snapshot's v3 validator reserves and the externally reported v3 reserves.
   * @return The maximum percentage difference allowed between the repricing snapshot's reported V3 validator reserves and the externally reported v3 reserves.
   */
  function maximumRepriceV3ReservesExternalPoRDiffPercentage()
    external
    view
    returns (uint256);

  /**
   * @dev Returns the maximum percentage difference allowed between the new price and the on-chain reference price
   * @return The maximum percentage difference allowed between the new price and the on-chain reference price
   */
  function maximumReferencePriceDiffPercentage()
    external
    view
    returns (uint256);

  /**
   * @dev The repricing snapshot that was most recently used to execute a reprice of the swETH token.
   * @return The `RepriceSnapshot` struct data that was most recently used to execute a reprice of the swETH token.
   */
  function lastRepriceSnapshot()
    external
    view
    returns (UpgradeableRepriceSnapshot memory);

  /**
   * @dev Returns the address of the external Proof of Reserves (PoR) contract used for verifying v3 validator reserves during repricing.
   * @return The address of the PoR contract.
   */
  function ExternalV3ReservesPoROracle()
    external
    view
    returns (AggregatorV3Interface);

  /**
   * @dev Asserts the validity of a repricing snapshot. This function will revert upon receiving a snapshot that would be rejected by submitSnapshot.
   * @param _snapshot The reprice snapshot struct to be validated
   */
  function assertRepricingSnapshotValidity(
    UpgradeableRepriceSnapshot calldata _snapshot
  ) external view;

  /**
   * @dev The entrypoint for trusted execution bots to submit RepricingSnapshot data. The data is ultimately used to perform a repricing of the swETH token.
   * @dev A repricing snapshot outlines the ETH reserves backing swETH at a moment in time (denoted by a block number on the execution layer and a slot on the consensus layer),
   * @dev  as well as information describing a reward period (given by the difference in blocks since the last snapshot) and the payable rewards over this period resulting from validator performance.
   * @dev Repricing snapshots include other stateful information, associated with a snapshot's block number, necessary to reprice the swETH token (totalETHDeposited and swETHTotalSupply).
   * @param _snapshot The `RepriceSnapshot` struct data submitted by the trusted execution bot.
   */
  function submitSnapshot(
    UpgradeableRepriceSnapshot calldata _snapshot
  ) external;

  /**
   * @dev This entrypoint will be used when submitting a snapshot and processing withdrawals. In this case we also want to allow the execution bot to be able to delete active validators.
   * @param activeValidatorsToDelete The list of active validators to delete
   * @param _snapshot The `RepriceSnapshot` struct data submitted by the trusted execution bot.
   * @param lastTokenIDToProcess The last withdrawal token ID to process
   */
  function submitSnapshotV2(
    bytes[] calldata activeValidatorsToDelete,
    UpgradeableRepriceSnapshot calldata _snapshot,
    uint256 lastTokenIDToProcess
  ) external;

  /**
   * @dev Sets the threshold number of blocks by which a repricing report is allowed to be stale
   * @notice Only a platform admin can call this function.
   * @param _maximumRepriceBlockAtSnapshotStaleness The new staleness threshold, expressed in terms of number of blocks
   */
  function setMaximumRepriceBlockAtSnapshotStaleness(
    uint256 _maximumRepriceBlockAtSnapshotStaleness
  ) external;

  /**
   * @dev Sets the address of the external Proof of Reserves (PoR) contract to be used for verifying v3 validator reserves during repricing.
   * @notice Only a platform admin can call this function.
   * @param _newAddress The new address of the PoR contract to be set.
   */
  function setExternalV3ReservesPoROracleAddress(address _newAddress) external;

  /**
   * @dev Sets the maximum percentage difference allowed between a repricing snapshot's v3 reserves and the externally reported v3 reserves.
   * @notice Only a platform admin can call this function.
   * @param _newMaximumRepriceV3ReservesExternalPoRDiffPercentage The new maximum percentage difference allowed between current v3 reserves and the externally reported v3 reserves.
   */
  function setMaximumRepriceV3ReservesExternalPoRDiffPercentage(
    uint256 _newMaximumRepriceV3ReservesExternalPoRDiffPercentage
  ) external;

  /**
   * @dev Sets the maximum length of time that can elapse between the last round data update and the current block timestamp before the chainlink data is considered stale, in which case the transaction will revert
   * @param _newMaximumRoundDataStalenessTime The new maximum staleness time for chainlink data
   */
  function setMaximumRoundDataStalenessTime(
    uint256 _newMaximumRoundDataStalenessTime
  ) external;

  /**
   * @dev Sets the maximum percentage difference allowed between the new price and the on-chain reference price
   * @param _newMaximumReferencePriceDiffPercentage The new maximum percentage difference allowed between the new price and the on-chain reference price
   */
  function setMaximumReferencePriceDiffPercentage(
    uint256 _newMaximumReferencePriceDiffPercentage
  ) external;
}
