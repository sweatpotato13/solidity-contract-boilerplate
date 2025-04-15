// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title LibERC20
 * @dev Storage library for ERC20 facet
 * @notice Provides the storage structure and utility functions for the ERC20 token system
 */
library LibERC20 {
    /**
     * @dev Storage structure for the ERC20 token
     * @param balances Mapping of addresses to token balances
     * @param allowances Nested mapping of owner addresses to spender allowances
     * @param totalSupply The total token supply
     * @param tokenName The name of the token
     * @param tokenSymbol The symbol of the token
     * @param tokenDecimals The number of decimals for token display
     */
    struct ERC20Storage {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimals;
    }

    /**
     * @dev Storage position for the ERC20 storage structure
     * @notice Position in storage is determined by keccak256 of a unique string
     */
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("diamond.erc20.storage");

    /**
     * @dev Retrieves the ERC20 storage structure
     * @return es The ERC20Storage struct from a specified position in contract storage
     */
    function erc20Storage() internal pure returns (ERC20Storage storage es) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
