// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IWeETH {
    function approve(address _spender, uint256 _amount) external returns (bool);
    function eETH() external view returns (address);
    function liquidityPool() external view returns (address);
    function wrap(uint256 _stETHAmount) external returns (uint256);
}
