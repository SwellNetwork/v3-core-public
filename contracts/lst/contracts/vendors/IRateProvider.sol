// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

/**
 * @title IRateProvider
 * @notice This interface ensure compatibility with Balancer's Metastable pools, the getRate() method is used as the pool rate. This reduces arbitrages whenever the swETH rate increases from a repricing event.
 * @dev https://github.com/balancer-labs/metastable-rate-providers/blob/master/contracts/interfaces/IRateProvider.sol
 */
interface IRateProvider {
  function getRate() external view returns (uint256);
}
