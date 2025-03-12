// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LibCounterV2
 * @dev Storage library for CounterFacet with extended functionality
 */
library LibCounterV2 {
    struct CounterStorage {
        uint256 count;
        uint256 lastIncremented; // Last increment timestamp
        uint256 lastDecremented; // Last decrement timestamp
        uint256 totalIncrements; // Total number of increments
        uint256 totalDecrements; // Total number of decrements
        address lastModifier; // Address of the last modifier
    }

    // Position in storage is determined by keccak256 of a unique string - Keep the same key as original
    bytes32 constant COUNTER_STORAGE_POSITION = keccak256("diamond.counter.storage");

    // Returns the struct from a specified position in contract storage
    function counterStorage() internal pure returns (CounterStorage storage cs) {
        bytes32 position = COUNTER_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    // Storage migration function
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
