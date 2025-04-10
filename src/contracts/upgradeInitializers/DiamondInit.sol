// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";
import "../libraries/LibCounter.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IDiamondCut.sol";
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IERC173.sol";
import "../interfaces/IERC165.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title DiamondInit
 * @dev Contract used to initialize state variables of a diamond during deployment or upgrade
 * @notice This contract is expected to be customized to initialize the diamond's state
 * @notice It is used with the diamond's diamondCut function during initialization
 */
contract DiamondInit is Initializable {
    /**
     * @dev Initializes the diamond storage with default values
     * @notice This function can only be called once, enforced by the initializer modifier
     * @notice Can only be called by the contract owner if the caller is not the diamond itself
     */
    function init() external initializer {
        // Initialize Diamond Storage
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        if (address(this) != msg.sender) {
            require(msg.sender == ds.contractOwner, "DiamondInit: not owner");
        }

        // Initialize Counter storage
        LibCounter.CounterStorage storage cs = LibCounter.counterStorage();
        cs.count = 0;

        // Initialize ERC20 storage
        LibERC20.ERC20Storage storage es = LibERC20.erc20Storage();
        es.tokenName = "Diamond Token";
        es.tokenSymbol = "DMD";
        es.tokenDecimals = 18;
        es.totalSupply = 0;

        // Add ERC165 support
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        // add your own state variables
        // EIP-2535 specifies that the `diamondCut` function takes two optional
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface
    }
}
