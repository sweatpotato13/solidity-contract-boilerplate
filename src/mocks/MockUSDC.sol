// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @dev Mock USDC token for testing payment integration
 * @notice Implements standard ERC20 with 6 decimals like real USDC
 */
contract MockUSDC is ERC20 {
    uint8 private constant USDC_DECIMALS = 6;

    /**
     * @dev Constructor that mints initial supply to deployer
     */
    constructor() ERC20("Mock USDC", "USDC") {
        // Mint 1 billion USDC to deployer for testing
        _mint(msg.sender, 1_000_000_000 * 10 ** USDC_DECIMALS);
    }

    /**
     * @dev Returns 6 decimals to match real USDC
     */
    function decimals() public pure override returns (uint8) {
        return USDC_DECIMALS;
    }

    /**
     * @dev Mint tokens to specified address (testing helper)
     * @param to Address to mint tokens to
     * @param amount Amount of tokens to mint (in token units)
     */
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    /**
     * @dev Burn tokens from specified address (testing helper)
     * @param from Address to burn tokens from
     * @param amount Amount of tokens to burn (in token units)
     */
    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }

    /**
     * @dev Set balance of address directly (testing helper)
     * @param account Address to set balance for
     * @param newBalance New balance in token units
     */
    function setBalance(address account, uint256 newBalance) external {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            _mint(account, newBalance - currentBalance);
        } else if (newBalance < currentBalance) {
            _burn(account, currentBalance - newBalance);
        }
    }

    /**
     * @dev Force approval for testing scenarios
     * @param owner Address of token owner
     * @param spender Address of approved spender
     * @param amount Amount to approve
     */
    function forceApproval(address owner, address spender, uint256 amount) external {
        _approve(owner, spender, amount);
    }
}
