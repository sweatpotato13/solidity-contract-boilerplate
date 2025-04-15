// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibDiamond.sol";
import "../libraries/LibCounter.sol";

/**
 * @title CounterFacetV2
 * @dev Upgraded version of CounterFacet with additional functionality
 * @notice Provides enhanced counter functions with event emission
 */
contract CounterFacetV2 {
    /**
     * @dev Access to counter storage
     * @return The counter storage struct
     */
    function getCounterStorage() internal pure returns (LibCounter.CounterStorage storage) {
        return LibCounter.counterStorage();
    }

    /**
     * @dev Get the current counter value
     * @return The current counter value
     */
    function getCount() external view returns (uint256) {
        return getCounterStorage().count;
    }

    /**
     * @dev Increment the counter by 2 (enhanced from V1)
     * @notice Emits CounterIncremented event after incrementing
     */
    function increment() external {
        getCounterStorage().count += 2;

        // Added in V2: Emit event when counter is incremented
        emit CounterIncremented(getCounterStorage().count);
    }

    /**
     * @dev Decrement the counter by 2 (enhanced from V1)
     * @notice The counter cannot go below zero
     * @notice Emits CounterDecremented event after decrementing
     */
    function decrement() external {
        LibCounter.CounterStorage storage cs = getCounterStorage();
        require(cs.count > 0, "Count cannot be negative");
        cs.count -= 2;

        // Added in V2: Emit event when counter is decremented
        emit CounterDecremented(cs.count);
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

        // Added in V2: Emit event when counter value is changed
        emit CounterSet(oldCount, _count);
    }

    /**
     * @dev Increment counter by 2 (added in V2)
     * @notice Identical to increment() but kept for backward compatibility
     * @notice Emits CounterIncremented event after incrementing
     */
    function doubleIncrement() external {
        getCounterStorage().count += 2;
        emit CounterIncremented(getCounterStorage().count);
    }

    /**
     * @dev Check if counter is a multiple of a given number (added in V2)
     * @param _number The number to check division by
     * @return True if the counter is a multiple of the given number, false otherwise
     * @notice Reverts if _number is zero
     */
    function isMultipleOf(uint256 _number) external view returns (bool) {
        require(_number != 0, "Cannot divide by zero");
        return getCounterStorage().count % _number == 0;
    }

    /**
     * @dev Emitted when counter is incremented
     * @param newCount The new counter value after incrementing
     */
    event CounterIncremented(uint256 newCount);

    /**
     * @dev Emitted when counter is decremented
     * @param newCount The new counter value after decrementing
     */
    event CounterDecremented(uint256 newCount);

    /**
     * @dev Emitted when counter is set to a new value
     * @param oldCount The previous counter value
     * @param newCount The new counter value
     */
    event CounterSet(uint256 oldCount, uint256 newCount);
}
