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

import {IswETH} from "../interfaces/IswETH.sol";
import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {INodeOperatorRegistry} from "../interfaces/INodeOperatorRegistry.sol";
import {IRateProvider} from "../vendors/IRateProvider.sol";

/**
 * @title swETH
 * @notice Contract for handling user deposits in ETH in exchange for swETH at the stored rate. Also handles the rate updates from the BOT wallet which will occur at a fixed interval.
 * @author https://github.com/max-taylor
 * @dev This contract inherits the Whitelist contract which holds the Access control manager state variable and the checkRole modifier
 */
contract swETH is
  Initializable,
  Whitelist,
  IswETH,
  IRateProvider,
  ERC20Upgradeable
{
  using SafeERC20 for IERC20;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

  uint256 public override lastRepriceETHReserves;
  uint256 private swETHToETHRateFixed;

  uint256 public override swellTreasuryRewardPercentage;
  uint256 public override nodeOperatorRewardPercentage;

  uint256 public override lastRepriceUNIX;

  uint256 public override totalETHDeposited;

  uint256 public override minimumRepriceTime;
  uint256 public override maximumRepriceDifferencePercentage;
  uint256 public override maximumRepriceswETHDifferencePercentage;

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
    __ERC20_init("swETH", "swETH");

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
    // Joined percentage total cannot exeed 100% (1 ether)
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

  function setMaximumRepriceswETHDifferencePercentage(
    uint256 _maximumRepriceswETHDifferencePercentage
  ) external checkRole(SwellLib.PLATFORM_ADMIN) {
    emit MaximumRepriceswETHDifferencePercentageUpdated(
      maximumRepriceswETHDifferencePercentage,
      _maximumRepriceswETHDifferencePercentage
    );

    maximumRepriceswETHDifferencePercentage = _maximumRepriceswETHDifferencePercentage;
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

  function swETHToETHRate() external view override returns (uint256) {
    return _swETHToETHRate().unwrap();
  }

  function ethToSwETHRate() external view override returns (uint256) {
    return _ethToSwETHRate().unwrap();
  }

  function getRate() external view override returns (uint256) {
    // This method is identical to swETHToETHRate but is required for the Balancer Metastable pools. Keeping this and the swETHToETHRate method because the swETHToETHRate method is more readable for integrations.
    return _swETHToETHRate().unwrap();
  }

  function deposit() external payable override checkWhitelist(msg.sender) {
    if (AccessControlManager.coreMethodsPaused()) {
      revert SwellLib.CoreMethodsPaused();
    }

    if (msg.value == 0) {
      revert SwellLib.InvalidETHDeposit();
    }

    uint256 swETHAmount = wrap(msg.value).mul(_ethToSwETHRate()).unwrap();

    _mint(msg.sender, swETHAmount);

    totalETHDeposited += msg.value;

    AddressUpgradeable.sendValue(
      payable(address(AccessControlManager.DepositManager())),
      msg.value
    );

    emit ETHDepositReceived(
      msg.sender,
      msg.value,
      swETHAmount,
      totalETHDeposited
    );
  }

  function reprice(
    uint256 _preRewardETHReserves,
    uint256 _newETHRewards,
    uint256 _swETHTotalSupply
  ) external override checkRole(SwellLib.BOT) {
    if (AccessControlManager.botMethodsPaused()) {
      revert SwellLib.BotMethodsPaused();
    }

    uint256 currSupply = totalSupply();

    if (_swETHTotalSupply == 0 || currSupply == 0) {
      revert CannotRepriceWithZeroSwETHSupply();
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

    UD60x18 rewardsInSwETH = wrap(_swETHTotalSupply).mul(rewardsInETH).div(
      wrap(_preRewardETHReserves - rewardsInETH.unwrap() + _newETHRewards)
    );

    // Also including the amount of new swETH that was minted alongside the provided swETH total supply
    uint256 updatedSwETHToETHRateFixed = wrap(totalReserves)
      .div(wrap(_swETHTotalSupply + rewardsInSwETH.unwrap()))
      .unwrap();

    // Ensure that the reprice differences are within expected ranges, only if the reprice method has been called before
    if (lastRepriceUNIX != 0) {
      // Check repricing rate difference
      uint256 repriceDiff = _absolute(
        updatedSwETHToETHRateFixed,
        swETHToETHRateFixed
      );

      uint256 maximumRepriceDiff = wrap(swETHToETHRateFixed)
        .mul(wrap(maximumRepriceDifferencePercentage))
        .unwrap();

      if (repriceDiff > maximumRepriceDiff) {
        revert RepriceDifferenceTooLarge(repriceDiff, maximumRepriceDiff);
      }
    }

    // Check swETH supply provided with actual current supply
    uint256 swETHSupplyDiff = _absolute(currSupply, _swETHTotalSupply);

    uint256 maximumswETHDiff = (currSupply *
      maximumRepriceswETHDifferencePercentage) / 1 ether;

    if (swETHSupplyDiff > maximumswETHDiff) {
      revert RepriceswETHDifferenceTooLarge(swETHSupplyDiff, maximumswETHDiff);
    }

    uint256 nodeOperatorRewards;
    uint256 swellTreasuryRewards;

    if (rewardsInSwETH.unwrap() != 0) {
      _mint(address(this), rewardsInSwETH.unwrap());

      UD60x18 nodeOperatorRewardPortion = wrap(nodeOperatorRewardPercentage)
        .div(wrap(rewardPercentageTotal));

      nodeOperatorRewards = nodeOperatorRewardPortion
        .mul(rewardsInSwETH)
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
    swETHToETHRateFixed = updatedSwETHToETHRateFixed;

    emit Reprice(
      lastRepriceETHReserves,
      swETHToETHRateFixed,
      nodeOperatorRewards,
      swellTreasuryRewards,
      totalETHDeposited
    );
  }

  // ************************************
  // ***** Internal methods ******

  /**
   * @dev Returns the ETH -> swETH rate, if no PoR reading has come through the rate is 1:1
   * @return The rate as a fixed-point type
   */
  function _ethToSwETHRate() internal view returns (UD60x18) {
    return wrap(1 ether).div(_swETHToETHRate());
  }

  /**
   * @dev Returns the swETH -> ETH rate, if no PoR reading has come in the rate is 1:1
   * @return The rate as a fixed-point type
   */
  function _swETHToETHRate() internal view returns (UD60x18) {
    if (swETHToETHRateFixed == 0) {
      return wrap(1 ether);
    }

    return wrap(swETHToETHRateFixed);
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
