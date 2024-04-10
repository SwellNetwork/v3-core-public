// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IWstETH {
    function approve(address _spender, uint256 _amount) external returns (bool);
    function getWstETHByStETH(uint256 _stETHAmount) external view returns (uint256);
    function stETH() external view returns (address);
    function wrap(uint256 _stETHAmount) external returns (uint256);
}
