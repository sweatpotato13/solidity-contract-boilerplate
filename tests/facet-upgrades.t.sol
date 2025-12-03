// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

// Import Diamond-related contracts
import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {CounterFacet} from "../src/facets/CounterFacet.sol";
import {CounterFacetV2} from "../src/facets/CounterFacetV2.sol";
import {CounterFacetV3} from "../src/facets/CounterFacetV3.sol";
import {ERC20Facet} from "../src/facets/ERC20Facet.sol";
import {CalculatorFacet} from "../src/facets/CalculatorFacet.sol";
import {DiamondInit} from "../src/upgradeInitializers/DiamondInit.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";

contract FacetUpgradesTest is Test {
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
    address user2;

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
        user2 = address(0x456);

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

    // Test upgrade from CounterFacet to CounterFacetV2
    function testUpgradeToCounterV2() public {
        // Set initial counter value
        counterFacet.increment();
        counterFacet.increment();
        uint256 initialCount = counterFacet.getCount();
        assertEq(initialCount, 2);

        // Deploy CounterFacetV2
        CounterFacetV2 counterFacetV2 = new CounterFacetV2();

        // Get existing selectors
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";
        bytes4[] memory selectorsToRemove = getSelectors(counterFunctions);

        // Get V2 selectors
        string[] memory counterV2Functions = new string[](6);
        counterV2Functions[0] = "getCount()";
        counterV2Functions[1] = "increment()";
        counterV2Functions[2] = "decrement()";
        counterV2Functions[3] = "setCount(uint256)";
        counterV2Functions[4] = "doubleIncrement()";
        counterV2Functions[5] = "isMultipleOf(uint256)";
        bytes4[] memory selectorsToAdd = getSelectors(counterV2Functions);

        // 기존 셀렉터 제거
        IDiamondCut.FacetCut[] memory removeCut = new IDiamondCut.FacetCut[](1);
        removeCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), action: IDiamondCut.FacetCutAction.Remove, functionSelectors: selectorsToRemove
        });

        IDiamondCut(address(diamond)).diamondCut(removeCut, address(0), "");

        // Add new selectors
        IDiamondCut.FacetCut[] memory addCut = new IDiamondCut.FacetCut[](1);
        addCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(counterFacetV2),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectorsToAdd
        });

        IDiamondCut(address(diamond)).diamondCut(addCut, address(0), "");

        // Call diamond with V2 interface
        CounterFacetV2 counterV2OnDiamond = CounterFacetV2(address(diamond));

        // Verify counter value is preserved
        uint256 countV2 = counterV2OnDiamond.getCount();
        assertEq(countV2, initialCount);

        // Test V2 functions
        bool isMultipleOf2 = counterV2OnDiamond.isMultipleOf(2);
        assertEq(isMultipleOf2, true);

        bool isMultipleOf3 = counterV2OnDiamond.isMultipleOf(3);
        assertEq(isMultipleOf3, false);

        // Test doubleIncrement
        counterV2OnDiamond.doubleIncrement();
        uint256 doubledCount = counterV2OnDiamond.getCount();
        assertEq(doubledCount, initialCount + 2);
    }

    // Test upgrade from CounterFacet -> CounterFacetV2 -> CounterFacetV3 (storage layout changes)
    function testUpgradeToCounterV3WithStorageChanges() public {
        // Set initial counter value
        counterFacet.increment();
        counterFacet.increment();
        counterFacet.increment();
        uint256 initialCount = counterFacet.getCount();
        assertEq(initialCount, 3);

        // Deploy CounterFacetV2
        CounterFacetV2 counterFacetV2 = new CounterFacetV2();

        // Upgrade V1 -> V2
        // Remove existing selectors
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";

        IDiamondCut.FacetCut[] memory removeV1 = new IDiamondCut.FacetCut[](1);
        removeV1[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: getSelectors(counterFunctions)
        });

        IDiamondCut(address(diamond)).diamondCut(removeV1, address(0), "");

        // Add V2 selectors
        string[] memory counterV2Functions = new string[](6);
        counterV2Functions[0] = "getCount()";
        counterV2Functions[1] = "increment()";
        counterV2Functions[2] = "decrement()";
        counterV2Functions[3] = "setCount(uint256)";
        counterV2Functions[4] = "doubleIncrement()";
        counterV2Functions[5] = "isMultipleOf(uint256)";

        IDiamondCut.FacetCut[] memory addV2 = new IDiamondCut.FacetCut[](1);
        addV2[0] = IDiamondCut.FacetCut({
            facetAddress: address(counterFacetV2),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors(counterV2Functions)
        });

        IDiamondCut(address(diamond)).diamondCut(addV2, address(0), "");

        // Verify V2 counter value
        CounterFacetV2 counterV2 = CounterFacetV2(address(diamond));
        uint256 v2Count = counterV2.getCount();
        assertEq(v2Count, initialCount);

        // Deploy CounterFacetV3 (completely different storage layout)
        CounterFacetV3 counterFacetV3 = new CounterFacetV3();

        // Upgrade V2 -> V3
        // Remove V2 selectors
        IDiamondCut.FacetCut[] memory removeV2 = new IDiamondCut.FacetCut[](1);
        removeV2[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: getSelectors(counterV2Functions)
        });

        IDiamondCut(address(diamond)).diamondCut(removeV2, address(0), "");

        // Add V3 selectors
        string[] memory counterV3Functions = new string[](5);
        counterV3Functions[0] = "getCount()";
        counterV3Functions[1] = "increment()";
        counterV3Functions[2] = "decrement()";
        counterV3Functions[3] = "setCount(uint256)";
        counterV3Functions[4] = "initializeV3()";

        IDiamondCut.FacetCut[] memory addV3 = new IDiamondCut.FacetCut[](1);
        addV3[0] = IDiamondCut.FacetCut({
            facetAddress: address(counterFacetV3),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors(counterV3Functions)
        });

        IDiamondCut(address(diamond)).diamondCut(addV3, address(0), "");

        // Call V3 initialization function (migrate V1/V2 storage -> V3 storage)
        CounterFacetV3 counterV3 = CounterFacetV3(address(diamond));
        counterV3.initializeV3();

        // Test V3 functionality
        counterV3.increment();

        // V3 increment adds 3 to count
        uint256 incrementedCount = counterV3.getCount();
        assertEq(incrementedCount, v2Count + 3);
    }

    // Test adding CalculatorFacet
    function testAddCalculatorFacet() public {
        // Deploy CalculatorFacet
        CalculatorFacet calculatorFacet = new CalculatorFacet();

        // Update to actual function signatures - clarify argument types
        string[] memory calculatorFunctions = new string[](8);
        calculatorFunctions[0] = "getResult()";
        calculatorFunctions[1] = "setValue(int256)";
        calculatorFunctions[2] = "add(int256)";
        calculatorFunctions[3] = "subtract(int256)";
        calculatorFunctions[4] = "multiply(int256)";
        calculatorFunctions[5] = "divide(int256)";
        calculatorFunctions[6] = "getOperationCount()";
        calculatorFunctions[7] = "getLastOperator()";

        // Add CalculatorFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(calculatorFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors(calculatorFunctions)
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Call diamond with calculator interface
        CalculatorFacet calculator = CalculatorFacet(address(diamond));

        // Verify initial value
        int256 initialValue = calculator.getResult();
        assertEq(initialValue, 0);

        // Set value to 10
        calculator.setValue(10);

        // Test basic operations
        calculator.add(5);
        int256 result = calculator.getResult();
        assertEq(result, 15);

        calculator.subtract(3);
        result = calculator.getResult();
        assertEq(result, 12);

        calculator.multiply(2);
        result = calculator.getResult();
        assertEq(result, 24);

        calculator.divide(4);
        result = calculator.getResult();
        assertEq(result, 6);

        // Verify operation count
        uint256 opCount = calculator.getOperationCount();
        assertEq(opCount, 4);

        // Verify last operator
        address lastOperator = calculator.getLastOperator();
        assertEq(lastOperator, owner);
    }

    // Test multiple facet additions and removals
    function testMultipleFacetAdditionsAndRemovals() public {
        // Update function signatures
        string[] memory calculatorFunctions = new string[](8);
        calculatorFunctions[0] = "getResult()";
        calculatorFunctions[1] = "setValue(int256)";
        calculatorFunctions[2] = "add(int256)";
        calculatorFunctions[3] = "subtract(int256)";
        calculatorFunctions[4] = "multiply(int256)";
        calculatorFunctions[5] = "divide(int256)";
        calculatorFunctions[6] = "getOperationCount()";
        calculatorFunctions[7] = "getLastOperator()";

        // Verify original facet count
        address[] memory originalFacets = diamondLoupeFacet.facetAddresses();
        uint256 originalFacetCount = originalFacets.length;

        // Deploy CalculatorFacet
        CalculatorFacet calculatorFacet = new CalculatorFacet();

        bytes4[] memory calculatorSelectors = getSelectors(calculatorFunctions);

        // Add CalculatorFacet
        IDiamondCut.FacetCut[] memory addCut = new IDiamondCut.FacetCut[](1);
        addCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(calculatorFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: calculatorSelectors
        });

        IDiamondCut(address(diamond)).diamondCut(addCut, address(0), "");

        // Verify addition
        address[] memory withCalculatorFacets = diamondLoupeFacet.facetAddresses();
        assertEq(withCalculatorFacets.length, originalFacetCount + 1);

        // Remove CalculatorFacet
        IDiamondCut.FacetCut[] memory removeCut = new IDiamondCut.FacetCut[](1);
        removeCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), action: IDiamondCut.FacetCutAction.Remove, functionSelectors: calculatorSelectors
        });

        IDiamondCut(address(diamond)).diamondCut(removeCut, address(0), "");

        // Verify removal
        address[] memory afterRemovalFacets = diamondLoupeFacet.facetAddresses();
        assertEq(afterRemovalFacets.length, originalFacetCount);

        // Verify selectors are removed
        for (uint256 i = 0; i < calculatorSelectors.length; i++) {
            address facetAddress = diamondLoupeFacet.facetAddress(calculatorSelectors[i]);
            assertEq(facetAddress, address(0));
        }
    }

    // Test replacing a single function
    function testReplaceSingleFunction() public {
        // Set initial counter value
        counterFacet.increment();
        counterFacet.increment();
        uint256 initialCount = counterFacet.getCount();
        assertEq(initialCount, 2);

        // Deploy CounterFacetV2
        CounterFacetV2 counterV2 = new CounterFacetV2();

        // Replace only increment function
        bytes4 incrementSelector = counterV2.increment.selector;

        // Replace increment function - properly convert to bytes4[]
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = incrementSelector;

        IDiamondCut.FacetCut[] memory replaceCut = new IDiamondCut.FacetCut[](1);
        replaceCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(counterV2), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(replaceCut, address(0), "");

        // Call replaced increment function (V2 version increments by 2)
        counterFacet.increment();

        // Verify result - should increase by 2
        uint256 newCount = counterFacet.getCount();
        assertEq(newCount, initialCount + 2);
    }

    // Test Diamond Cut performing multiple operations simultaneously
    function testMultipleOperationDiamondCut() public {
        // Deploy CalculatorFacet
        CalculatorFacet calculatorFacet = new CalculatorFacet();

        // Deploy CounterFacetV2
        CounterFacetV2 counterV2 = new CounterFacetV2();

        // Existing Counter selectors
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";
        bytes4[] memory counterSelectors = getSelectors(counterFunctions);

        // CounterV2 selectors
        string[] memory counterV2Functions = new string[](6);
        counterV2Functions[0] = "getCount()";
        counterV2Functions[1] = "increment()";
        counterV2Functions[2] = "decrement()";
        counterV2Functions[3] = "setCount(uint256)";
        counterV2Functions[4] = "doubleIncrement()";
        counterV2Functions[5] = "isMultipleOf(uint256)";
        bytes4[] memory counterV2Selectors = getSelectors(counterV2Functions);

        // Calculator selectors - update function signatures
        string[] memory calculatorFunctions = new string[](8);
        calculatorFunctions[0] = "getResult()";
        calculatorFunctions[1] = "setValue(int256)";
        calculatorFunctions[2] = "add(int256)";
        calculatorFunctions[3] = "subtract(int256)";
        calculatorFunctions[4] = "multiply(int256)";
        calculatorFunctions[5] = "divide(int256)";
        calculatorFunctions[6] = "getOperationCount()";
        calculatorFunctions[7] = "getLastOperator()";
        bytes4[] memory calculatorSelectors = getSelectors(calculatorFunctions);

        // Prepare diamond cut with multiple operations
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);

        // Remove existing Counter
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), action: IDiamondCut.FacetCutAction.Remove, functionSelectors: counterSelectors
        });

        // Add CounterV2
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(counterV2),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: counterV2Selectors
        });

        // Add Calculator
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(calculatorFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: calculatorSelectors
        });

        // Execute diamond cut
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        // Verify all operations succeeded
        // 1. Verify CounterV2 works
        CounterFacetV2 counterV2OnDiamond = CounterFacetV2(address(diamond));
        counterV2OnDiamond.increment();
        uint256 count = counterV2OnDiamond.getCount();
        assertEq(count, 2); // V2's increment increases by 2

        // 2. Verify Calculator works - change type to int256
        CalculatorFacet calculatorOnDiamond = CalculatorFacet(address(diamond));
        calculatorOnDiamond.add(10);
        int256 result = calculatorOnDiamond.getResult();
        assertEq(result, 10);

        // 3. Verify previous Counter functions are replaced with CounterV2 address
        bytes4 incrementSelector = counterV2.increment.selector;
        address facetAddressForIncrement = diamondLoupeFacet.facetAddress(incrementSelector);
        assertEq(facetAddressForIncrement, address(counterV2));
    }
}
