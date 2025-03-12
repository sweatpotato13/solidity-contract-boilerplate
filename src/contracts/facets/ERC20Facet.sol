// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../libraries/LibERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20Facet is IERC20 {
    // Access to ERC20 storage
    function getERC20Storage() internal pure returns (LibERC20.ERC20Storage storage) {
        return LibERC20.erc20Storage();
    }

    // Token name
    function name() external view returns (string memory) {
        return getERC20Storage().tokenName;
    }

    // Token symbol
    function symbol() external view returns (string memory) {
        return getERC20Storage().tokenSymbol;
    }

    // Token decimals
    function decimals() external view returns (uint8) {
        return getERC20Storage().tokenDecimals;
    }

    // Set token metadata (only owner)
    function setTokenDetails(string memory _name, string memory _symbol, uint8 _decimals) external {
        LibDiamond.enforceIsContractOwner();
        LibERC20.ERC20Storage storage es = getERC20Storage();
        es.tokenName = _name;
        es.tokenSymbol = _symbol;
        es.tokenDecimals = _decimals;
    }

    // Total supply of tokens
    function totalSupply() external view override returns (uint256) {
        return getERC20Storage().totalSupply;
    }

    // Get balance of account
    function balanceOf(address account) external view override returns (uint256) {
        return getERC20Storage().balances[account];
    }

    // Transfer tokens
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    // Get allowance
    function allowance(address owner, address spender) external view override returns (uint256) {
        return getERC20Storage().allowances[owner][spender];
    }

    // Approve spending
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // Transfer tokens from an approved address
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);

        LibERC20.ERC20Storage storage es = getERC20Storage();
        uint256 currentAllowance = es.allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _approve(sender, msg.sender, currentAllowance - amount);
        return true;
    }

    // Internal transfer function
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

    // Internal approval function
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        getERC20Storage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // Mint new tokens (only owner)
    function mint(address account, uint256 amount) external {
        LibDiamond.enforceIsContractOwner();
        require(account != address(0), "ERC20: mint to the zero address");

        LibERC20.ERC20Storage storage es = getERC20Storage();
        es.totalSupply += amount;
        es.balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    // Burn tokens (only owner)
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
