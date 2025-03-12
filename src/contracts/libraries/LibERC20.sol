// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LibERC20
 * @dev Storage library for ERC20 facet
 */
library LibERC20 {
    struct ERC20Storage {
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
        uint256 totalSupply;
        string tokenName;
        string tokenSymbol;
        uint8 tokenDecimals;
    }

    // Position in storage is determined by keccak256 of a unique string
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("diamond.erc20.storage");

    // Returns the struct from a specified position in contract storage
    function erc20Storage() internal pure returns (ERC20Storage storage es) {
        bytes32 position = ERC20_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}
