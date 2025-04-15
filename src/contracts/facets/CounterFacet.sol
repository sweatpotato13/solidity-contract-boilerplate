// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibDiamond.sol";
import "../libraries/LibCounter.sol";

/**
 * @title CounterFacet
 * @dev Facet that implements counter functionality
 * @notice Provides functions to increment, decrement, and set a counter value
 */
contract CounterFacet {
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
     * @dev Increment the counter by 1
     */
    function increment() external {
        getCounterStorage().count += 1;
    }

    /**
     * @dev Decrement the counter by 1
     * @notice The counter cannot go below zero
     */
    function decrement() external {
        LibCounter.CounterStorage storage cs = getCounterStorage();
        require(cs.count > 0, "Count cannot be negative");
        cs.count -= 1;
    }

    /**
     * @dev Set the counter to a specific value
     * @param _count The new counter value
     * @notice Only the contract owner can call this function
     */
    function setCount(uint256 _count) external {
        LibDiamond.enforceIsContractOwner(); // Only owner can set count
        getCounterStorage().count = _count;
    }
}
