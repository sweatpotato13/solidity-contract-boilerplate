// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import "../libraries/LibDiamond.sol";
import "../libraries/LibCounter.sol";
import "../libraries/LibERC20.sol";
import "../interfaces/IDiamondCut.sol";
import "../interfaces/IDiamondLoupe.sol";
import "../interfaces/IERC173.sol";
import "../interfaces/IERC165.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

// It is expected that this contract is customized if you want to deploy your diamond
// with data from a deployment script. Use the init function to initialize state variables
// of your diamond. Add parameters to the init function if you need to.

contract DiamondInit is Initializable {
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
