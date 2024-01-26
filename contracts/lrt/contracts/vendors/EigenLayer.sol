// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.16;

interface IEigenPodManager {
  function createPod() external;
  function getPod(address podOwner) external view returns (IEigenPod);
}

interface IEigenPod {}
