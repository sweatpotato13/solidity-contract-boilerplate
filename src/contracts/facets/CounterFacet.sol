// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../libraries/LibCounter.sol";

contract CounterFacet {
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
        getCounterStorage().count += 1;
    }

    // Decrement the counter
    function decrement() external {
        LibCounter.CounterStorage storage cs = getCounterStorage();
        require(cs.count > 0, "Count cannot be negative");
        cs.count -= 1;
    }

    // Set the counter to a specific value
    function setCount(uint256 _count) external {
        LibDiamond.enforceIsContractOwner(); // Only owner can set count
        getCounterStorage().count = _count;
    }
}
