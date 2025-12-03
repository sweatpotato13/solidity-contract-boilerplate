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

contract DiamondTest is Test {
    // Contract variables
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    CounterFacet counterFacet;
    ERC20Facet erc20Facet;
    DiamondInit diamondInit;

    // Addresses
    address owner;
    address otherAccount;

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
        otherAccount = address(0x123);

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
        string[] memory diamondLoupeFunctions = new string[](4);
        diamondLoupeFunctions[0] = "facets()";
        diamondLoupeFunctions[1] = "facetFunctionSelectors(address)";
        diamondLoupeFunctions[2] = "facetAddresses()";
        diamondLoupeFunctions[3] = "facetAddress(bytes4)";

        string[] memory ownershipFunctions = new string[](2);
        ownershipFunctions[0] = "transferOwnership(address)";
        ownershipFunctions[1] = "owner()";

        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";

        string[] memory erc20Functions = new string[](13);
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
        erc20Functions[12] = "_approve(address,address,uint256)";

        // Prepare diamond cut for adding facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](4);

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors(diamondLoupeFunctions)
        });

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors(ownershipFunctions)
        });

        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(counterFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors(counterFunctions)
        });

        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(erc20Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors(erc20Functions)
        });

        // Prepare initialization function data
        bytes memory functionCall = abi.encodeWithSignature("init()");

        // Execute diamond cut
        IDiamondCut(address(diamond)).diamondCut(cut, address(diamondInit), functionCall);

        // Create contract interfaces through proxy
        diamondLoupeFacet = DiamondLoupeFacet(address(diamond));
        ownershipFacet = OwnershipFacet(address(diamond));
        counterFacet = CounterFacet(address(diamond));
        erc20Facet = ERC20Facet(address(diamond));
    }

    // Test deployment
    function testDeployment() public {
        // Verify diamond address
        assertTrue(address(diamond) != address(0));

        // Verify each facet address
        assertTrue(address(diamondCutFacet) != address(0));
        assertTrue(address(diamondLoupeFacet) != address(0));
        assertTrue(address(ownershipFacet) != address(0));
        assertTrue(address(counterFacet) != address(0));
        assertTrue(address(erc20Facet) != address(0));
    }

    function testFacetsRegistration() public {
        // Verify number of registered facets (DiamondCutFacet + 4 facets)
        IDiamondLoupe.Facet[] memory facets = diamondLoupeFacet.facets();
        assertEq(facets.length, 5);
    }

    // Test OwnershipFacet
    function testOwnership() public {
        // Verify owner
        assertEq(ownershipFacet.owner(), owner);
    }

    function testTransferOwnership() public {
        // Transfer ownership
        ownershipFacet.transferOwnership(otherAccount);
        assertEq(ownershipFacet.owner(), otherAccount);
    }

    // Test CounterFacet
    function testCounterInitialValue() public {
        // Verify initial value is 0
        assertEq(counterFacet.getCount(), 0);
    }

    function testCounterIncrement() public {
        // Test increment
        counterFacet.increment();
        assertEq(counterFacet.getCount(), 1);

        counterFacet.increment();
        assertEq(counterFacet.getCount(), 2);
    }

    function testCounterDecrement() public {
        // Test decrement (increment first to prevent underflow)
        counterFacet.increment();
        counterFacet.increment();
        assertEq(counterFacet.getCount(), 2);

        counterFacet.decrement();
        assertEq(counterFacet.getCount(), 1);
    }

    function testCounterSetValue() public {
        // Set to specific value
        counterFacet.setCount(100);
        assertEq(counterFacet.getCount(), 100);
    }

    // Test ERC20Facet
    function testTokenDetails() public {
        // Verify token details
        assertEq(erc20Facet.name(), "Diamond Token");
        assertEq(erc20Facet.symbol(), "DMD");
        assertEq(erc20Facet.decimals(), 18);
    }

    function testMintTokens() public {
        // Mint tokens
        uint256 mintAmount = 1000 * 10 ** 18;
        erc20Facet.mint(owner, mintAmount);

        assertEq(erc20Facet.balanceOf(owner), mintAmount);
        assertEq(erc20Facet.totalSupply(), mintAmount);
    }

    function testTokenTransfer() public {
        // Test token transfer
        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 transferAmount = 100 * 10 ** 18;

        erc20Facet.mint(owner, mintAmount);
        erc20Facet.transfer(otherAccount, transferAmount);

        assertEq(erc20Facet.balanceOf(owner), mintAmount - transferAmount);
        assertEq(erc20Facet.balanceOf(otherAccount), transferAmount);
    }

    function testTokenApproval() public {
        // Test token approval and transferFrom
        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 approvalAmount = 500 * 10 ** 18;
        uint256 transferAmount = 200 * 10 ** 18;

        erc20Facet.mint(owner, mintAmount);
        erc20Facet.approve(otherAccount, approvalAmount);

        assertEq(erc20Facet.allowance(owner, otherAccount), approvalAmount);

        // Simulate another account calling transferFrom
        vm.prank(otherAccount);
        erc20Facet.transferFrom(owner, otherAccount, transferAmount);

        assertEq(erc20Facet.balanceOf(owner), mintAmount - transferAmount);
        assertEq(erc20Facet.balanceOf(otherAccount), transferAmount);
        assertEq(erc20Facet.allowance(owner, otherAccount), approvalAmount - transferAmount);
    }

    function testUpdateTokenDetails() public {
        // Update token details
        erc20Facet.setTokenDetails("Updated Token", "UTK", 8);

        assertEq(erc20Facet.name(), "Updated Token");
        assertEq(erc20Facet.symbol(), "UTK");
        assertEq(erc20Facet.decimals(), 8);
    }

    // Test Diamond upgrade
    function testAddNewFunctions() public {
        // Deploy new CounterFacet
        CounterFacet newCounterFacet = new CounterFacet();

        // Prepare function selectors
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";

        // Execute replacement
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(newCounterFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: getSelectors(counterFunctions)
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Test new functionality
        counterFacet.setCount(42);
        assertEq(counterFacet.getCount(), 42);
    }

    function testRemoveFunctions() public {
        // Prepare function selectors
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";

        // Remove functions
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), // Address 0 for removal
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: getSelectors(counterFunctions)
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Verify function call fails
        vm.expectRevert();
        counterFacet.getCount();
    }
}
