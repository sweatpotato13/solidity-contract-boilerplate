// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LibCounter
 * @dev Storage library for Counter facet
 */
library LibCounter {
    struct CounterStorage {
        uint256 count;
    }

    // Position in storage is determined by keccak256 of a unique string
    bytes32 constant COUNTER_STORAGE_POSITION = keccak256("diamond.counter.storage");

    // Returns the struct from a specified position in contract storage
    function counterStorage() internal pure returns (CounterStorage storage cs) {
        bytes32 position = COUNTER_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
}
