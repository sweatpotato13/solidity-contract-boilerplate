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

contract GasTest is Test {
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
    address user1;

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
        user1 = address(0x123);

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

    // Measure gas cost of counter operations
    function testCounterOperationsGas() public {
        // getCount - read operation
        uint256 startGas = gasleft();
        counterFacet.getCount();
        uint256 gasUsed = startGas - gasleft();

        // increment - write operation
        startGas = gasleft();
        counterFacet.increment();
        gasUsed = startGas - gasleft();

        // setCount - write operation with parameter
        startGas = gasleft();
        counterFacet.setCount(42);
        gasUsed = startGas - gasleft();

        // 상태 변경 확인
        assertEq(counterFacet.getCount(), 42);
    }

    // Measure gas cost of ERC20 operations
    function testERC20OperationsGas() public {
        // name - read operation
        uint256 startGas = gasleft();
        erc20Facet.name();
        uint256 gasUsed = startGas - gasleft();

        // mint tokens - write operation
        uint256 mintAmount = 1000 * 10 ** 18;
        startGas = gasleft();
        erc20Facet.mint(owner, mintAmount);
        gasUsed = startGas - gasleft();

        // transfer tokens - write operation
        uint256 transferAmount = 100 * 10 ** 18;
        startGas = gasleft();
        erc20Facet.transfer(user1, transferAmount);
        gasUsed = startGas - gasleft();

        // approve tokens - write operation
        startGas = gasleft();
        erc20Facet.approve(user1, transferAmount);
        gasUsed = startGas - gasleft();

        // 상태 변경 확인
        assertEq(erc20Facet.balanceOf(user1), transferAmount);
        assertEq(erc20Facet.allowance(owner, user1), transferAmount);
    }

    // Measure gas cost of Diamond upgrade operations
    function testDiamondUpgradeGas() public {
        // Deploy new CounterFacet for replacement
        CounterFacet newCounterFacet = new CounterFacet();

        // Prepare selectors
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";
        bytes4[] memory selectors = getSelectors(counterFunctions);

        // Measure gas for facet replacement
        uint256 startGas = gasleft();

        // Use memory array instead of array literal
        IDiamondCut.FacetCut[] memory replaceCuts = new IDiamondCut.FacetCut[](1);
        replaceCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(newCounterFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(replaceCuts, address(0), "");
        uint256 gasUsed = startGas - gasleft();

        // Measure gas for facet removal
        startGas = gasleft();

        // Use memory array instead of array literal
        IDiamondCut.FacetCut[] memory removeCuts = new IDiamondCut.FacetCut[](1);
        removeCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), action: IDiamondCut.FacetCutAction.Remove, functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(removeCuts, address(0), "");
        gasUsed = startGas - gasleft();

        // Measure gas for complex multi-operation (including add, replace, remove)
        CounterFacet anotherCounterFacet = new CounterFacet();

        startGas = gasleft();

        // Use memory array instead of array literal
        IDiamondCut.FacetCut[] memory addCuts = new IDiamondCut.FacetCut[](1);
        addCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(anotherCounterFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(addCuts, address(0), "");
        gasUsed = startGas - gasleft();

        // Verify upgrade
        counterFacet.setCount(100);
        assertEq(counterFacet.getCount(), 100);
    }
}
