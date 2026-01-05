// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CounterInstance} from "./CounterInstance.sol";
import {ICounterLens} from "./interfaces/ICounterLens.sol";

/**
 * @title CounterLens
 * @notice Gas-efficient read-only queries for Counter
 * @dev This contract is NOT upgradeable - deploy new versions as needed
 * @dev Implements ICounterLens interface for standardized querying
 */
contract CounterLens is ICounterLens {
    // ============================================
    // SINGLE USER QUERIES
    // ============================================

    /// @inheritdoc ICounterLens
    function getCount(address counter, address user) external view returns (uint256) {
        return CounterInstance(counter).counters(user);
    }

    /// @inheritdoc ICounterLens
    function getUserStats(address counter, address user) external view returns (UserStats memory stats) {
        CounterInstance counterInstance = CounterInstance(counter);
        stats = UserStats({
            currentCount: counterInstance.counters(user), totalIncrements: counterInstance.userIncrementCount(user)
        });
    }

    // ============================================
    // GLOBAL QUERIES
    // ============================================

    /// @inheritdoc ICounterLens
    function getGlobalStats(address counter) external view returns (GlobalStats memory stats) {
        CounterInstance counterInstance = CounterInstance(counter);
        stats = GlobalStats({
            totalIncrements: counterInstance.totalIncrements(), uniqueUsers: counterInstance.uniqueUsers()
        });
    }

    /// @inheritdoc ICounterLens
    function getCountBatch(address counter, address[] calldata users) external view returns (uint256[] memory counts) {
        uint256 length = users.length;
        counts = new uint256[](length);
        CounterInstance counterInstance = CounterInstance(counter);

        for (uint256 i = 0; i < length;) {
            counts[i] = counterInstance.counters(users[i]);
            unchecked {
                ++i;
            }
        }
    }
}
