// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.7;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {RepriceSnapshot} from "../libraries/Repricing.sol";
import {IRepricingOracle} from "../interfaces/IRepricingOracle.sol";
import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {AggregatorV3Interface} from "../vendors/AggregatorV3Interface.sol";

contract MockRepricingOracleForUpgrade is IRepricingOracle, Initializable {
  error ErrUpgradeSuccess();

  IAccessControlManager public AccessControlManager;
  AggregatorV3Interface public override ExternalV3ReservesPoROracle;

  uint256 public override maximumRepriceBlockAtSnapshotStaleness;
  uint256 public override maximumRepriceV3ReservesExternalPoRDiffPercentage;

  RepriceSnapshot private _lastRepriceSnapshot;

  bool public testValue;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  function withdrawERC20(IERC20 _token) external override {
    revert ErrUpgradeSuccess();
  }

  function lastRepriceSnapshot()
    external
    view
    override
    returns (RepriceSnapshot memory)
  {
    revert ErrUpgradeSuccess();
  }

  function assertRepricingSnapshotValidity(
    RepriceSnapshot calldata _snapshot
  ) external view override {}

  function submitSnapshot(
    RepriceSnapshot calldata _snapshot
  ) external override {
    // if this function reverts this means that the proxy contract is pointing at the correct implementation
    revert ErrUpgradeSuccess();
  }

  function setMaximumRepriceBlockAtSnapshotStaleness(
    uint256 _maximumRepriceBlockAtSnapshotStaleness
  ) external override {
    revert ErrUpgradeSuccess();
  }

  function setExternalV3ReservesPoROracleAddress(
    address _newAddress
  ) external override {
    revert ErrUpgradeSuccess();
  }

  function setMaximumRepriceV3ReservesExternalPoRDiffPercentage(
    uint256 _newMaximumRepriceV3ReservesExternalPoRDiffPercentage
  ) external override {
    revert ErrUpgradeSuccess();
  }

  function unsetExternalV3ReservesPoROracleAddress() external override {
    revert ErrUpgradeSuccess();
  }
}
