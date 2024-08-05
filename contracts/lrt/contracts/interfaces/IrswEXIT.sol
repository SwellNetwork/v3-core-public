// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

import {IERC721Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title RswEXIT Interface
 * @dev This interface provides the methods to interact with the SwEXIT contract.
 */
interface IrswEXIT is IERC721Upgradeable {
  /**
   * @dev Struct representing a withdrawal request.
   * @param timestamp The timestamp of the withdrawal request.
   * @param amount The amount of RswETH that was requested to be withdrawn.
   * @param lastTokenIdProcessed The last token ID processed when the withdraw request was created, required later on when fetching the rates.
   * @param rateWhenCreated The rate when the withdrawal request was created.
   */
  struct WithdrawRequest {
    uint256 amount;
    uint256 lastTokenIdProcessed;
    uint256 rateWhenCreated;
  }

  /**
   * @dev Thrown when the withdrawal request is too large
   * @param amount The withdrawal request amount.
   * @param limit The withdrawal request limit.
   */
  error WithdrawRequestTooLarge(uint256 amount, uint256 limit);

  /**
   * @dev Thrown when the withdrawal request amount is less than the minimum.
   * @param amount The withdrawal request amount.
   * @param minimum The withdrawal request minimum.
   */
  error WithdrawRequestTooSmall(uint256 amount, uint256 minimum);

  /**
   * @dev Thrown when trying to claim withdrawals for a token that doesn't exist
   */
  error WithdrawalRequestDoesNotExist();

  /**
   * @dev Thrown when trying to claim withdrawals and the requested token has not been processed.
   */
  error WithdrawalRequestNotProcessed();

  /**
   * @dev Thrown when processing withdrawals and the provided _lastRequestIdToProcess hasn't been minted
   */
  error CannotProcessWithdrawalsForNonExistentToken();

  /**
   * @dev Thrown when processing withdrawals and the provided _lastRequestIdToProcess is less than the previous token ID processed
   */
  error LastTokenIdToProcessMustBeGreaterOrEqualThanPrevious();

  /**
   * @dev Thrown when calling a withdrawal method and the withdrawals are paused.
   */
  error WithdrawalsPaused();

  /**
   * @dev Thrown when trying to update the withdrawal request minimum to be less than the withdrawal request maximum.
   */
  error WithdrawRequestMinimumMustBeLessOrEqualToMaximum();

  /**
   * @dev Thrown when trying to update the withdrawal request maximum to be less than the withdrawal request minimum.
   */
  error WithdrawRequestMaximumMustBeGreaterOrEqualToMinimum();

  /**
   * @dev Thrown when anyone except the owner tries to finalize a withdrawal request
   */
  error WithdrawalRequestFinalizationOnlyAllowedForNFTOwner();

  /**
   * @dev Emitted when the base URI is updated.
   * @param oldBaseURI The old base URI.
   * @param newBaseURI The new base URI.
   */
  event BaseURIUpdated(string oldBaseURI, string newBaseURI);

  /**
   * @dev Emitted when a withdrawal request is created.
   * @param tokenId The token ID of the withdrawal request.
   * @param amount The amount of RswETH to withdraw.
   * @param timestamp The timestamp of the withdrawal request.
   * @param lastTokenIdProcessed The last token ID processed, required later on when fetching the rates.
   * @param rateWhenCreated The rate when the withdrawal request was created.
   * @param owner The owner of the withdrawal request.
   */
  event WithdrawRequestCreated(
    uint256 tokenId,
    uint256 amount,
    uint256 timestamp,
    uint256 indexed lastTokenIdProcessed,
    uint256 rateWhenCreated,
    address indexed owner
  );

  /**
   * @dev Emitted when a withdrawal request is claimed.
   * @param owner The owner of the withdrawal request.
   * @param tokenId The token ID of the withdrawal request.
   * @param exitClaimedETH The amount of ETH the owner received.
   */
  event WithdrawalClaimed(
    address indexed owner,
    uint256 tokenId,
    uint256 exitClaimedETH
  );

  /**
   * @dev Emitted when withdrawals are processed.
   * @param fromTokenId The first token ID to process.
   * @param toTokenId The last token ID to process.
   * @param processedRate The rate that the withdrawal requests were processed at, not the finalised rate when claiming just the processed rate
   * @param processedExitingETH The amount of exiting ETH accumulated when processing withdrawals.
   * @param processedExitedETH The amount of exited ETH accumulated when processing withdrawals.
   */
  event WithdrawalsProcessed(
    uint256 fromTokenId,
    uint256 toTokenId,
    uint256 processedRate,
    uint256 processedExitingETH,
    uint256 processedExitedETH
  );

  /**
   * @dev Emitted when the withdrawal request limit is updated.
   * @param oldLimit The old withdrawal request limit.
   * @param newLimit The new withdrawal request limit.
   */
  event WithdrawalRequestMaximumUpdated(uint256 oldLimit, uint256 newLimit);

  /**
   * @dev Emitted when the withdrawal request minimum is updated.
   * @param oldMinimum The old withdrawal request minimum.
   * @param newMinimum The new withdrawal request minimum.
   */
  event WithdrawalRequestMinimumUpdated(uint256 oldMinimum, uint256 newMinimum);

  /**
   * @dev Emitted when ETH is received.
   * @param sender The sender of the ETH.
   * @param amount The amount of ETH received.
   */
  event ETHReceived(address indexed sender, uint256 amount);

  /**
   * @dev Returns the base URI.
   */
  function baseURI() external view returns (string memory);

  /**
   * @dev This method withdraws contract's _token balance to a platform admin
   * @param _token The ERC20 token to withdraw from the contract
   */
  function withdrawERC20(IERC20 _token) external;

  /**
   * @dev Returns the withdrawal request maximum size.
   * @return The withdrawal request maximum size.
   */
  function withdrawRequestMaximum() external view returns (uint256);

  /**
   * @dev Returns the withdrawal request minimum.
   * @return The withdrawal request minimum.
   */
  function withdrawRequestMinimum() external view returns (uint256);

  /**
   * @dev Returns the amount of exiting ETH, which is has not yet been processed for withdrawals.
   * @dev This value is increased by new withdrawal requests and decreased when withdrawals are processed.
   * @dev The amount is given by (amount * rate when requested), where amount is the amount of withdrawn rswETH.
   * @return The current amount of exiting ETH.
   */
  function exitingETH() external view returns (uint256);

  /**
   * @dev Returns the total amount of exited ETH to date. Exited ETH is ETH that was processed in a withdrawal request.
   * @dev When ETH is processed in a withdrawal request, the amount of exited ETH is given by (amount * finalRate), where finalRate is the lesser of the rate when requested and the processed rate, and amount is the amount of withdrawn rswETH.
   * @return The exited ETH.
   */
  function totalETHExited() external view returns (uint256);

  /**
   * @dev Allows the platform admin to update the base URI.
   * @param _baseURI The new base URI.
   */
  function setBaseURI(string memory _baseURI) external;

  /**
   * @dev Allows the platform admin to update the withdrawal request maximum.
   * @param _withdrawRequestMaximum The new withdrawal request maximum.
   */
  function setWithdrawRequestMaximum(uint256 _withdrawRequestMaximum) external;

  /**
   * @dev Allows the platform admin to update the withdrawal request minimum.
   * @param _withdrawRequestMinimum The new withdrawal request minimum.
   */
  function setWithdrawRequestMinimum(uint256 _withdrawRequestMinimum) external;

  /**
   * @dev Processes withdrawals for a given range of token IDs.
   * @param _lastTokenIdToProcess The last token Id to process.
   */
  function processWithdrawals(uint256 _lastTokenIdToProcess) external;

  /**
   * @dev Creates a new withdrawal request.
   * @param amount The amount of RswETH to withdraw.
   */
  function createWithdrawRequest(uint256 amount) external;

  /**
   * @dev Finalizes a withdrawal request, sending the ETH to the owner of the request. This is callable by anyone.
   * @param tokenId The token ID of the withdrawal request to claim.
   */
  function finalizeWithdrawal(uint256 tokenId) external;

  /**
   * @dev Checks if the provided token ID has been processed and returns the rate it was processed at. NOTE: This isn't the final rate that the user will receive, it's just the rate that the withdrawal request was processed at.
   * @param tokenId The token ID to check.
   * @return isProcessed A boolean indicating whether or not the token ID has been processed.
   * @return processedRate The processed rate for the given token ID.
   */
  function getProcessedRateForTokenId(
    uint256 tokenId
  ) external view returns (bool isProcessed, uint256 processedRate);

  /**
   * @dev Returns the last token ID that was processed.
   * @return The last token ID processed.
   */
  function getLastTokenIdProcessed() external view returns (uint256);

  /**
   * @dev Returns the last token ID that was created.
   * @return The last token ID created.
   */
  function getLastTokenIdCreated() external view returns (uint256);
}
