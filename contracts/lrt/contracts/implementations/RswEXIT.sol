// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {wrap} from "@prb/math/src/UD60x18.sol";
import {ERC721EnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import {EnumerableMapUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
import {EnumerableSetUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import {IrswEXIT} from "../interfaces/IrswEXIT.sol";
import {IrswETH} from "../interfaces/IrswETH.sol";
import {IAccessControlManager} from "../interfaces/IAccessControlManager.sol";
import {SwellLib} from "../libraries/SwellLib.sol";
import {Whitelist} from "./Whitelist.sol";
import {AddressUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @title rswEXIT
 * @author https://github.com/max-taylor
 * @dev This contract will be handling the; creating, processing and claiming of withdraw requests. Withdraw requests have their own ERC721 token and the ID of that token links to a WithdrawRequest struct within a mapping, this struct contains all the necessary metadata to manage withdraw requests.
 */
contract RswEXIT is IrswEXIT, ERC721EnumerableUpgradeable, Whitelist {
  using SafeERC20 for IERC20;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using EnumerableMapUpgradeable for EnumerableMapUpgradeable.Bytes32ToUintMap;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.Bytes32Set;

  // Using a Bytes32ToUintMap here because they don't support uint256 -> uint256 map, could create one but far simpler to use this and caste to and from bytes32
  EnumerableMapUpgradeable.Bytes32ToUintMap processedTokenIdToRate;

  uint256 private _lastTokenIdCreated;

  // Mapping of tokenId's to their associated WithdrawRequests
  mapping(uint256 => WithdrawRequest) public withdrawalRequests;

  uint256 public override withdrawRequestMaximum;
  uint256 public override withdrawRequestMinimum;

  uint256 public override exitingETH;
  uint256 public override totalETHExited;

  string public override baseURI;

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  fallback() external {
    revert SwellLib.InvalidMethodCall();
  }

  receive() external payable {
    emit ETHReceived(msg.sender, msg.value);
  }

  function initialize(
    IAccessControlManager _accessControlManager
  ) external initializer checkZeroAddress(address(_accessControlManager)) {
    __ERC721_init("rswEXIT", "rswEXIT");

    __Whitelist_init(_accessControlManager);
  }

  // ************************************
  // ***** External methods *************

  function withdrawERC20(
    IERC20 _token
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    uint256 contractBalance = _token.balanceOf(address(this));
    if (contractBalance == 0) {
      revert SwellLib.NoTokensToWithdraw();
    }

    _token.safeTransfer(msg.sender, contractBalance);
  }

  function setWithdrawRequestMaximum(
    uint256 _withdrawRequestMaximum
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    if (_withdrawRequestMaximum < withdrawRequestMinimum) {
      revert WithdrawRequestMaximumMustBeGreaterOrEqualToMinimum();
    }

    emit WithdrawalRequestMaximumUpdated(
      withdrawRequestMaximum,
      _withdrawRequestMaximum
    );

    withdrawRequestMaximum = _withdrawRequestMaximum;
  }

  function setWithdrawRequestMinimum(
    uint256 _withdrawRequestMinimum
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    if (_withdrawRequestMinimum > withdrawRequestMaximum) {
      revert WithdrawRequestMinimumMustBeLessOrEqualToMaximum();
    }

    emit WithdrawalRequestMinimumUpdated(
      withdrawRequestMinimum,
      _withdrawRequestMinimum
    );

    withdrawRequestMinimum = _withdrawRequestMinimum;
  }

  function setBaseURI(
    string memory _updatedBaseURI
  ) external override checkRole(SwellLib.PLATFORM_ADMIN) {
    emit BaseURIUpdated(_baseURI(), _updatedBaseURI);

    baseURI = _updatedBaseURI;
  }

  function processWithdrawals(
    uint256 _lastTokenIdToProcess
  ) external override checkRole(SwellLib.PROCESS_WITHDRAWALS) {
    uint256 lastTokenIdProcessed = getLastTokenIdProcessed();

    if (_lastTokenIdToProcess < lastTokenIdProcessed) {
      revert LastTokenIdToProcessMustBeGreaterOrEqualThanPrevious();
    }

    uint256 requestsToProcess = _lastTokenIdToProcess - lastTokenIdProcessed;

    if (requestsToProcess == 0) return;

    // Ensure that the lastRequestIdToProcess is minted
    if (_ownerOf(_lastTokenIdToProcess) == address(0)) {
      revert CannotProcessWithdrawalsForNonExistentToken();
    }

    uint256 processedRate = AccessControlManager.rswETH().rswETHToETHRate();

    processedTokenIdToRate.set(bytes32(_lastTokenIdToProcess), processedRate);

    // Increment these memory counters and commit them to storage at the end of the loop
    uint256 processedExitedETH;
    uint256 processedExitingETH;

    // Increment the requestsToProcess counter so we can iterate over the requests
    ++requestsToProcess;

    // Iterate over each request calculating totals for exited / exiting ETH
    for (uint256 i = 1; i < requestsToProcess; ) {
      uint256 tokenId = lastTokenIdProcessed + i;

      uint256 amount = withdrawalRequests[tokenId].amount;
      uint256 rateWhenCreated = withdrawalRequests[tokenId].rateWhenCreated;

      // The final rate when claiming the request is the lesser of the processed rate and the rate when the request was created
      uint256 finalRate = processedRate > rateWhenCreated
        ? rateWhenCreated
        : processedRate;

      uint256 requestExitingETH = wrap(amount)
        .mul(wrap(rateWhenCreated))
        .unwrap();

      uint256 requestExitedETH = wrap(amount).mul(wrap(finalRate)).unwrap();

      processedExitingETH += requestExitingETH;
      processedExitedETH += requestExitedETH;

      unchecked {
        ++i;
      }
    }

    // Update these counters as the ETH is now processed
    exitingETH -= processedExitingETH;
    totalETHExited += processedExitedETH;

    // Transfer the ETH to swEXIT for holding
    AccessControlManager.DepositManager().transferETHForWithdrawRequests(
      processedExitedETH
    );

    emit WithdrawalsProcessed(
      lastTokenIdProcessed + 1,
      _lastTokenIdToProcess,
      processedRate,
      processedExitingETH,
      processedExitedETH
    );
  }

  function createWithdrawRequest(
    uint256 amount
  ) external override checkWhitelist(msg.sender) {
    if (AccessControlManager.withdrawalsPaused()) {
      revert WithdrawalsPaused();
    }

    uint256 cachedWithdrawRequestMinimum = withdrawRequestMinimum;

    if (amount < cachedWithdrawRequestMinimum) {
      revert WithdrawRequestTooSmall(amount, cachedWithdrawRequestMinimum);
    }

    uint256 cachedWithdrawRequestMaximum = withdrawRequestMaximum;

    if (amount > cachedWithdrawRequestMaximum) {
      revert WithdrawRequestTooLarge(amount, cachedWithdrawRequestMaximum);
    }

    IrswETH rswETH = AccessControlManager.rswETH();

    // Cast the swETH to IERC20Upgradeable to use the safeTransferFrom method
    IERC20Upgradeable(rswETH).safeTransferFrom(
      msg.sender,
      address(this),
      amount
    );

    // Burn the tokens first to prevent reentrancy and to validate they own the requested amount of swETH
    rswETH.burn(amount);

    uint256 tokenId = ++_lastTokenIdCreated;

    uint256 lastTokenIdProcessed = getLastTokenIdProcessed();

    uint256 rateWhenCreated = AccessControlManager.rswETH().rswETHToETHRate();

    withdrawalRequests[tokenId] = WithdrawRequest({
      amount: amount,
      lastTokenIdProcessed: lastTokenIdProcessed,
      rateWhenCreated: rateWhenCreated
    });

    exitingETH += wrap(amount).mul(wrap(rateWhenCreated)).unwrap();

    _safeMint(msg.sender, tokenId);

    emit WithdrawRequestCreated(
      tokenId,
      amount,
      block.timestamp,
      lastTokenIdProcessed,
      rateWhenCreated,
      msg.sender
    );
  }

  function finalizeWithdrawal(uint256 tokenId) external override {
    if (AccessControlManager.withdrawalsPaused()) {
      revert WithdrawalsPaused();
    }

    address owner = _ownerOf(tokenId);

    if (!_exists(tokenId)) {
      revert WithdrawalRequestDoesNotExist();
    }

    if (owner != msg.sender) {
      revert WithdrawalRequestFinalizationOnlyAllowedForNFTOwner();
    }

    (bool isProcessed, uint256 processedRate) = getProcessedRateForTokenId(
      tokenId
    );

    if (!isProcessed) {
      revert WithdrawalRequestNotProcessed();
    }

    uint256 rateWhenCreated = withdrawalRequests[tokenId].rateWhenCreated;

    uint256 finalRate = processedRate > rateWhenCreated
      ? rateWhenCreated
      : processedRate;

    uint256 ethClaim = wrap(withdrawalRequests[tokenId].amount)
      .mul(wrap(finalRate))
      .unwrap();

    _burn(tokenId);

    AddressUpgradeable.sendValue(payable(owner), ethClaim);

    emit WithdrawalClaimed(owner, tokenId, ethClaim);
  }

  // ************************************
  // ***** Public methods *************

  function getProcessedRateForTokenId(
    uint256 tokenId
  ) public view override returns (bool isProcessed, uint256 processedRate) {
    if (tokenId == 0) {
      return (false, 0);
    }

    uint256 processedTokenIdToRateLengthCache = processedTokenIdToRate.length();

    if (processedTokenIdToRateLengthCache == 0) {
      return (false, 0);
    }

    uint256 lastProcessedTokenId = uint256(
      processedTokenIdToRate._inner._keys.at(
        processedTokenIdToRateLengthCache - 1
      )
    );

    if (lastProcessedTokenId < tokenId) {
      return (false, 0);
    }

    // Binary search for the lowest processed token ID that is greater than or equal to tokenId
    uint256 lowerBound = processedTokenIdToRate._inner._keys._inner._indexes[
      bytes32(withdrawalRequests[tokenId].lastTokenIdProcessed)
    ];
    uint256 upperBound = processedTokenIdToRateLengthCache - 1;

    uint256 foundProcessedTokenId = 0;

    while (upperBound >= lowerBound) {
      uint256 mid = lowerBound + ((upperBound - lowerBound) / 2);

      uint256 nextProcessedTokenId = uint256(
        processedTokenIdToRate._inner._keys.at(mid)
      );

      if (tokenId > nextProcessedTokenId) {
        lowerBound = mid + 1; // Increase the lower bound
      } else {
        foundProcessedTokenId = nextProcessedTokenId;
        if (mid == 0 || lowerBound == upperBound) {
          break; // Found the lowest possible processed token ID greater than or equal to tokenId
        }
        upperBound = mid - 1; // Decrease the upper bound
      }
    }

    processedRate = processedTokenIdToRate.get(bytes32(foundProcessedTokenId));

    return (true, processedRate);
  }

  function getLastTokenIdProcessed() public view override returns (uint256) {
    uint256 processedTokenIdToRateLengthCache = processedTokenIdToRate.length();

    if (processedTokenIdToRateLengthCache == 0) {
      return 0;
    }

    return
      uint256(
        processedTokenIdToRate._inner._keys.at(
          processedTokenIdToRateLengthCache - 1
        )
      );
  }

  function getLastTokenIdCreated() public view override returns (uint256) {
    return _lastTokenIdCreated;
  }

  // ************************************
  // ***** Internal methods *************

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}
