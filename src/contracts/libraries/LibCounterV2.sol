// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LibCounterV2
 * @dev Storage library for CounterFacet with extended functionality
 * @notice Provides storage structures and utility functions for the counter system v2
 */
library LibCounterV2 {
    /**
     * @dev Extended storage structure for counter with metadata tracking
     * @param count The current counter value
     * @param lastIncremented Timestamp of the last increment operation
     * @param lastDecremented Timestamp of the last decrement operation
     * @param totalIncrements Total number of increment operations
     * @param totalDecrements Total number of decrement operations
     * @param lastModifier Address of the account that last modified the counter
     */
    struct CounterStorage {
        uint256 count;
        uint256 lastIncremented; // Last increment timestamp
        uint256 lastDecremented; // Last decrement timestamp
        uint256 totalIncrements; // Total number of increments
        uint256 totalDecrements; // Total number of decrements
        address lastModifier; // Address of the last modifier
    }

    /**
     * @dev Storage position for the counter storage structure
     * @notice Position in storage is determined by keccak256 of a unique string
     * @notice Keeps the same key as original to maintain data continuity
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

    /**
     * @dev Initializes the extended counter storage when migrating from v1
     * @notice Sets initial values for new fields if they haven't been set yet
     * @notice Should be called when upgrading from previous counter version
     */
    function migrateStorage() internal {
        CounterStorage storage cs = counterStorage();

        // Initialize data if not already initialized
        if (cs.lastModifier == address(0)) {
            cs.lastIncremented = block.timestamp;
            cs.lastDecremented = block.timestamp;
            cs.totalIncrements = 0;
            cs.totalDecrements = 0;
            cs.lastModifier = msg.sender;
        }
    }
}
