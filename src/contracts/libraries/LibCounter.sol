// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LibCounter
 * @dev Storage library for Counter facet
 * @notice Provides the storage structure and utility functions for the basic counter system
 */
library LibCounter {
    /**
     * @dev Storage structure for the counter
     * @param count The current counter value
     */
    struct CounterStorage {
        uint256 count;
    }

    /**
     * @dev Storage position for the counter storage structure
     * @notice Position in storage is determined by keccak256 of a unique string
     */
    bytes32 constant COUNTER_STORAGE_POSITION = keccak256("diamond.counter.storage");

    /**
     * @dev Retrieves the counter storage structure
     * @return cs The CounterStorage struct from a specified position in contract storage
     */
    function counterStorage() internal pure returns (CounterStorage storage cs) {
        bytes32 position = COUNTER_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
}
