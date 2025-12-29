// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title CounterStorage
 * @notice Storage layout for the Counter contract
 * @dev This contract defines the storage layout of the Counter contract.
 *      This contract is inherited by Counter to separate storage concerns and
 *      make the storage layout explicit for upgradeable contracts.
 */
contract CounterStorage {
    // ============================================
    // STATE VARIABLES (V1)
    // ============================================

    /// @notice Mapping of user address to their counter value
    mapping(address => uint256) public counters;

    /// @notice Total number of increments across all users
    uint256 public totalIncrements;

    /// @notice Mapping of user address to their total increment count
    mapping(address => uint256) public userIncrementCount;

    /// @notice Number of unique users who have incremented
    uint256 public uniqueUsers;

    /// @notice Mapping to track if a user has ever incremented (for uniqueUsers count)
    mapping(address => bool) internal _hasIncremented;

    // ============================================
    // STORAGE GAP
    // ============================================

    /**
     * @dev Storage gap for future upgrades
     * @notice Reserves 50 storage slots for future contract upgrades
     * @dev Reduce this gap when adding new storage variables
     */
    uint256[50] private __gap;
}
