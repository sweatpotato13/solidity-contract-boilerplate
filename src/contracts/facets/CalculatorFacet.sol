// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../libraries/LibCalculator.sol";

/**
 * @title CalculatorFacet
 * @dev A simple calculator facet with basic arithmetic operations
 */
contract CalculatorFacet {
    // Events
    event OperationPerformed(string operation, int256 value, int256 newResult);
    event ResultReset(address operator);

    // Access to calculator storage
    function getCalculatorStorage() internal pure returns (LibCalculator.CalculatorStorage storage) {
        return LibCalculator.calculatorStorage();
    }

    // Get the current result
    function getResult() external view returns (int256) {
        return getCalculatorStorage().result;
    }

    // Get the operation count
    function getOperationCount() external view returns (uint256) {
        return getCalculatorStorage().operationCount;
    }

    // Get the last operator address
    function getLastOperator() external view returns (address) {
        return getCalculatorStorage().lastOperator;
    }

    // Add value to current result
    function add(int256 value) external returns (int256) {
        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result += value;
        cs.operationCount++;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("add", value, cs.result);
        return cs.result;
    }

    // Subtract value from current result
    function subtract(int256 value) external returns (int256) {
        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result -= value;
        cs.operationCount++;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("subtract", value, cs.result);
        return cs.result;
    }

    // Multiply current result by value
    function multiply(int256 value) external returns (int256) {
        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result *= value;
        cs.operationCount++;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("multiply", value, cs.result);
        return cs.result;
    }

    // Divide current result by value
    function divide(int256 value) external returns (int256) {
        require(value != 0, "Division by zero");

        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result /= value;
        cs.operationCount++;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("divide", value, cs.result);
        return cs.result;
    }

    // Reset the result to zero
    function reset() external {
        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result = 0;
        cs.lastOperator = msg.sender;

        emit ResultReset(msg.sender);
    }

    // Set the result to a specific value (owner only)
    function setValue(int256 value) external {
        LibDiamond.enforceIsContractOwner(); // Only owner can set value

        LibCalculator.CalculatorStorage storage cs = getCalculatorStorage();
        cs.result = value;
        cs.lastOperator = msg.sender;

        emit OperationPerformed("set", value, value);
    }
}
