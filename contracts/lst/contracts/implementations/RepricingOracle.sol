// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IRepricingOracle} from "../interfaces/IRepricingOracle.sol";
import {Repricing, RepriceSnapshot, BalancesSnapshot, RepriceSnapshotState, UpgradeableRepriceSnapshot, WithdrawSnapshotState} from "../libraries/Repricing.sol";
import {IswETH} from "../interfaces/IswETH.sol";
import {IswEXIT} from "../interfaces/IswEXIT.sol";
import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {SwellLib} from "../libraries/SwellLib.sol";
import {AggregatorV3Interface} from "../vendors/AggregatorV3Interface.sol";
import {UD60x18, wrap} from "@prb/math/src/UD60x18.sol";

/**
 * @title RepricingOracle
 * @author https://github.com/SwellNetwork
 * @notice This contract receives snapshots from the execution bot and reprices swETH
 */
contract RepricingOracle is IRepricingOracle, Initializable {
  using SafeERC20 for IERC20;
  using Repricing for BalancesSnapshot;

  IAccessControlManager public AccessControlManager;
  AggregatorV3Interface public override ExternalV3ReservesPoROracle;

  uint256 public override maximumRepriceBlockAtSnapshotStaleness;
  uint256 public override maximumRepriceV3ReservesExternalPoRDiffPercentage;

  RepriceSnapshot private _lastRepriceSnapshot; // ! This has been deprecated in favor of the snapshots mapping, we are using a mapping because we want to allow changes to the Snapshot struct in future. This has to be kept here for compability with the storage layout of the previous version of this contract. There is also additional handling in this contract to support the old snapshot when this contract is first upgraded.

  // Using unstructured storage layout for this struct so that we can upgrade the struct in future
  bytes32 internal constant SNAPSHOT_STRUCT_SLOT =
    keccak256("swell.Swell.snapshotStructSlot");

  uint256 public override maximumRoundDataStalenessTime;
  uint256 public override maximumReferencePriceDiffPercentage;

  // This reads from storage so cannot be a pure function
  function getSnapshotStruct()
    internal
    view
    returns (UpgradeableRepriceSnapshot storage s)
  {
    bytes32 slot = SNAPSHOT_STRUCT_SLOT;
    assembly {
      s.slot := slot
    }
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  modifier checkRole(bytes32 role) {
    AccessControlManager.checkRole(role, msg.sender);
    _;
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

  function initialize(
    IAccessControlManager _accessControlManager,
    AggregatorV3Interface _externalV3ReservesPoROracle
  ) external initializer checkZeroAddress(address(_accessControlManager)) {
    AccessControlManager = _accessControlManager;
    ExternalV3ReservesPoROracle = _externalV3ReservesPoROracle;
  }

  // ************************************
  // ***** External methods ******

  function withdrawERC20(
    IERC20 _token
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    uint256 contractBalance = _token.balanceOf(address(this));
    if (contractBalance == 0) {
      revert SwellLib.NoTokensToWithdraw();
    }

    _token.safeTransfer(msg.sender, contractBalance);
  }

  // ** Execution bot methods **

  function submitSnapshot(
    UpgradeableRepriceSnapshot calldata _snapshot
  ) external override checkRole(SwellLib.BOT) {
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }
    ExternalV3ReservesResult
      memory externalV3ReservesResult = _externalV3ReservesLatestRoundData();
    _assertRepricingSnapshotValidity(_snapshot, externalV3ReservesResult);

    uint256 swETHToETHRate = AccessControlManager.swETH().swETHToETHRate();
    uint256 referenceOnChainRate = _referenceOnChainRate(
      _snapshot.state,
      _snapshot.withdrawState,
      externalV3ReservesResult
    );

    handleReprice(_snapshot);

    uint256 newSwETHToETHRate = AccessControlManager.swETH().swETHToETHRate();
    _checkReferencePriceDiff(
      newSwETHToETHRate,
      referenceOnChainRate,
      maximumReferencePriceDiffPercentage
    );

    if (swETHToETHRate > newSwETHToETHRate) {
      AccessControlManager.lockdown();
    }
  }

  function submitSnapshotV2(
    bytes[] calldata activeValidatorsToDelete,
    UpgradeableRepriceSnapshot calldata _snapshot,
    uint256 lastTokenIDToProcess
  ) external override checkRole(SwellLib.BOT) {
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }
    ExternalV3ReservesResult
      memory externalV3ReservesResult = _externalV3ReservesLatestRoundData();
    _assertRepricingSnapshotValidity(_snapshot, externalV3ReservesResult);

    if (activeValidatorsToDelete.length > 0) {
      AccessControlManager.NodeOperatorRegistry().deleteActiveValidators(
        activeValidatorsToDelete
      );
    }

    uint256 swETHToETHRate = AccessControlManager.swETH().swETHToETHRate();
    uint256 referenceOnChainRate = _referenceOnChainRate(
      _snapshot.state,
      _snapshot.withdrawState,
      externalV3ReservesResult
    );

    handleReprice(_snapshot);

    uint256 newSwETHToETHRate = AccessControlManager.swETH().swETHToETHRate();
    _checkReferencePriceDiff(
      newSwETHToETHRate,
      referenceOnChainRate,
      maximumReferencePriceDiffPercentage
    );

    if (swETHToETHRate > newSwETHToETHRate) {
      AccessControlManager.lockdown();
    }

    if (!AccessControlManager.withdrawalsPaused()) {
      AccessControlManager.swEXIT().processWithdrawals(lastTokenIDToProcess);
    }
  }

  // ** PLATFORM_ADMIN management methods **

  function setExternalV3ReservesPoROracleAddress(
    address _newAddress
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    emit ExternalV3ReservesPoROracleAddressUpdated(
      address(ExternalV3ReservesPoROracle),
      _newAddress
    );
    ExternalV3ReservesPoROracle = AggregatorV3Interface(_newAddress);
  }

  function setMaximumRepriceBlockAtSnapshotStaleness(
    uint256 _maximumRepriceBlockAtSnapshotStaleness
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    emit MaximumRepriceBlockAtSnapshotStalenessUpdated(
      maximumRepriceBlockAtSnapshotStaleness,
      _maximumRepriceBlockAtSnapshotStaleness
    );

    maximumRepriceBlockAtSnapshotStaleness = _maximumRepriceBlockAtSnapshotStaleness;
  }

  function setMaximumRepriceV3ReservesExternalPoRDiffPercentage(
    uint256 _newMaximumRepriceV3ReservesExternalPoRDiffPercentage
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    emit MaximumRepriceV3ReservesExternalPoRDiffPercentageUpdated(
      maximumRepriceV3ReservesExternalPoRDiffPercentage,
      _newMaximumRepriceV3ReservesExternalPoRDiffPercentage
    );

    maximumRepriceV3ReservesExternalPoRDiffPercentage = _newMaximumRepriceV3ReservesExternalPoRDiffPercentage;
  }

  function setMaximumRoundDataStalenessTime(
    uint256 _newMaximumRoundDataStalenessTime
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    emit MaximumRoundDataStalenessTimeUpdated(
      maximumRoundDataStalenessTime,
      _newMaximumRoundDataStalenessTime
    );

    maximumRoundDataStalenessTime = _newMaximumRoundDataStalenessTime;
  }

  function setMaximumReferencePriceDiffPercentage(
    uint256 _newMaximumReferencePriceDiffPercentage
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    emit MaximumReferencePriceDiffPercentageUpdated(
      maximumReferencePriceDiffPercentage,
      _newMaximumReferencePriceDiffPercentage
    );

    maximumReferencePriceDiffPercentage = _newMaximumReferencePriceDiffPercentage;
  }

  // ************************************
  // ***** Internal helpers *****

  function handleReprice(
    UpgradeableRepriceSnapshot calldata _snapshot
  ) internal {
    // gather state
    uint256 reserveAssets = _snapshot.state.balances.reserveAssets();

    // events
    emit SnapshotSubmittedV2(
      _snapshot.meta.blockNumber,
      _snapshot.meta.slot,
      _snapshot.meta.timestamp,
      _snapshot.state.totalETHDeposited,
      _snapshot.state.swETHTotalSupply,
      _snapshot.withdrawState.totalETHExited
    );

    emit ReservesRecordedV2(
      _snapshot.meta.blockNumber,
      _snapshot.state.balances.executionLayer,
      _snapshot.state.balances.consensusLayerV3Validators,
      _snapshot.state.balances.consensusLayerV2Validators,
      _snapshot.state.balances.transitioning,
      reserveAssets - _snapshot.withdrawState.exitingETH,
      reserveAssets,
      _snapshot.withdrawState.exitingETH
    );

    if (_snapshot.meta.blockOfLastSnapshot != 0) {
      // acquire extra info to add context to rewards event
      (
        int256 reserveAssetsChange,
        uint256 ethDepositsChange,
        uint256 ethExitedChange
      ) = _repricingPeriodDeltas(
          reserveAssets,
          _snapshot.state,
          _snapshot.withdrawState
        );

      emit RewardsCalculatedV2(
        _snapshot.meta.blockNumber,
        _snapshot.meta.blockOfLastSnapshot,
        reserveAssetsChange,
        ethDepositsChange,
        _snapshot.rewardsPayableForFees,
        ethExitedChange
      );
    }

    // reprice call
    uint256 newETHRewards = _snapshot.rewardsPayableForFees;
    uint256 swETHTotalSupply = _snapshot.state.swETHTotalSupply;
    uint256 preRewardETHReserves = reserveAssets -
      _snapshot.withdrawState.exitingETH -
      newETHRewards;

    AccessControlManager.swETH().reprice(
      preRewardETHReserves,
      newETHRewards,
      swETHTotalSupply
    );

    UpgradeableRepriceSnapshot
      storage upgradeableRepriceSnapshot = getSnapshotStruct();

    // Values must be set individually because of the way the UpgradeableRepriceSnapshot struct is stored in storage
    upgradeableRepriceSnapshot.meta = _snapshot.meta;
    upgradeableRepriceSnapshot.state = _snapshot.state;
    upgradeableRepriceSnapshot.rewardsPayableForFees = _snapshot
      .rewardsPayableForFees;
    upgradeableRepriceSnapshot.withdrawState = _snapshot.withdrawState;
  }

  function _repricingPeriodDeltas(
    uint256 _reserveAssets,
    RepriceSnapshotState memory _snapshotState,
    WithdrawSnapshotState memory _withdrawState
  )
    internal
    view
    returns (
      int256 reserveAssetsChange,
      uint256 ethDepositsChange,
      uint256 ethExitedChange
    )
  {
    UpgradeableRepriceSnapshot
      storage upgradeableRepriceSnapshot = getSnapshotStruct();

    bool useOldSnapshot = upgradeableRepriceSnapshot.meta.blockNumber == 0;

    uint256 reserveAssets = useOldSnapshot
      ? _lastRepriceSnapshot.state.balances.reserveAssets()
      : upgradeableRepriceSnapshot.state.balances.reserveAssets();
    reserveAssetsChange = int256(_reserveAssets) - int256(reserveAssets);

    uint256 totalETHDeposited = useOldSnapshot
      ? _lastRepriceSnapshot.state.totalETHDeposited
      : upgradeableRepriceSnapshot.state.totalETHDeposited;
    ethDepositsChange = _snapshotState.totalETHDeposited - totalETHDeposited;

    uint256 totalETHExited = useOldSnapshot
      ? 0
      : upgradeableRepriceSnapshot.withdrawState.totalETHExited;
    ethExitedChange = _withdrawState.totalETHExited - totalETHExited;
  }

  /**
   * @dev Asserts the validity of a repricing snapshot
   * @param _snapshot The snapshot to assert the validity of
   * @param _externalV3ReservesResult A struct holding information about the external V3 proof of reserves contract: whether the on-chain data source exists, and the latest value if it does
   */
  function _assertRepricingSnapshotValidity(
    UpgradeableRepriceSnapshot memory _snapshot,
    ExternalV3ReservesResult memory _externalV3ReservesResult
  ) internal view {
    UpgradeableRepriceSnapshot
      storage upgradeableRepriceSnapshot = getSnapshotStruct();

    uint256 upgradeableSnapshotBlockNumber = upgradeableRepriceSnapshot
      .meta
      .blockNumber;

    bool useOldSnapshot = upgradeableSnapshotBlockNumber == 0;

    uint256 lastRepriceBlockNumber = useOldSnapshot
      ? _lastRepriceSnapshot.meta.blockNumber
      : upgradeableSnapshotBlockNumber;

    if (_snapshot.meta.blockOfLastSnapshot != lastRepriceBlockNumber) {
      revert RepriceBlockOfLastSnapshotMismatch(
        _snapshot.meta.blockOfLastSnapshot,
        lastRepriceBlockNumber
      );
    }

    if (_snapshot.meta.blockOfLastSnapshot >= _snapshot.meta.blockNumber) {
      revert RepriceBlockAtSnapshotDidNotIncrease();
    }

    if (_snapshot.meta.blockNumber >= block.number) {
      revert RepriceBlockAtSnapshotTooHigh(
        _snapshot.meta.blockNumber,
        block.number
      );
    }

    uint256 snapshotStalenessInBlocks = block.number -
      _snapshot.meta.blockNumber;

    uint256 cachedMaximumRepriceBlockAtSnapshotStaleness = maximumRepriceBlockAtSnapshotStaleness;

    if (
      snapshotStalenessInBlocks > cachedMaximumRepriceBlockAtSnapshotStaleness
    ) {
      revert RepriceBlockAtSnapshotIsStale(
        snapshotStalenessInBlocks,
        cachedMaximumRepriceBlockAtSnapshotStaleness
      );
    }

    IswEXIT swEXIT = AccessControlManager.swEXIT();

    if (swEXIT.totalETHExited() != _snapshot.withdrawState.totalETHExited) {
      revert ProcessWithdrawalsTotalETHExitedMismatch();
    }

    // Exiting must rise
    if (swEXIT.exitingETH() < _snapshot.withdrawState.exitingETH) {
      revert ProcessWithdrawalsExitingETHMustMonotonicallyIncrease();
    }

    // This contract will be deployed on some chains that will not have the AggregatorV3Interface deployed, so we want to skip this check if the address is 0
    if (!_externalV3ReservesResult.exists) {
      return;
    }

    uint256 v3ReservesExternalPoRDiff = _absolute(
      _snapshot.state.balances.consensusLayerV3Validators,
      _externalV3ReservesResult.externallyReportedV3Balance
    );

    uint256 maximumV3ReservesExternalPoRDiff = (_externalV3ReservesResult
      .externallyReportedV3Balance *
      maximumRepriceV3ReservesExternalPoRDiffPercentage) / 1 ether;

    if (v3ReservesExternalPoRDiff > maximumV3ReservesExternalPoRDiff) {
      revert RepriceV3ReservesExternalPoRDifferentialTooHigh(
        v3ReservesExternalPoRDiff,
        maximumV3ReservesExternalPoRDiff
      );
    }
  }

  /**
   * @dev Returns the absolute difference between two uint256 values
   */
  function _absolute(uint256 _a, uint256 _b) internal pure returns (uint256) {
    if (_a < _b) {
      return _b - _a;
    }

    return _a - _b;
  }

  /**
   * @dev Calculates a reference price against which the new swETH rate can be compared
   * @param _state The state of the snapshot that will be used in repricing
   * @param _withdrawState The withdraw state of the snapshot that will be used in repricing
   * @param _externalV3ReservesResult A struct holding information about the external V3 proof of reserves contract: whether the on-chain data source exists, and the latest value if it does
   */
  function _referenceOnChainRate(
    RepriceSnapshotState memory _state,
    WithdrawSnapshotState memory _withdrawState,
    ExternalV3ReservesResult memory _externalV3ReservesResult
  ) internal view returns (uint256) {
    uint256 rewardPercentageTotal;
    {
      IswETH swETH = AccessControlManager.swETH();

      uint256 totalSupply = swETH.totalSupply();
      if (totalSupply == 0) {
        revert CannotComputeReferencePriceWithZeroSwETHSupply();
      }

      _state.swETHTotalSupply = totalSupply;
      rewardPercentageTotal =
        swETH.nodeOperatorRewardPercentage() +
        swETH.swellTreasuryRewardPercentage();
      _state.totalETHDeposited = swETH.totalETHDeposited();
    }

    {
      IswEXIT swEXIT = AccessControlManager.swEXIT();
      _withdrawState.totalETHExited = swEXIT.totalETHExited();
      _withdrawState.exitingETH = swEXIT.exitingETH();
    }

    if (_externalV3ReservesResult.exists) {
      _state.balances.consensusLayerV3Validators = _externalV3ReservesResult
        .externallyReportedV3Balance;
    }

    {
      address depositManager = address(AccessControlManager.DepositManager());
      _state.balances.executionLayer = depositManager.balance;
    }

    uint256 reserveAssets = _state.balances.reserveAssets();

    uint256 rewardsPayableForFees;
    {
      int256 unclampedRewardsPayableForFees;
      {
        (
          int256 reserveAssetsChange,
          uint256 ethDepositsChange,
          uint256 ethExitedChange
        ) = _repricingPeriodDeltas(reserveAssets, _state, _withdrawState);

        unclampedRewardsPayableForFees =
          reserveAssetsChange -
          int256(ethDepositsChange) +
          int256(ethExitedChange);
      }

      if (unclampedRewardsPayableForFees > 0) {
        rewardsPayableForFees = uint256(unclampedRewardsPayableForFees);
      }
    }

    uint256 referenceNewPrice;
    {
      uint256 totalReserves = reserveAssets - _withdrawState.exitingETH;

      UD60x18 rewardsInETH = wrap(rewardsPayableForFees).mul(
        wrap(rewardPercentageTotal)
      );

      UD60x18 rewardsInSwETH = wrap(_state.swETHTotalSupply)
        .mul(rewardsInETH)
        .div(wrap(totalReserves - rewardsInETH.unwrap()));

      referenceNewPrice = wrap(totalReserves)
        .div(wrap(_state.swETHTotalSupply + rewardsInSwETH.unwrap()))
        .unwrap();
    }

    return referenceNewPrice;
  }

  /**
   * @dev Checks if the reference price difference is too high. The reference price is a combination of various on-chain sources used to approximate the real rate.
   * @param _newSwETHToETHRate The new swETH to ETH rate used as a basis for comparison
   * @param _referenceRate The reference on-chain rate used as an approximation of the real rate
   * @param _cachedMaximumReferencePriceDiffPercentage The maximum price difference percentage against the reference, cached to save gas
   */
  function _checkReferencePriceDiff(
    uint256 _newSwETHToETHRate,
    uint256 _referenceRate,
    uint256 _cachedMaximumReferencePriceDiffPercentage
  ) internal pure {
    uint256 referencePriceDiff = _absolute(_newSwETHToETHRate, _referenceRate);

    uint256 maximumReferencePriceDiff = (_newSwETHToETHRate *
      _cachedMaximumReferencePriceDiffPercentage) / 1 ether;

    if (referencePriceDiff > maximumReferencePriceDiff) {
      revert ReferencePriceDiffTooHigh(
        referencePriceDiff,
        _cachedMaximumReferencePriceDiffPercentage
      );
    }
  }

  // Holds information about the latest round data from the external V3 reserves PoR oracle
  struct ExternalV3ReservesResult {
    // Whether there is a value for the external V3 reserves that can be used for calculations
    bool exists;
    // The latest round data from the external V3 reserves PoR oracle, if it exists
    uint256 externallyReportedV3Balance;
  }

  /**
   * @dev Returns the latest round data from the external V3 reserves PoR oracle
   * @notice If the address of the external V3 reserves PoR oracle is 0, this function will return a struct with exists set to false
   * @notice If the latest round data from the oracle is stale, this function will revert
   * @return A struct holding information about the latest round data from the external V3 reserves PoR oracle
   */
  function _externalV3ReservesLatestRoundData()
    internal
    view
    returns (ExternalV3ReservesResult memory)
  {
    if (address(ExternalV3ReservesPoROracle) == address(0)) {
      return
        ExternalV3ReservesResult({
          exists: false,
          externallyReportedV3Balance: 0
        });
    }

    (, int256 latestRoundData, , uint256 updatedAt, ) = AggregatorV3Interface(
      ExternalV3ReservesPoROracle
    ).latestRoundData();

    uint256 roundDataExpiryTime = updatedAt + maximumRoundDataStalenessTime;

    if (block.timestamp > roundDataExpiryTime) {
      revert RoundDataIsStale(updatedAt, block.timestamp - roundDataExpiryTime);
    }

    return
      ExternalV3ReservesResult({
        exists: true,
        externallyReportedV3Balance: uint256(latestRoundData)
      });
  }

  // ************************************
  // ***** External view methods *****

  function lastRepriceSnapshot()
    external
    view
    override
    returns (UpgradeableRepriceSnapshot memory)
  {
    UpgradeableRepriceSnapshot
      storage upgradeableRepriceSnapshot = getSnapshotStruct();
    // Handling for when this contract is upgraded and we want to return the last snapshot
    if (upgradeableRepriceSnapshot.meta.blockNumber == 0) {
      return
        UpgradeableRepriceSnapshot({
          meta: _lastRepriceSnapshot.meta,
          state: _lastRepriceSnapshot.state,
          rewardsPayableForFees: _lastRepriceSnapshot.rewardsPayableForFees,
          withdrawState: WithdrawSnapshotState({
            totalETHExited: 0,
            exitingETH: 0
          })
        });
    }

    return upgradeableRepriceSnapshot;
  }

  function assertRepricingSnapshotValidity(
    UpgradeableRepriceSnapshot calldata _snapshot
  ) external view override {
    ExternalV3ReservesResult
      memory externalV3ReservesResult = _externalV3ReservesLatestRoundData();
    _assertRepricingSnapshotValidity(_snapshot, externalV3ReservesResult);
  }
}
