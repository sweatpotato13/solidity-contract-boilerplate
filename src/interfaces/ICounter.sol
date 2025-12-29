// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title ICounter
 * @notice Interface for the upgradeable counter contract
 * @dev Simple counter where each user can increment their own counter
 */
interface ICounter {
    // ============================================
    // EVENTS
    // ============================================

    /**
     * @notice Emitted when a user increments their counter
     * @param user Address of the user
     * @param newValue New counter value
     * @param timestamp Block timestamp when increment occurred
     */
    event CounterIncremented(address indexed user, uint256 newValue, uint256 timestamp);

    // ============================================
    // USER FUNCTIONS
    // ============================================

    /**
     * @notice Increment the caller's counter by 1
     * @dev Increases msg.sender's counter and updates global statistics
     */
    function increment() external;
}
