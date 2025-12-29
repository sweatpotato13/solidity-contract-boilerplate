// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {ICounter} from "./interfaces/ICounter.sol";
import {CounterStorage} from "./CounterStorage.sol";

/**
 * @title Counter
 * @notice Upgradeable counter contract using TransparentProxy pattern
 * @dev Use CounterLens for gas-efficient read operations
 */
abstract contract Counter is ICounter, Initializable, OwnableUpgradeable, CounterStorage {
    // ============================================
    // INITIALIZER
    // ============================================

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {}

    /**
     * @notice Initialize the contract
     * @param _owner Initial owner address
     */
    function initialize(address _owner) public initializer {
        __Ownable_init(_owner);
    }

    // ============================================
    // USER FUNCTIONS
    // ============================================

    /// @inheritdoc ICounter
    function increment() external override {
        // Track if this is user's first increment
        if (!_hasIncremented[msg.sender]) {
            _hasIncremented[msg.sender] = true;
            uniqueUsers++;
        }

        // Increment user's counter
        counters[msg.sender]++;

        // Update statistics
        totalIncrements++;
        userIncrementCount[msg.sender]++;

        emit CounterIncremented(msg.sender, counters[msg.sender], block.timestamp);
    }
}
