// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IRepricingOracle} from "../interfaces/IRepricingOracle.sol";
import {Repricing, RepriceSnapshot, BalancesSnapshot, RepriceSnapshotState} from "../libraries/Repricing.sol";
import {IrswETH} from "../interfaces/IrswETH.sol";
import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {RepriceSnapshot} from "../libraries/Repricing.sol";
import {SwellLib} from "../libraries/SwellLib.sol";
import {AggregatorV3Interface} from "../vendors/AggregatorV3Interface.sol";

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

  RepriceSnapshot private _lastRepriceSnapshot;

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
    RepriceSnapshot calldata _snapshot
  ) external override checkRole(SwellLib.BOT) {
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }
    // validation
    _assertRepricingSnapshotValidity(_snapshot);

    // gather state
    uint256 totalReserves = _snapshot.state.balances.totalReserves();

    // events
    emit SnapshotSubmitted(
      _snapshot.meta.blockNumber,
      _snapshot.meta.slot,
      _snapshot.meta.timestamp,
      _snapshot.state.totalETHDeposited,
      _snapshot.state.rswETHTotalSupply
    );

    emit ReservesRecorded(
      _snapshot.meta.blockNumber,
      _snapshot.state.balances.executionLayer,
      _snapshot.state.balances.consensusLayerV3Validators,
      _snapshot.state.balances.consensusLayerV2Validators,
      _snapshot.state.balances.transitioning,
      totalReserves
    );

    if (_snapshot.meta.blockOfLastSnapshot != 0) {
      // acquire extra info to add context to rewards event
      (
        int256 reservesChange,
        uint256 ethDepositsChange
      ) = _repricingPeriodDeltas(totalReserves, _snapshot.state);

      emit RewardsCalculated(
        _snapshot.meta.blockNumber,
        _snapshot.meta.blockOfLastSnapshot,
        reservesChange,
        ethDepositsChange,
        _snapshot.rewardsPayableForFees
      );
    }

    // reprice call
    uint256 newETHRewards = _snapshot.rewardsPayableForFees;
    uint256 rswETHTotalSupply = _snapshot.state.rswETHTotalSupply;
    uint256 preRewardETHReserves = totalReserves - newETHRewards;

    AccessControlManager.rswETH().reprice(
      preRewardETHReserves,
      newETHRewards,
      rswETHTotalSupply
    );

    // persist state

    _lastRepriceSnapshot = _snapshot;
  }

  // ** PLATFORM_ADMIN management methods **

  function setExternalV3ReservesPoROracleAddress(
    address _newAddress
  )
    external
    override
    checkRole(SwellLib.PLATFORM_ADMIN)
    checkZeroAddress(_newAddress)
  {
    emit ExternalV3ReservesPoROracleAddressUpdated(
      address(ExternalV3ReservesPoROracle),
      _newAddress
    );
    ExternalV3ReservesPoROracle = AggregatorV3Interface(_newAddress);
  }

  function unsetExternalV3ReservesPoROracleAddress()
    external
    override
    checkRole(SwellLib.PLATFORM_ADMIN)
  {
    emit ExternalV3ReservesPoROracleAddressUnset(
      address(ExternalV3ReservesPoROracle)
    );
    ExternalV3ReservesPoROracle = AggregatorV3Interface(address(0));
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

  // ************************************
  // ***** Internal helpers *****

  function _repricingPeriodDeltas(
    uint256 _totalReserves,
    RepriceSnapshotState memory _snapshotState
  ) internal view returns (int256 reservesChange, uint256 ethDepositsChange) {
    reservesChange =
      int256(_totalReserves) -
      int256(_lastRepriceSnapshot.state.balances.totalReserves());

    ethDepositsChange =
      _snapshotState.totalETHDeposited -
      _lastRepriceSnapshot.state.totalETHDeposited;
  }

  function _assertRepricingSnapshotValidity(
    RepriceSnapshot memory _snapshot
  ) internal view {
    if (
      _snapshot.meta.blockOfLastSnapshot !=
      _lastRepriceSnapshot.meta.blockNumber
    ) {
      revert RepriceBlockOfLastSnapshotMismatch(
        _snapshot.meta.blockOfLastSnapshot,
        _lastRepriceSnapshot.meta.blockNumber
      );
    }

    if (_snapshot.meta.blockOfLastSnapshot >= _snapshot.meta.blockNumber) {
      revert RepriceBlockAtSnapshotDidNotIncrease();
    }

    if (_snapshot.meta.slot <= _lastRepriceSnapshot.meta.slot) {
      revert RepriceSlotDidNotIncrease();
    }

    if (_snapshot.meta.timestamp <= _lastRepriceSnapshot.meta.timestamp) {
      revert RepriceTimestampDidNotIncrease();
    }

    if (_snapshot.meta.blockNumber >= block.number) {
      revert RepriceBlockAtSnapshotTooHigh(_snapshot.meta.blockNumber, block.number);
    }

    uint256 snapshotStalenessInBlocks = block.number -
      _snapshot.meta.blockNumber;

    if (snapshotStalenessInBlocks > maximumRepriceBlockAtSnapshotStaleness) {
      revert RepriceBlockAtSnapshotIsStale(
        snapshotStalenessInBlocks,
        maximumRepriceBlockAtSnapshotStaleness
      );
    }

    // This contract will be deployed on some chains that will not have the AggregatorV3Interface deployed, so we want to skip this check if the address is 0
    if (address(ExternalV3ReservesPoROracle) == address(0)) {
      return;
    }

    (, int256 externallyReportedV3Balance, , , ) = AggregatorV3Interface(
      ExternalV3ReservesPoROracle
    ).latestRoundData();

    uint256 v3ReservesExternalPoRDiff = _absolute(
      _snapshot.state.balances.consensusLayerV3Validators,
      uint256(externallyReportedV3Balance)
    );

    uint256 maximumV3ReservesExternalPoRDiff = (uint256(
      externallyReportedV3Balance
    ) * maximumRepriceV3ReservesExternalPoRDiffPercentage) / 1 ether;

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

  // ************************************
  // ***** External view methods *****

  function lastRepriceSnapshot()
    external
    view
    override
    returns (RepriceSnapshot memory)
  {
    return _lastRepriceSnapshot;
  }

  function assertRepricingSnapshotValidity(
    RepriceSnapshot calldata _snapshot
  ) external view override {
    _assertRepricingSnapshotValidity(_snapshot);
  }
}
