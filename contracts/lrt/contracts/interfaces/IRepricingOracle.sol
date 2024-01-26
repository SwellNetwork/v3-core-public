// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RepriceSnapshot} from "../libraries/Repricing.sol";
import {AggregatorV3Interface} from "../vendors/AggregatorV3Interface.sol";
import {IrswETH} from "../interfaces/IrswETH.sol";

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
   * @dev Error thrown when the consensus layer slot did not increase since the last repricing snapshot.
   */
  error RepriceSlotDidNotIncrease();

  /**
   * @dev Error thrown when timestamp did not increase since the last reprice snapshot.
   */
  error RepriceTimestampDidNotIncrease();

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
   * @dev Event emitted on a successful call to unset the address of the external Proof of Reserves (PoR) contract. When unset, PoR checks are skipped during repricing.
   * @param oldAddress The previous address of the PoR contract, now zero.
   */
  event ExternalV3ReservesPoROracleAddressUnset(address oldAddress);

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
   * @param rswETHTotalSupply The total rswETH supply at the time of the snapshot.
   */
  event SnapshotSubmitted(
    uint256 indexed blockNumber,
    uint256 slot,
    uint256 reportTimestamp,
    uint256 totalETHDeposited,
    uint256 rswETHTotalSupply
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
   * @dev Event emitted when rewards are calculated during reprice.
   * @param blockAtSnapshot The block number at the time of the repricing snapshot.
   * @param blockOfLastSnapshot The block number of the last repricing snapshot. In conjunction with blockAtSnapshot, this describes the period over which rewards were calculated.
   * @param reservesChange Change in ETH reserves since the last repricing.
   * @param ethDepositsChange Change in total ETH deposited by stakers since the last repricing.
   * @param rewardsPayableForFees The amount of rewards to be distributed among rswETH holders, node operators, and the Swell Treasury, resulting from changes to total reserves and total ETH deposited.
   */
  event RewardsCalculated(
    uint256 indexed blockAtSnapshot,
    uint256 blockOfLastSnapshot,
    int256 reservesChange,
    uint256 ethDepositsChange,
    uint256 rewardsPayableForFees
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
   * @dev Returns the maximum percentage difference allowed between a repricing snapshot's v3 validator reserves and the externally reported v3 reserves.
   * @return The maximum percentage difference allowed between the repricing snapshot's reported V3 validator reserves and the externally reported v3 reserves.
   */
  function maximumRepriceV3ReservesExternalPoRDiffPercentage()
    external
    view
    returns (uint256);

  /**
   * @dev The repricing snapshot that was most recently used to execute a reprice of the rswETH token.
   * @return The `RepriceSnapshot` struct data that was most recently used to execute a reprice of the rswETH token.
   */
  function lastRepriceSnapshot() external view returns (RepriceSnapshot memory);

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
    RepriceSnapshot calldata _snapshot
  ) external view;

  /**
   * @dev The entrypoint for trusted execution bots to submit RepricingSnapshot data. The data is ultimately used to perform a repricing of the rswETH token.
   * @dev A repricing snapshot outlines the ETH reserves backing rswETH at a moment in time (denoted by a block number on the execution layer and a slot on the consensus layer),
   * @dev  as well as information describing a reward period (given by the difference in blocks since the last snapshot) and the payable rewards over this period resulting from validator performance.
   * @dev Repricing snapshots include other stateful information, associated with a snapshot's block number, necessary to reprice the rswETH token (totalETHDeposited and rswETHTotalSupply).
   * @param _snapshot The `RepriceSnapshot` struct data submitted by the trusted execution bot.
   */
  function submitSnapshot(RepriceSnapshot calldata _snapshot) external;

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
   * @dev Unsets the address of the external Proof of Reserves (PoR) contract to be used for verifying v3 validator reserves during repricing.
   * @notice Only a platform admin can call this function.
   */
  function unsetExternalV3ReservesPoROracleAddress() external;

  /**
   * @dev Sets the maximum percentage difference allowed between a repricing snapshot's v3 reserves and the externally reported v3 reserves.
   * @notice Only a platform admin can call this function.
   * @param _newMaximumRepriceV3ReservesExternalPoRDiffPercentage The new maximum percentage difference allowed between current v3 reserves and the externally reported v3 reserves.
   */
  function setMaximumRepriceV3ReservesExternalPoRDiffPercentage(
    uint256 _newMaximumRepriceV3ReservesExternalPoRDiffPercentage
  ) external;
}
