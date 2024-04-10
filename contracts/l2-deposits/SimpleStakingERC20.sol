// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

// External dependencies
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable, Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

// Internal dependencies
import {ISimpleStakingERC20} from "./interfaces/ISimpleStakingERC20.sol";

contract SimpleStakingERC20 is Ownable2Step, ReentrancyGuard, ISimpleStakingERC20 {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                               VARIABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice Mapping of supported tokens
    /// IERC20 address -> bool (true if supported)
    mapping(IERC20 => Supported) public supportedTokens;

    /// @notice Total staked balance for each token
    /// IERC20 address -> uint256 (total staked balance)
    mapping(IERC20 => uint256) public totalStakedBalance;

    /// @notice Staked balances for each user
    /// user address -> IERC20 address -> uint256 (staked balance)
    mapping(address => mapping(IERC20 => uint256)) public stakedBalances;

    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) Ownable(_owner) {}

    /*//////////////////////////////////////////////////////////////
                               RESTRICTED
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISimpleStakingERC20
    function supportToken(IERC20 _token, Supported calldata _supported) external onlyOwner {
        if (address(_token) == address(0)) revert ADDRESS_NULL();

        supportedTokens[_token] = _supported;

        emit SupportedToken(_token, _supported);
    }

    /// @inheritdoc ISimpleStakingERC20
    function rescueERC20(IERC20 _token) external onlyOwner {
        _token.safeTransfer(owner(), _token.balanceOf(address(this)) - totalStakedBalance[_token]);
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISimpleStakingERC20
    function deposit(IERC20 _token, uint256 _amount, address _receiver) external nonReentrant {
        if (_amount == 0) revert AMOUNT_NULL();
        if (_receiver == address(0)) revert ADDRESS_NULL();
        if (!supportedTokens[_token].deposit) revert TOKEN_NOT_ALLOWED(_token);

        uint256 bal = _token.balanceOf(address(this));
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = _token.balanceOf(address(this)) - bal; // To handle deflationary tokens

        totalStakedBalance[_token] += _amount;

        unchecked {
            stakedBalances[_receiver][_token] += _amount;
        }

        emit Deposit(_token, _receiver, _amount);
    }

    /// @inheritdoc ISimpleStakingERC20
    function withdraw(IERC20 _token, uint256 _amount, address _receiver) external nonReentrant {
        if (_amount == 0) revert AMOUNT_NULL();
        if (stakedBalances[msg.sender][_token] < _amount) revert INSUFFICIENT_BALANCE();
        if (_receiver == address(0)) revert ADDRESS_NULL();
        if (!supportedTokens[_token].withdraw) revert TOKEN_NOT_ALLOWED(_token);

        unchecked {
            totalStakedBalance[_token] -= _amount;
            stakedBalances[msg.sender][_token] -= _amount;
        }

        _token.safeTransfer(_receiver, _amount);

        emit Withdraw(_token, msg.sender, _amount);
    }
}
