// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/**
 * @title BalancesSnapshot
 * @dev An exhaustive categorization of the ETH reserves backing the rswETH token at a point in time.
 */
struct BalancesSnapshot {
  uint256 executionLayer; // ETH in protocol controlled contracts on the execution layer which has not yet been deposited on the beacon chain.
  uint256 consensusLayerV3Validators; // ETH Reserves held by v3 validators on the consensus layer.
  uint256 consensusLayerV2Validators; // ETH Reserves held by v2 validators on the consensus layer.
  uint256 transitioning; // ETH Reserves held by validators transitioning to the beacon chain.
}

/**
 * @title RepriceSnapshotState
 * @dev A struct representing the state of a repricing snapshot.
 */
struct RepriceSnapshotState {
  uint256 totalETHDeposited; // The total amount of ETH deposited by stakers.
  uint256 rswETHTotalSupply; // The total supply of the rswETH token.
  BalancesSnapshot balances; // A struct which exhaustively categorizes the current ETH reserves backing rswETH.
}

/**
 * @title RepriceSnapshotMeta
 * @dev A struct containing metadata related to a particular repricing snapshot.
 */
struct RepriceSnapshotMeta {
  uint256 blockNumber; // The block number at which the snapshot was taken.
  uint256 blockOfLastSnapshot; // The block number of the snapshot which preceded this one.
  uint256 slot; // The slot on the consensus layer in which the block associated with the snapshot was proposed.
  uint256 timestamp; // A timestamp which indicates when the execution bot started calculations.
}

/**
 * @title RepriceSnapshot
 * @dev A struct representing a complete repricing snapshot.
 * @dev A repricing snapshot outlines the ETH reserves backing rswETH at a moment in time (denoted by a block number on the execution layer and a slot on the consensus layer),
 * @dev  as well as information describing a reward period (given by the difference in blocks since the last snapshot) and the payable rewards over this period resulting from validator performance.
 * @dev Repricing snapshots include other stateful information, associated with a snapshot's block number, necessary to reprice the rswETH token (totalETHDeposited and swETHTotalSupply).
 */
struct RepriceSnapshot {
  RepriceSnapshotMeta meta; // An instance of RepriceSnapshotMeta containing metadata about the snapshot.
  RepriceSnapshotState state; // An instance of RepriceSnapshotState representing the state of the snapshot.
  uint256 rewardsPayableForFees; // The amount of rewards to be distributed among rswETH holders, node operators, and the Swell Treasury, resulting from changes to total reserves and total ETH deposited since the last snapshot.
}

library Repricing {
  function totalReserves(
    BalancesSnapshot memory _balances
  ) internal pure returns (uint256) {
    return
      _balances.executionLayer +
      _balances.consensusLayerV3Validators +
      _balances.consensusLayerV2Validators +
      _balances.transitioning;
  }
}
