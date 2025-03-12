// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../libraries/LibCounter.sol";

/**
 * @title CounterFacetV2
 * @dev Upgraded version of CounterFacet with additional functionality
 */
contract CounterFacetV2 {
    // Access to counter storage
    function getCounterStorage() internal pure returns (LibCounter.CounterStorage storage) {
        return LibCounter.counterStorage();
    }

    // Get the current counter value
    function getCount() external view returns (uint256) {
        return getCounterStorage().count;
    }

    // Increment the counter
    function increment() external {
        getCounterStorage().count += 2;

        // Added in V2: Emit event when counter is incremented
        emit CounterIncremented(getCounterStorage().count);
    }

    // Decrement the counter
    function decrement() external {
        LibCounter.CounterStorage storage cs = getCounterStorage();
        require(cs.count > 0, "Count cannot be negative");
        cs.count -= 2;

        // Added in V2: Emit event when counter is decremented
        emit CounterDecremented(cs.count);
    }

    // Set the counter to a specific value
    function setCount(uint256 _count) external {
        LibDiamond.enforceIsContractOwner(); // Only owner can set count
        uint256 oldCount = getCounterStorage().count;
        getCounterStorage().count = _count;

        // Added in V2: Emit event when counter value is changed
        emit CounterSet(oldCount, _count);
    }

    // Added in V2: New function to increment counter by 2
    function doubleIncrement() external {
        getCounterStorage().count += 2;
        emit CounterIncremented(getCounterStorage().count);
    }

    // Added in V2: Function to check if counter is a multiple of a given number
    function isMultipleOf(uint256 _number) external view returns (bool) {
        require(_number != 0, "Cannot divide by zero");
        return getCounterStorage().count % _number == 0;
    }

    // Events added in V2
    event CounterIncremented(uint256 newCount);
    event CounterDecremented(uint256 newCount);
    event CounterSet(uint256 oldCount, uint256 newCount);
}
