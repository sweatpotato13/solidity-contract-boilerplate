// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibDiamond.sol";
import "../libraries/LibCounterV2.sol";

/**
 * @title CounterFacetV3
 * @dev Version of CounterFacet that uses extended storage structure
 * @notice Provides enhanced counter functions with additional metadata tracking
 */
contract CounterFacetV3 {
    /**
     * @dev Access to counter storage
     * @return The counter storage struct
     */
    function getCounterStorage() internal pure returns (LibCounterV2.CounterStorage storage) {
        return LibCounterV2.counterStorage();
    }

    /**
     * @dev Function for initial migration from v2 to v3
     * @notice Only the contract owner can call this function
     */
    function initializeV3() external {
        LibDiamond.enforceIsContractOwner(); // Only owner can initialize
        LibCounterV2.migrateStorage();
    }

    /**
     * @dev Get the current counter value
     * @return The current counter value
     */
    function getCount() external view returns (uint256) {
        return getCounterStorage().count;
    }

    /**
     * @dev Increment the counter by 3 with extended functionality
     * @notice Updates timestamp, increment count, and modifier address
     * @notice Emits CounterIncremented event
     */
    function increment() external {
        LibCounterV2.CounterStorage storage cs = getCounterStorage();
        cs.count += 3;
        cs.lastIncremented = block.timestamp;
        cs.totalIncrements += 1; // Single operation
        cs.lastModifier = msg.sender;

        emit CounterIncremented(cs.count, cs.totalIncrements, msg.sender);
    }

    /**
     * @dev Decrement the counter by 3 with extended functionality
     * @notice Updates timestamp, decrement count, and modifier address
     * @notice Emits CounterDecremented event
     * @notice The counter cannot go below zero
     */
    function decrement() external {
        LibCounterV2.CounterStorage storage cs = getCounterStorage();
        require(cs.count > 0, "Count cannot be negative");
        cs.count -= 3;
        cs.lastDecremented = block.timestamp;
        cs.totalDecrements += 1; // Single operation
        cs.lastModifier = msg.sender;

        emit CounterDecremented(cs.count, cs.totalDecrements, msg.sender);
    }

    /**
     * @dev Set the counter to a specific value
     * @param _count The new counter value
     * @notice Only the contract owner can call this function
     * @notice Emits CounterSet event with old and new values
     */
    function setCount(uint256 _count) external {
        LibDiamond.enforceIsContractOwner(); // Only owner can set count
        uint256 oldCount = getCounterStorage().count;
        getCounterStorage().count = _count;
        getCounterStorage().lastModifier = msg.sender;

        emit CounterSet(oldCount, _count, msg.sender);
    }

    /**
     * @dev Increment counter by 6 (doubled from standard increment)
     * @notice Updates timestamp, increment count, and modifier address
     * @notice Considered as a single operation for totalIncrements counter
     * @notice Emits CounterIncremented event
     */
    function doubleIncrement() external {
        LibCounterV2.CounterStorage storage cs = getCounterStorage();
        cs.count += 6;
        cs.lastIncremented = block.timestamp;
        cs.totalIncrements += 1; // Considered as a single operation
        cs.lastModifier = msg.sender;

        emit CounterIncremented(cs.count, cs.totalIncrements, msg.sender);
    }

    /**
     * @dev Check if counter is a multiple of a given number
     * @param _number The number to check division by
     * @return True if the counter is a multiple of the given number, false otherwise
     * @notice Reverts if _number is zero
     */
    function isMultipleOf(uint256 _number) external view returns (bool) {
        require(_number != 0, "Cannot divide by zero");
        return getCounterStorage().count % _number == 0;
    }

    /**
     * @dev Get comprehensive counter information
     * @return count The current counter value
     * @return lastIncremented Timestamp of the last increment operation
     * @return lastDecremented Timestamp of the last decrement operation
     * @return totalIncrements Total number of increment operations
     * @return totalDecrements Total number of decrement operations
     * @return lastModifier Address that last modified the counter
     */
    function getCounterInfo()
        external
        view
        returns (
            uint256 count,
            uint256 lastIncremented,
            uint256 lastDecremented,
            uint256 totalIncrements,
            uint256 totalDecrements,
            address lastModifier
        )
    {
        LibCounterV2.CounterStorage storage cs = getCounterStorage();
        return
            (cs.count, cs.lastIncremented, cs.lastDecremented, cs.totalIncrements, cs.totalDecrements, cs.lastModifier);
    }

    /**
     * @dev Get timestamp of last increment operation
     * @return Timestamp of the last increment
     */
    function getLastIncrementTime() external view returns (uint256) {
        return getCounterStorage().lastIncremented;
    }

    /**
     * @dev Get timestamp of last decrement operation
     * @return Timestamp of the last decrement
     */
    function getLastDecrementTime() external view returns (uint256) {
        return getCounterStorage().lastDecremented;
    }

    /**
     * @dev Get total number of increment operations
     * @return The total number of increments
     */
    function getTotalIncrements() external view returns (uint256) {
        return getCounterStorage().totalIncrements;
    }

    /**
     * @dev Get total number of decrement operations
     * @return The total number of decrements
     */
    function getTotalDecrements() external view returns (uint256) {
        return getCounterStorage().totalDecrements;
    }

    /**
     * @dev Get address of last account that modified the counter
     * @return The address of the last modifier
     */
    function getLastModifier() external view returns (address) {
        return getCounterStorage().lastModifier;
    }

    /**
     * @dev Emitted when counter is incremented
     * @param newCount The new counter value after incrementing
     * @param totalIncrements The total number of increment operations performed
     * @param modifierAddress The address that performed the increment
     */
    event CounterIncremented(uint256 newCount, uint256 totalIncrements, address modifierAddress);

    /**
     * @dev Emitted when counter is decremented
     * @param newCount The new counter value after decrementing
     * @param totalDecrements The total number of decrement operations performed
     * @param modifierAddress The address that performed the decrement
     */
    event CounterDecremented(uint256 newCount, uint256 totalDecrements, address modifierAddress);

    /**
     * @dev Emitted when counter is set to a new value
     * @param oldCount The previous counter value
     * @param newCount The new counter value
     * @param modifierAddress The address that set the new value
     */
    event CounterSet(uint256 oldCount, uint256 newCount, address modifierAddress);
}
