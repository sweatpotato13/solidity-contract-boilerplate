// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LibCalculator
 * @dev Storage library for Calculator facet
 */
library LibCalculator {
    struct CalculatorStorage {
        int256 result;
        uint256 operationCount;
        address lastOperator;
    }

    // Position in storage is determined by keccak256 of a unique string
    bytes32 constant CALCULATOR_STORAGE_POSITION = keccak256("diamond.calculator.storage");

    // Returns the struct from a specified position in contract storage
    function calculatorStorage() internal pure returns (CalculatorStorage storage cs) {
        bytes32 position = CALCULATOR_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
}
