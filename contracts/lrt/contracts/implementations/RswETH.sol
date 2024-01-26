// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {UD60x18, wrap} from "@prb/math/src/UD60x18.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Whitelist} from "./Whitelist.sol";

import {SwellLib} from "../libraries/SwellLib.sol";

import {IrswETH} from "../interfaces/IrswETH.sol";
import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {INodeOperatorRegistry} from "../interfaces/INodeOperatorRegistry.sol";
import {IRateProvider} from "../vendors/IRateProvider.sol";

/**
 * @title rswETH
 * @notice Contract for handling user deposits in ETH in exchange for rswETH at the stored rate. Also handles the rate updates from the BOT wallet which will occur at a fixed interval.
 * @author https://github.com/max-taylor
 * @dev This contract inherits the Whitelist contract which holds the Access control manager state variable and the checkRole modifier
 */
contract RswETH is
  Initializable,
  Whitelist,
  IrswETH,
  IRateProvider,
  ERC20Upgradeable
{
  using SafeERC20 for IERC20;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  uint256 public override lastRepriceETHReserves;
  uint256 private rswETHToETHRateFixed;

  uint256 public override swellTreasuryRewardPercentage;
  uint256 public override nodeOperatorRewardPercentage;

  uint256 public override lastRepriceUNIX;

  uint256 public override totalETHDeposited;

  uint256 public override minimumRepriceTime;
  uint256 public override maximumRepriceDifferencePercentage;
  uint256 public override maximumRepricerswETHDifferencePercentage;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  fallback() external {
    revert SwellLib.InvalidMethodCall();
  }

  function initialize(
    IAccessControlManager _accessControlManager
  ) external initializer checkZeroAddress(address(_accessControlManager)) {
    __ERC20_init("rswETH", "rswETH");

    __Whitelist_init(_accessControlManager);
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

  function setSwellTreasuryRewardPercentage(
    uint256 _newSwellTreasuryRewardPercentage
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    // Joined percentage total cannot exceed 100% (1 ether)
    if (
      nodeOperatorRewardPercentage + _newSwellTreasuryRewardPercentage > 1 ether
    ) {
      revert RewardPercentageTotalOverflow();
    }

    emit SwellTreasuryRewardPercentageUpdate(
      swellTreasuryRewardPercentage,
      _newSwellTreasuryRewardPercentage
    );

    swellTreasuryRewardPercentage = _newSwellTreasuryRewardPercentage;
  }

  function setNodeOperatorRewardPercentage(
    uint256 _newNodeOperatorRewardPercentage
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    // Joined percentage total cannot exeed 100% (1 ether)
    if (
      swellTreasuryRewardPercentage + _newNodeOperatorRewardPercentage > 1 ether
    ) {
      revert RewardPercentageTotalOverflow();
    }

    emit NodeOperatorRewardPercentageUpdate(
      nodeOperatorRewardPercentage,
      _newNodeOperatorRewardPercentage
    );

    nodeOperatorRewardPercentage = _newNodeOperatorRewardPercentage;
  }

  function setMinimumRepriceTime(
    uint256 _minimumRepriceTime
  ) external checkRole(SwellLib.PLATFORM_ADMIN) {
    emit MinimumRepriceTimeUpdated(minimumRepriceTime, _minimumRepriceTime);

    minimumRepriceTime = _minimumRepriceTime;
  }

  function setMaximumRepricerswETHDifferencePercentage(
    uint256 _maximumRepricerswETHDifferencePercentage
  ) external checkRole(SwellLib.PLATFORM_ADMIN) {
    emit MaximumRepricerswETHDifferencePercentageUpdated(
      maximumRepricerswETHDifferencePercentage,
      _maximumRepricerswETHDifferencePercentage
    );

    maximumRepricerswETHDifferencePercentage = _maximumRepricerswETHDifferencePercentage;
  }

  function setMaximumRepriceDifferencePercentage(
    uint256 _maximumRepriceDifferencePercentage
  ) external checkRole(SwellLib.PLATFORM_ADMIN) {
    emit MaximumRepriceDifferencePercentageUpdated(
      maximumRepriceDifferencePercentage,
      _maximumRepriceDifferencePercentage
    );

    maximumRepriceDifferencePercentage = _maximumRepriceDifferencePercentage;
  }

  function rswETHToETHRate() external view override returns (uint256) {
    return _rswETHToETHRate().unwrap();
  }

  function ethToRswETHRate() external view override returns (uint256) {
    return _ethToRswETHRate().unwrap();
  }

  function getRate() external view override returns (uint256) {
    // This method is identical to rswETHToETHRate but is required for the Balancer Metastable pools. Keeping this and the rswETHToETHRate method because the rswETHToETHRate method is more readable for integrations.
    return _rswETHToETHRate().unwrap();
  }

  function _deposit(address referral) internal {
    if (AccessControlManager.coreMethodsPaused()) {
      revert SwellLib.CoreMethodsPaused();
    }

    if (msg.value == 0) {
      revert SwellLib.InvalidETHDeposit();
    }

    uint256 rswETHAmount = wrap(msg.value).mul(_ethToRswETHRate()).unwrap();

    _mint(msg.sender, rswETHAmount);

    totalETHDeposited += msg.value;

    AddressUpgradeable.sendValue(
      payable(address(AccessControlManager.DepositManager())),
      msg.value
    );

    emit ETHDepositReceived(
      msg.sender,
      msg.value,
      rswETHAmount,
      totalETHDeposited,
      referral
    );
  }

  function deposit() external payable override checkWhitelist(msg.sender) {
    _deposit(address(0));
  }

  function depositWithReferral(
    address referral
  ) external payable override checkWhitelist(msg.sender) {
    if (msg.sender == referral) {
      revert SwellLib.CannotReferSelf();
    }
    _deposit(referral);
  }

  function reprice(
    uint256 _preRewardETHReserves,
    uint256 _newETHRewards,
    uint256 _rswETHTotalSupply
  ) external override checkRole(SwellLib.REPRICER) {
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }
    uint256 currSupply = totalSupply();

    if (_rswETHTotalSupply == 0 || currSupply == 0) {
      revert CannotRepriceWithZeroRswETHSupply();
    }

    if (_preRewardETHReserves == 0) {
      revert InvalidPreRewardETHReserves();
    }

    uint256 timeSinceLastReprice = block.timestamp - lastRepriceUNIX;

    if (timeSinceLastReprice < minimumRepriceTime) {
      revert NotEnoughTimeElapsedForReprice(
        minimumRepriceTime - timeSinceLastReprice
      );
    }

    uint256 totalReserves = _preRewardETHReserves + _newETHRewards;

    uint256 rewardPercentageTotal = swellTreasuryRewardPercentage +
      nodeOperatorRewardPercentage;

    UD60x18 rewardsInETH = wrap(_newETHRewards).mul(
      wrap(rewardPercentageTotal)
    );

    UD60x18 rewardsInRswETH = wrap(_rswETHTotalSupply).mul(rewardsInETH).div(
      wrap(_preRewardETHReserves - rewardsInETH.unwrap() + _newETHRewards)
    );

    // Also including the amount of new rswETH that was minted alongside the provided rswETH total supply
    uint256 updatedRswETHToETHRateFixed = wrap(totalReserves)
      .div(wrap(_rswETHTotalSupply + rewardsInRswETH.unwrap()))
      .unwrap();

    // Ensure that the reprice differences are within expected ranges, only if the reprice method has been called before
    if (lastRepriceUNIX != 0) {
      // Check repricing rate difference
      uint256 repriceDiff = _absolute(
        updatedRswETHToETHRateFixed,
        rswETHToETHRateFixed
      );

      uint256 maximumRepriceDiff = wrap(rswETHToETHRateFixed)
        .mul(wrap(maximumRepriceDifferencePercentage))
        .unwrap();

      if (repriceDiff > maximumRepriceDiff) {
        revert RepriceDifferenceTooLarge(repriceDiff, maximumRepriceDiff);
      }
    }

    // Check rswETH supply provided with actual current supply
    uint256 rswETHSupplyDiff = _absolute(currSupply, _rswETHTotalSupply);

    uint256 maximumrswETHDiff = (currSupply *
      maximumRepricerswETHDifferencePercentage) / 1 ether;

    if (rswETHSupplyDiff > maximumrswETHDiff) {
      revert RepricerswETHDifferenceTooLarge(rswETHSupplyDiff, maximumrswETHDiff);
    }

    uint256 nodeOperatorRewards;
    uint256 swellTreasuryRewards;

    if (rewardsInRswETH.unwrap() != 0) {
      _mint(address(this), rewardsInRswETH.unwrap());

      UD60x18 nodeOperatorRewardPortion = wrap(nodeOperatorRewardPercentage)
        .div(wrap(rewardPercentageTotal));

      nodeOperatorRewards = nodeOperatorRewardPortion
        .mul(rewardsInRswETH)
        .unwrap();

      if (nodeOperatorRewards != 0) {
        INodeOperatorRegistry nodeOperatorRegistry = AccessControlManager
          .NodeOperatorRegistry();

        uint128 totalOperators = nodeOperatorRegistry.numOperators();

        UD60x18 totalActiveValidators = wrap(
          nodeOperatorRegistry.getPoRAddressListLength()
        );

        if (totalActiveValidators.unwrap() == 0) {
          revert NoActiveValidators();
        }

        // Operator Id's start at 1
        for (uint128 i = 1; i <= totalOperators; ) {
          (
            address rewardAddress,
            uint256 operatorActiveValidators
          ) = nodeOperatorRegistry.getRewardDetailsForOperatorId(i);

          if (operatorActiveValidators != 0) {
            uint256 operatorsRewardShare = wrap(operatorActiveValidators)
              .div(totalActiveValidators)
              .mul(wrap(nodeOperatorRewards))
              .unwrap();

            _transfer(address(this), rewardAddress, operatorsRewardShare);
          }

          // Will never overflow as the total operators are capped at uint128
          unchecked {
            ++i;
          }
        }
      }

      // Transfer the remaining tokens to the treasury, this includes the swell treasury percentage and if there are any remainder tokens after NO distribution
      swellTreasuryRewards = balanceOf(address(this));

      if (swellTreasuryRewards != 0) {
        _transfer(
          address(this),
          AccessControlManager.SwellTreasury(),
          swellTreasuryRewards
        );
      }
    }

    lastRepriceETHReserves = totalReserves;
    lastRepriceUNIX = block.timestamp;
    rswETHToETHRateFixed = updatedRswETHToETHRateFixed;

    emit Reprice(
      lastRepriceETHReserves,
      rswETHToETHRateFixed,
      nodeOperatorRewards,
      swellTreasuryRewards,
      totalETHDeposited
    );
  }

  // ************************************
  // ***** Internal methods ******

  /**
   * @dev Returns the ETH -> rswETH rate, if no PoR reading has come through the rate is 1:1
   * @return The rate as a fixed-point type
   */
  function _ethToRswETHRate() internal view returns (UD60x18) {
    return wrap(1 ether).div(_rswETHToETHRate());
  }

  /**
   * @dev Returns the rswETH -> ETH rate, if no PoR reading has come in the rate is 1:1
   * @return The rate as a fixed-point type
   */
  function _rswETHToETHRate() internal view returns (UD60x18) {
    if (rswETHToETHRateFixed == 0) {
      return wrap(1 ether);
    }

    return wrap(rswETHToETHRateFixed);
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
}
