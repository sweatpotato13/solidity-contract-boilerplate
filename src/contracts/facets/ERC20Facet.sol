// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ERC20Facet
 * @dev Implementation of the ERC20 token standard as a diamond facet
 * @notice This facet provides ERC20 token functionality within the diamond
 */
contract ERC20Facet is IERC20 {
    /**
     * @dev Access to ERC20 storage
     * @return The ERC20 storage struct
     */
    function getERC20Storage() internal pure returns (LibERC20.ERC20Storage storage) {
        return LibERC20.erc20Storage();
    }

    /**
     * @dev Returns the name of the token
     * @return The token name
     */
    function name() external view returns (string memory) {
        return getERC20Storage().tokenName;
    }

    /**
     * @dev Returns the symbol of the token
     * @return The token symbol
     */
    function symbol() external view returns (string memory) {
        return getERC20Storage().tokenSymbol;
    }

    /**
     * @dev Returns the number of decimals used for display purposes
     * @return The token decimals
     */
    function decimals() external view returns (uint8) {
        return getERC20Storage().tokenDecimals;
    }

    /**
     * @dev Sets the token metadata
     * @param _name The new token name
     * @param _symbol The new token symbol
     * @param _decimals The new token decimals
     * @notice Only the contract owner can call this function
     */
    function setTokenDetails(string memory _name, string memory _symbol, uint8 _decimals) external {
        LibDiamond.enforceIsContractOwner();
        LibERC20.ERC20Storage storage es = getERC20Storage();
        es.tokenName = _name;
        es.tokenSymbol = _symbol;
        es.tokenDecimals = _decimals;
    }

    /**
     * @dev Returns the total supply of tokens
     * @return The total supply
     */
    function totalSupply() external view override returns (uint256) {
        return getERC20Storage().totalSupply;
    }

    /**
     * @dev Returns the token balance of an account
     * @param account The address to query the balance of
     * @return The account balance
     */
    function balanceOf(address account) external view override returns (uint256) {
        return getERC20Storage().balances[account];
    }

    /**
     * @dev Transfers tokens to a specified address
     * @param recipient The address to transfer to
     * @param amount The amount to transfer
     * @return True if the transfer was successful
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev Returns the amount of tokens that an owner allowed to a spender
     * @param owner The address that owns the tokens
     * @param spender The address that will spend the tokens
     * @return The remaining allowance
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return getERC20Storage().allowances[owner][spender];
    }

    /**
     * @dev Approves a spender to spend tokens on behalf of the caller
     * @param spender The address which will spend the tokens
     * @param amount The amount of tokens to be spent
     * @return True if the approval was successful
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev Transfers tokens from one address to another, with approval
     * @param sender The address which you want to transfer tokens from
     * @param recipient The address which you want to transfer to
     * @param amount The amount of tokens to be transferred
     * @return True if the transfer was successful
     * @notice Requires sufficient allowance
     */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        LibERC20.ERC20Storage storage es = getERC20Storage();
        uint256 currentAllowance = es.allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    /**
     * @dev Internal function to handle token transfers
     * @param sender The address sending tokens
     * @param recipient The address receiving tokens
     * @param amount The amount of tokens to transfer
     * @notice Checks for zero addresses and sufficient balance
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        LibERC20.ERC20Storage storage es = getERC20Storage();
        uint256 senderBalance = es.balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        es.balances[sender] = senderBalance - amount;
        es.balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /**
     * @dev Internal function to handle token approvals
     * @param owner The address that owns the tokens
     * @param spender The address allowed to spend the tokens
     * @param amount The amount of tokens to be spent
     * @notice Checks for zero addresses
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        getERC20Storage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Creates new tokens and assigns them to an account
     * @param account The address to receive the minted tokens
     * @param amount The amount of tokens to mint
     * @notice Only the contract owner can call this function
     */
    function mint(address account, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        require(account != address(0), "ERC20: mint to the zero address");

        LibERC20.ERC20Storage storage es = getERC20Storage();
        es.totalSupply += amount;
        es.balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys tokens from an account, reducing the total supply
     * @param account The address from which to burn tokens
     * @param amount The amount of tokens to burn
     * @notice Only the contract owner can call this function
     * @notice Checks for sufficient balance
     */
    function burn(address account, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        require(account != address(0), "ERC20: burn from the zero address");

        LibERC20.ERC20Storage storage es = getERC20Storage();
        uint256 accountBalance = es.balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        es.balances[account] = accountBalance - amount;
        es.totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
}
