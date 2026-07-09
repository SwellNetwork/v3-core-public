// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IStaking {
    /// @notice Request to unlock token.
    /// @param amount Amount of token to withdraw.
    /// @param unlockTime Timestamp when the token will be unlocked.
    struct Request {
        uint256 amount;
        uint256 unlockTime;
    }

    /// @notice error emitted when address is null.
    error ADDRESS_NULL();

    /// @notice error emitted when amount is null.
    error AMOUNT_NULL();

    /// @notice error emitted when balance is insufficient.
    error INSUFFICIENT_BALANCE();

    /// @notice error emitted when max requests is reached.
    error MAX_REQUESTS_REACHED();

    /// @notice event emitted when cooldown time is updated.
    event CooldownUpdated(uint256 oldCoooldown, uint256 newCooldownTime);

    /// @notice event emitted when token are locked.
    event Lock(address indexed account, uint256 amount);

    /// @notice event emitted when request to unlock token is made.
    event RequestUnlock(address indexed account, uint256 amount, uint256 unlockTime);

    /// @notice event emitted when token are unlocked.
    event Unlock(address indexed account, uint256 amount);

    /// @notice Get the max requests.
    /// @return The max requests allowed.
    function MAX_REQUESTS() external view returns (uint256);

    /// @notice Get the staking token address.
    /// @return The staking token address.
    function TOKEN() external view returns (address);

    /// @notice Get the balance of staked token of an account.
    /// @dev Doesn't take into account token in unlock requests.
    /// @return The balance of staked token of an account.
    function balanceOf(address) external view returns (uint256);

    /// @notice Clean empty request, i.e. when request has been unlocked.
    function cleanEmptyRequest() external;

    /// @notice Get the cooldown time.
    /// @return The cooldown time duration.
    function cooldownTime() external view returns (uint256);

    /// @notice Get the unlock requests of an account.
    /// @param _account The account address.
    /// @return The list of unlock requests.
    function getUnlockRequests(address _account) external view returns (Request[] memory);

    /// @notice Lock token.
    /// @param _account The account address to lock for.
    /// @param _amount The amount of token to lock.
    function lock(address _account, uint256 _amount) external;

    /// @notice Request to unlock token.
    /// @param _amount Amount of token to withdraw.
    function requestUnlock(uint256 _amount) external;

    /// @notice Set the cooldown duration.
    /// @param _duration The new cooldown duration is seconds.
    function setCooldownDuration(uint256 _duration) external;

    /// @notice Get the total supply of staked token.
    /// @dev The total supply is the sum of all balance of staked token.
    /// @dev Doesn't necessarily match the total amount of token in this contract.
    /// @return The total supply of staked token.
    function totalSupply() external view returns (uint256);

    /// @notice Unlock token.
    /// @dev List of request can contain empty request, i.e. request with amount 0.
    function unlock() external;
}
