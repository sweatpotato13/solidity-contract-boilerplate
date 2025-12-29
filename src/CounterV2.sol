// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Counter} from "./Counter.sol";

/**
 * @title CounterV2
 * @notice Upgraded version of Counter with additional decrement functionality
 * @dev Example of an upgraded contract for testing upgrade mechanism
 */
abstract contract CounterV2 is Counter {
    // ============================================
    // EVENTS
    // ============================================

    /**
     * @notice Emitted when a user decrements their counter
     * @param user Address of the user
     * @param newValue New counter value
     * @param timestamp Block timestamp when decrement occurred
     */
    event CounterDecremented(address indexed user, uint256 newValue, uint256 timestamp);

    // ============================================
    // NEW FUNCTIONS IN V2
    // ============================================

    /**
     * @notice Decrement the caller's counter by a specific amount
     * @dev Counter cannot go below zero
     * @param amount Amount to decrement by
     */
    function decrementBy(uint256 amount) external {
        require(counters[msg.sender] >= amount, "CounterV2: insufficient counter value");

        counters[msg.sender] -= amount;

        emit CounterDecremented(msg.sender, counters[msg.sender], block.timestamp);
    }

    /**
     * @notice Get the version of the contract
     * @return Version string
     */
    function version() external pure returns (string memory) {
        return "v2.0.0";
    }
}
