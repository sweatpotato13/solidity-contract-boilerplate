// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../libraries/LibCounterV2.sol";

/**
 * @title CounterFacetV3
 * @dev Version of CounterFacet that uses extended storage structure
 */
contract CounterFacetV3 {
    // Access to counter storage
    function getCounterStorage() internal pure returns (LibCounterV2.CounterStorage storage) {
        return LibCounterV2.counterStorage();
    }

    // Function for initial migration
    function initializeV3() external {
        LibDiamond.enforceIsContractOwner(); // Only owner can initialize
        LibCounterV2.migrateStorage();
    }

    // Get the current counter value
    function getCount() external view returns (uint256) {
        return getCounterStorage().count;
    }

    // Increment the counter with extended functionality
    function increment() external {
        LibCounterV2.CounterStorage storage cs = getCounterStorage();
        cs.count += 3;
        cs.lastIncremented = block.timestamp;
        cs.totalIncrements += 1; // Single operation
        cs.lastModifier = msg.sender;

        emit CounterIncremented(cs.count, cs.totalIncrements, msg.sender);
    }

    // Decrement the counter with extended functionality
    function decrement() external {
        LibCounterV2.CounterStorage storage cs = getCounterStorage();
        require(cs.count > 0, "Count cannot be negative");
        cs.count -= 3;
        cs.lastDecremented = block.timestamp;
        cs.totalDecrements += 1; // Single operation
        cs.lastModifier = msg.sender;

        emit CounterDecremented(cs.count, cs.totalDecrements, msg.sender);
    }

    // Set the counter to a specific value
    function setCount(uint256 _count) external {
        LibDiamond.enforceIsContractOwner(); // Only owner can set count
        uint256 oldCount = getCounterStorage().count;
        getCounterStorage().count = _count;
        getCounterStorage().lastModifier = msg.sender;

        emit CounterSet(oldCount, _count, msg.sender);
    }

    // Added in V3: Function to increment counter by 2
    function doubleIncrement() external {
        LibCounterV2.CounterStorage storage cs = getCounterStorage();
        cs.count += 6;
        cs.lastIncremented = block.timestamp;
        cs.totalIncrements += 1; // Considered as a single operation
        cs.lastModifier = msg.sender;

        emit CounterIncremented(cs.count, cs.totalIncrements, msg.sender);
    }

    // Function to check if counter is a multiple of a given number
    function isMultipleOf(uint256 _number) external view returns (bool) {
        require(_number != 0, "Cannot divide by zero");
        return getCounterStorage().count % _number == 0;
    }

    // Added in V3: Function to get extended counter information
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
        return (
            cs.count,
            cs.lastIncremented,
            cs.lastDecremented,
            cs.totalIncrements,
            cs.totalDecrements,
            cs.lastModifier
        );
    }

    // Added in V3: Get last increment time
    function getLastIncrementTime() external view returns (uint256) {
        return getCounterStorage().lastIncremented;
    }

    // Added in V3: Get last decrement time
    function getLastDecrementTime() external view returns (uint256) {
        return getCounterStorage().lastDecremented;
    }

    // Added in V3: Get total number of increments
    function getTotalIncrements() external view returns (uint256) {
        return getCounterStorage().totalIncrements;
    }

    // Added in V3: Get total number of decrements
    function getTotalDecrements() external view returns (uint256) {
        return getCounterStorage().totalDecrements;
    }

    // Added in V3: Get last modifier address
    function getLastModifier() external view returns (address) {
        return getCounterStorage().lastModifier;
    }

    // Events added in V3
    event CounterIncremented(uint256 newCount, uint256 totalIncrements, address modifierAddress);
    event CounterDecremented(uint256 newCount, uint256 totalDecrements, address modifierAddress);
    event CounterSet(uint256 oldCount, uint256 newCount, address modifierAddress);
}
