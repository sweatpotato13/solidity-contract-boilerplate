// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title LibCalculator
 * @dev Storage library for Calculator facet
 * @notice Provides the storage structure and utility functions for the calculator system
 */
library LibCalculator {
    /**
     * @dev Storage structure for the calculator
     * @param result The current calculator result value
     * @param operationCount The total number of operations performed
     * @param lastOperator The address of the account that last performed an operation
     */
    struct CalculatorStorage {
        int256 result;
        uint256 operationCount;
        address lastOperator;
    }

    /**
     * @dev Storage position for the calculator storage structure
     * @notice Position in storage is determined by keccak256 of a unique string
     */
    bytes32 constant CALCULATOR_STORAGE_POSITION = keccak256("diamond.calculator.storage");

    /**
     * @dev Retrieves the calculator storage structure
     * @return cs The CalculatorStorage struct from a specified position in contract storage
     */
    function calculatorStorage() internal pure returns (CalculatorStorage storage cs) {
        bytes32 position = CALCULATOR_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
}
