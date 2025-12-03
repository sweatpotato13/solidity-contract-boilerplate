// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

// Import Diamond-related contracts
import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {CounterFacet} from "../src/facets/CounterFacet.sol";
import {ERC20Facet} from "../src/facets/ERC20Facet.sol";
import {DiamondInit} from "../src/upgradeInitializers/DiamondInit.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import {IERC165} from "../src/interfaces/IERC165.sol";

contract DiamondLoupeTest is Test {
    // Contract variables
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    CounterFacet counterFacet;
    ERC20Facet erc20Facet;
    DiamondInit diamondInit;

    // Interface IDs - corrected to exact values
    bytes4 constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 constant DIAMOND_LOUPE_INTERFACE_ID = 0x48e2b093;
    bytes4 constant DIAMOND_CUT_INTERFACE_ID = 0x1f931c1c;

    // Addresses
    address owner;
    address[] facetAddresses;

    // Selector-to-address mapping
    mapping(bytes4 => address) selectorToFacetMap;

    // Facet selector management functions
    function getSelector(string memory _func) internal pure returns (bytes4) {
        return bytes4(keccak256(bytes(_func)));
    }

    function getSelectors(string[] memory _functionSignatures) internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](_functionSignatures.length);
        for (uint256 i = 0; i < _functionSignatures.length; i++) {
            selectors[i] = getSelector(_functionSignatures[i]);
        }
        return selectors;
    }

    // Test setup (deployment)
    function setUp() public {
        owner = address(this);

        // Deploy DiamondCutFacet
        diamondCutFacet = new DiamondCutFacet();

        // Deploy Diamond
        diamond = new Diamond(owner, address(diamondCutFacet));

        // Deploy DiamondInit
        diamondInit = new DiamondInit();

        // Deploy each Facet
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        counterFacet = new CounterFacet();
        erc20Facet = new ERC20Facet();

        // Prepare function signatures for each facet
        string[] memory diamondLoupeFunctions = new string[](5);
        diamondLoupeFunctions[0] = "facets()";
        diamondLoupeFunctions[1] = "facetFunctionSelectors(address)";
        diamondLoupeFunctions[2] = "facetAddresses()";
        diamondLoupeFunctions[3] = "facetAddress(bytes4)";
        diamondLoupeFunctions[4] = "supportsInterface(bytes4)";

        string[] memory ownershipFunctions = new string[](2);
        ownershipFunctions[0] = "transferOwnership(address)";
        ownershipFunctions[1] = "owner()";

        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";

        string[] memory erc20Functions = new string[](12);
        erc20Functions[0] = "name()";
        erc20Functions[1] = "symbol()";
        erc20Functions[2] = "decimals()";
        erc20Functions[3] = "totalSupply()";
        erc20Functions[4] = "balanceOf(address)";
        erc20Functions[5] = "transfer(address,uint256)";
        erc20Functions[6] = "allowance(address,address)";
        erc20Functions[7] = "approve(address,uint256)";
        erc20Functions[8] = "transferFrom(address,address,uint256)";
        erc20Functions[9] = "setTokenDetails(string,string,uint8)";
        erc20Functions[10] = "mint(address,uint256)";
        erc20Functions[11] = "burn(address,uint256)";

        // Get selectors
        bytes4[] memory loupeSelectors = getSelectors(diamondLoupeFunctions);
        bytes4[] memory ownershipSelectors = getSelectors(ownershipFunctions);
        bytes4[] memory counterSelectors = getSelectors(counterFunctions);
        bytes4[] memory erc20Selectors = getSelectors(erc20Functions);

        // Create selector-to-address mapping
        for (uint256 i = 0; i < loupeSelectors.length; i++) {
            selectorToFacetMap[loupeSelectors[i]] = address(diamondLoupeFacet);
        }
        for (uint256 i = 0; i < ownershipSelectors.length; i++) {
            selectorToFacetMap[ownershipSelectors[i]] = address(ownershipFacet);
        }
        for (uint256 i = 0; i < counterSelectors.length; i++) {
            selectorToFacetMap[counterSelectors[i]] = address(counterFacet);
        }
        for (uint256 i = 0; i < erc20Selectors.length; i++) {
            selectorToFacetMap[erc20Selectors[i]] = address(erc20Facet);
        }

        // Store facet addresses
        facetAddresses.push(address(diamondLoupeFacet));
        facetAddresses.push(address(ownershipFacet));
        facetAddresses.push(address(counterFacet));
        facetAddresses.push(address(erc20Facet));

        // Prepare diamond cut for adding facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](4);

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(counterFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: counterSelectors
        });

        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(erc20Facet), action: IDiamondCut.FacetCutAction.Add, functionSelectors: erc20Selectors
        });

        // Prepare initialization function data
        bytes memory functionCall = abi.encodeWithSignature("init()");

        // Execute diamond cut
        IDiamondCut(address(diamond)).diamondCut(cut, address(diamondInit), functionCall);

        // Create contract interfaces through proxy
        diamondLoupeFacet = DiamondLoupeFacet(address(diamond));
    }

    // Test facets()
    function testFacets() public view {
        IDiamondLoupe.Facet[] memory facets = diamondLoupeFacet.facets();

        // DiamondCutFacet + 4 facets = 5 total
        assertEq(facets.length, 5);

        // Each facet should have a valid address and selectors
        for (uint256 i = 0; i < facets.length; i++) {
            assertTrue(facets[i].facetAddress != address(0));
            assertTrue(facets[i].functionSelectors.length > 0);
        }
    }

    // Test facetFunctionSelectors()
    function testFacetFunctionSelectors() public view {
        // Test for each facet address
        for (uint256 i = 0; i < facetAddresses.length; i++) {
            address facetAddress = facetAddresses[i];
            bytes4[] memory selectors = diamondLoupeFacet.facetFunctionSelectors(facetAddress);

            // Selectors should exist
            assertTrue(selectors.length > 0);
        }
    }

    // Test for non-existent facet address
    function testFacetFunctionSelectorsForNonExistentAddress() public view {
        address nonExistentAddress = address(0x1);
        bytes4[] memory selectors = diamondLoupeFacet.facetFunctionSelectors(nonExistentAddress);

        // Should return empty array
        assertEq(selectors.length, 0);
    }

    // Test facetAddresses()
    function testFacetAddresses() public view {
        address[] memory addresses = diamondLoupeFacet.facetAddresses();

        // DiamondCutFacet + 4 facets = 5 total
        assertEq(addresses.length, 5);

        // Verify each deployed facet address is included
        for (uint256 i = 0; i < facetAddresses.length; i++) {
            bool found = false;
            for (uint256 j = 0; j < addresses.length; j++) {
                if (addresses[j] == facetAddresses[i]) {
                    found = true;
                    break;
                }
            }
            assertTrue(found);
        }
    }

    // Test facetAddress()
    function testFacetAddress() public view {
        // Declare array variable and set each element
        string[] memory loupeFunctionSignatures = new string[](4);
        loupeFunctionSignatures[0] = "facets()";
        loupeFunctionSignatures[1] = "facetFunctionSelectors(address)";
        loupeFunctionSignatures[2] = "facetAddresses()";
        loupeFunctionSignatures[3] = "facetAddress(bytes4)";

        // Get selectors
        bytes4[] memory loupeSelectors = getSelectors(loupeFunctionSignatures);

        // Test logic
        for (uint256 i = 0; i < loupeSelectors.length; i++) {
            address expectedFacetAddress = selectorToFacetMap[loupeSelectors[i]];
            address actualFacetAddress = diamondLoupeFacet.facetAddress(loupeSelectors[i]);
            assertEq(actualFacetAddress, expectedFacetAddress);
        }
    }

    // Test for non-existent function selector
    function testFacetAddressForNonExistentSelector() public view {
        bytes4 nonExistentSelector = bytes4(keccak256("nonExistentFunction()"));
        address facetAddress = diamondLoupeFacet.facetAddress(nonExistentSelector);

        // Should return address(0)
        assertEq(facetAddress, address(0));
    }

    // Test supportsInterface()
    function testSupportsERC165Interface() public view {
        bool isSupported = IERC165(address(diamond)).supportsInterface(ERC165_INTERFACE_ID);
        assertTrue(isSupported);
    }

    function testSupportsDiamondLoupeInterface() public view {
        bool isSupported = IERC165(address(diamond)).supportsInterface(DIAMOND_LOUPE_INTERFACE_ID);
        assertTrue(isSupported);
    }

    function testSupportsDiamondCutInterface() public view {
        bool isSupported = IERC165(address(diamond)).supportsInterface(DIAMOND_CUT_INTERFACE_ID);
        assertTrue(isSupported);
    }
}
