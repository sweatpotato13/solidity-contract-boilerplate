// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../libraries/LibCalculator.sol";

/**
 * @title CalculatorFacet
 * @dev A simple calculator facet with basic arithmetic operations
 * @notice Provides arithmetic functions to perform calculations on a stored result
 */
contract CalculatorFacet {
    /**
     * @dev Emitted when an arithmetic operation is performed
     * @param operation The type of operation performed (add, subtract, multiply, divide, set)
     * @param value The value used in the operation
     * @param newResult The result after the operation
     */
    event OperationPerformed(string operation, int256 value, int256 newResult);
    
    /**
     * @dev Emitted when the result is reset to zero
     * @param operator The address that performed the reset
     */
    event ResultReset(address operator);

    /**
     * @dev Access to calculator storage
     * @return The calculator storage struct
     */
    function getCalculatorStorage() internal pure returns (LibCalculator.CalculatorStorage storage) {
        return LibCalculator.calculatorStorage();
    }

    /**
     * @dev Get the current result of calculations
     * @return The current stored result
     */
    function getResult() external view returns (int256) {
        return getCalculatorStorage().result;
    }

    /**
     * @dev Get the total number of operations performed
     * @return The operation count
     */
    function getOperationCount() external view returns (uint256) {
        return getCalculatorStorage().operationCount;
    }

    /**
     * @dev Get the address of the last account that performed an operation
     * @return The address of the last operator
     */
    function getLastOperator() external view returns (address) {
        return getCalculatorStorage().lastOperator;
    }

    /**
     * @dev Add a value to the current result
     * @param value The value to add
     * @return The new result after addition
     */
    function add(int256 value) external returns (int256) {
        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result += value;
        cs.operationCount++;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("add", value, cs.result);
        return cs.result;
    }

    /**
     * @dev Subtract a value from the current result
     * @param value The value to subtract
     * @return The new result after subtraction
     */
    function subtract(int256 value) external returns (int256) {
        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result -= value;
        cs.operationCount++;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("subtract", value, cs.result);
        return cs.result;
    }

    /**
     * @dev Multiply the current result by a value
     * @param value The value to multiply by
     * @return The new result after multiplication
     */
    function multiply(int256 value) external returns (int256) {
        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result *= value;
        cs.operationCount++;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("multiply", value, cs.result);
        return cs.result;
    }

    /**
     * @dev Divide the current result by a value
     * @param value The value to divide by
     * @return The new result after division
     * @notice Reverts if attempting to divide by zero
     */
    function divide(int256 value) external returns (int256) {
        require(value != 0, "Division by zero");

        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result /= value;
        cs.operationCount++;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("divide", value, cs.result);
        return cs.result;
    }

    /**
     * @dev Reset the result to zero
     * @notice Emits a ResultReset event
     */
    function reset() external {
        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result = 0;
        cs.lastOperator = msg.sender;

        emit ResultReset(msg.sender);
    }

    /**
     * @dev Set the result to a specific value
     * @param value The value to set as the new result
     * @notice Only the contract owner can call this function
     */
    function setValue(int256 value) external {
        LibDiamond.enforceIsContractOwner(); // Only owner can set value

        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result = value;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("set", value, value);
    }
}
