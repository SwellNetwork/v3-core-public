// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IWETH} from "./interfaces/IWETH.sol";
import {IWeETH} from "./interfaces/IWeETH.sol";
import {IWstETH} from "./interfaces/IWstETH.sol";
import {ISimpleStakingERC20} from "./interfaces/ISimpleStakingERC20.sol";

contract Zap {
    IWETH public immutable weth;
    IERC20 public immutable eETH;
    IERC20 public immutable stETH;
    IWeETH public immutable weETH;
    IWstETH public immutable wstETH;
    ISimpleStakingERC20 public immutable stakingContract;

    constructor(address payable _weth, address _wstETH, address _weETH, address _stakingContract) {
        weth = IWETH(_weth);
        weETH = IWeETH(_weETH);
        wstETH = IWstETH(_wstETH);
        eETH = IERC20(weETH.eETH());
        stETH = IERC20(wstETH.stETH());
        stakingContract = ISimpleStakingERC20(_stakingContract);

        eETH.approve(address(weETH), type(uint256).max);
        weth.approve(_stakingContract, type(uint256).max);
        stETH.approve(address(wstETH), type(uint256).max);
        weETH.approve(address(stakingContract), type(uint256).max);
        wstETH.approve(address(stakingContract), type(uint256).max);
    }

    function ethZapIn() external payable {
        if (msg.value == 0) revert ISimpleStakingERC20.AMOUNT_NULL();
        // Wrap ETH to wETH
        weth.deposit{value: msg.value}();

        // Deposit wETH to staking contract
        stakingContract.deposit(IERC20(address(weth)), msg.value, msg.sender);
    }

    function stETHZapIn(uint256 _amount) external {
        if (_amount == 0) revert ISimpleStakingERC20.AMOUNT_NULL();
        // Transfer stETH from msg.sender to this contract, sometimes 1 or 2 wei can be missing.
        stETH.transferFrom(msg.sender, address(this), _amount);

        // Deposit wstETH to staking contract
        stakingContract.deposit(IERC20(address(wstETH)), wstETH.wrap(stETH.balanceOf(address(this))), msg.sender);
    }

    function eETHZapIn(uint256 _amount) external {
        if (_amount == 0) revert ISimpleStakingERC20.AMOUNT_NULL();
        // Transfer eETH from msg.sender to this contract, sometimes 1 or 2 wei can be missing.
        eETH.transferFrom(msg.sender, address(this), _amount);

        // Deposit eETH to staking contract
        stakingContract.deposit(IERC20(address(weETH)), weETH.wrap(eETH.balanceOf(address(this))), msg.sender);
    }
}
