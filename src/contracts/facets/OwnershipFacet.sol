// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {IERC173} from "../interfaces/IERC173.sol";

/**
 * @title OwnershipFacet
 * @dev Implementation of the IERC173 interface for contract ownership
 * @notice Provides functions to query and transfer contract ownership
 */
contract OwnershipFacet is IERC173 {
    /**
     * @dev Transfers ownership of the contract to a new address
     * @param _newOwner The address to transfer ownership to
     * @notice Only the current owner can call this function
     * @notice If _newOwner is address(0), ownership is effectively renounced
     */
    function transferOwnership(address _newOwner) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    /**
     * @dev Returns the address of the current owner
     * @return owner_ The address of the current owner
     */
    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}
