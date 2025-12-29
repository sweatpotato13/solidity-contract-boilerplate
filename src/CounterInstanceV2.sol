// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {CounterV2} from "./CounterV2.sol";

/**
 * @title CounterInstanceV2
 * @notice Concrete implementation of the abstract CounterV2 contract
 * @dev This is the V2 implementation for upgrade testing
 */
contract CounterInstanceV2 is CounterV2 {
    /**
     * @notice Constructor
     * @dev Disables initializers to prevent implementation contract from being initialized
     */
    constructor() {
        _disableInitializers();
    }
}
