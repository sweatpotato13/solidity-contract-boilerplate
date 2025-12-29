// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Counter} from "./Counter.sol";

/**
 * @title CounterInstance
 * @notice Concrete implementation of the abstract Counter contract
 * @dev This contract provides a deployable instance of Counter.
 *      It is designed to be used behind a TransparentUpgradeableProxy for
 *      upgradeable deployments. The constructor disables initializers on the
 *      implementation to prevent attacks.
 */
contract CounterInstance is Counter {
    /**
     * @notice Constructor
     * @dev Disables initializers to prevent implementation contract from being initialized
     */
    constructor() {
        _disableInitializers();
    }
}
