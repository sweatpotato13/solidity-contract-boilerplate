// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ICounterLens
 * @notice Interface for gas-efficient read-only queries for Counter
 * @dev Provides view functions to query counter data and statistics
 */
interface ICounterLens {
    // ============================================
    // STRUCTS
    // ============================================

    /**
     * @notice User-specific statistics
     * @param currentCount Current counter value
     * @param totalIncrements Total number of increments performed
     */
    struct UserStats {
        uint256 currentCount;
        uint256 totalIncrements;
    }

    /**
     * @notice Global statistics
     * @param totalIncrements Total number of increments across all users
     * @param uniqueUsers Number of unique users who have incremented
     */
    struct GlobalStats {
        uint256 totalIncrements;
        uint256 uniqueUsers;
    }

    // ============================================
    // SINGLE USER QUERIES
    // ============================================

    /**
     * @notice Get counter value for a specific user
     * @param counter Address of the Counter contract
     * @param user Address of the user to query
     * @return Current counter value for the user
     */
    function getCount(address counter, address user) external view returns (uint256);

    /**
     * @notice Get statistics for a specific user
     * @param counter Address of the Counter contract
     * @param user Address of the user to query
     * @return stats User statistics including current count and total increments
     */
    function getUserStats(address counter, address user) external view returns (UserStats memory stats);

    // ============================================
    // GLOBAL QUERIES
    // ============================================

    /**
     * @notice Get global counter statistics
     * @param counter Address of the Counter contract
     * @return stats Global statistics including total increments and unique users
     */
    function getGlobalStats(address counter) external view returns (GlobalStats memory stats);

    /**
     * @notice Get multiple users' counter values in a single call
     * @param counter Address of the Counter contract
     * @param users Array of user addresses to query
     * @return counts Array of counter values corresponding to the users array
     */
    function getCountBatch(address counter, address[] calldata users) external view returns (uint256[] memory counts);
}
