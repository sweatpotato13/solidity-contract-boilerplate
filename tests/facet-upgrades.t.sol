// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

// Diamond 관련 컨트랙트들 임포트
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
    // 컨트랙트 변수들
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    CounterFacet counterFacet;
    ERC20Facet erc20Facet;
    DiamondInit diamondInit;

    // 주소들
    address owner;
    address user1;
    address user2;

    // Facet 셀렉터 관리 함수들
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

    // 테스트 셋업 (배포)
    function setUp() public {
        owner = address(this);
        user1 = address(0x123);
        user2 = address(0x456);

        // DiamondCutFacet 배포
        diamondCutFacet = new DiamondCutFacet();

        // Diamond 배포
        diamond = new Diamond(owner, address(diamondCutFacet));

        // DiamondInit 배포
        diamondInit = new DiamondInit();

        // 각 Facet 배포
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        counterFacet = new CounterFacet();
        erc20Facet = new ERC20Facet();

        // 각 facet의 함수 시그니처 준비
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

        // Facet 추가를 위한 다이아몬드 컷 준비
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

        // 초기화 함수 데이터 준비
        bytes memory functionCall = abi.encodeWithSignature("init()");

        // 다이아몬드 컷 실행
        IDiamondCut(address(diamond)).diamondCut(cut, address(diamondInit), functionCall);

        // 프록시를 통해 컨트랙트 인터페이스 생성
        diamondLoupeFacet = DiamondLoupeFacet(address(diamond));
        ownershipFacet = OwnershipFacet(address(diamond));
        counterFacet = CounterFacet(address(diamond));
        erc20Facet = ERC20Facet(address(diamond));
    }

    // CounterFacet -> CounterFacetV2 업그레이드 테스트
    function testUpgradeToCounterV2() public {
        // 초기 카운터 값 설정
        counterFacet.increment();
        counterFacet.increment();
        uint256 initialCount = counterFacet.getCount();
        assertEq(initialCount, 2);

        // CounterFacetV2 배포
        CounterFacetV2 counterFacetV2 = new CounterFacetV2();

        // 기존 셀렉터 가져오기
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";
        bytes4[] memory selectorsToRemove = getSelectors(counterFunctions);

        // V2 셀렉터 가져오기
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

        // 새 셀렉터 추가
        IDiamondCut.FacetCut[] memory addCut = new IDiamondCut.FacetCut[](1);
        addCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(counterFacetV2),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectorsToAdd
        });

        IDiamondCut(address(diamond)).diamondCut(addCut, address(0), "");

        // V2 인터페이스로 다이아몬드 호출
        CounterFacetV2 counterV2OnDiamond = CounterFacetV2(address(diamond));

        // 카운터 값이 보존되었는지 확인
        uint256 countV2 = counterV2OnDiamond.getCount();
        assertEq(countV2, initialCount);

        // V2 함수 테스트
        bool isMultipleOf2 = counterV2OnDiamond.isMultipleOf(2);
        assertEq(isMultipleOf2, true);

        bool isMultipleOf3 = counterV2OnDiamond.isMultipleOf(3);
        assertEq(isMultipleOf3, false);

        // doubleIncrement 테스트
        counterV2OnDiamond.doubleIncrement();
        uint256 doubledCount = counterV2OnDiamond.getCount();
        assertEq(doubledCount, initialCount + 2);
    }

    // CounterFacet -> CounterFacetV2 -> CounterFacetV3 (스토리지 레이아웃 변경) 테스트
    function testUpgradeToCounterV3WithStorageChanges() public {
        // 초기 카운터 값 설정
        counterFacet.increment();
        counterFacet.increment();
        counterFacet.increment();
        uint256 initialCount = counterFacet.getCount();
        assertEq(initialCount, 3);

        // CounterFacetV2 배포
        CounterFacetV2 counterFacetV2 = new CounterFacetV2();

        // V1 -> V2 업그레이드
        // 기존 셀렉터 제거
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

        // V2 셀렉터 추가
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

        // V2 카운터 값 확인
        CounterFacetV2 counterV2 = CounterFacetV2(address(diamond));
        uint256 v2Count = counterV2.getCount();
        assertEq(v2Count, initialCount);

        // CounterFacetV3 배포 (완전히 다른 스토리지 레이아웃)
        CounterFacetV3 counterFacetV3 = new CounterFacetV3();

        // V2 -> V3 업그레이드
        // V2 셀렉터 제거
        IDiamondCut.FacetCut[] memory removeV2 = new IDiamondCut.FacetCut[](1);
        removeV2[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: getSelectors(counterV2Functions)
        });

        IDiamondCut(address(diamond)).diamondCut(removeV2, address(0), "");

        // V3 셀렉터 추가
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

        // V3 초기화 함수 호출 (V1/V2 스토리지 -> V3 스토리지로 마이그레이션)
        CounterFacetV3 counterV3 = CounterFacetV3(address(diamond));
        counterV3.initializeV3();

        // V3 기능 테스트
        counterV3.increment();

        // V3 increment는 카운트에 3을 더함
        uint256 incrementedCount = counterV3.getCount();
        assertEq(incrementedCount, v2Count + 3);
    }

    // CalculatorFacet 추가 테스트
    function testAddCalculatorFacet() public {
        // CalculatorFacet 배포
        CalculatorFacet calculatorFacet = new CalculatorFacet();

        // 실제 함수 시그니처로 수정 - 인자 타입도 명확히
        string[] memory calculatorFunctions = new string[](8);
        calculatorFunctions[0] = "getResult()";
        calculatorFunctions[1] = "setValue(int256)"; // uint256 -> int256
        calculatorFunctions[2] = "add(int256)"; // uint256 -> int256
        calculatorFunctions[3] = "subtract(int256)"; // uint256 -> int256
        calculatorFunctions[4] = "multiply(int256)"; // uint256 -> int256
        calculatorFunctions[5] = "divide(int256)"; // uint256 -> int256
        calculatorFunctions[6] = "getOperationCount()";
        calculatorFunctions[7] = "getLastOperator()";

        // CalculatorFacet 추가
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(calculatorFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: getSelectors(calculatorFunctions)
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // 계산기 인터페이스로 다이아몬드 호출
        CalculatorFacet calculator = CalculatorFacet(address(diamond));

        // 초기값 확인
        int256 initialValue = calculator.getResult();
        assertEq(initialValue, 0);

        // 값을 10으로 설정
        calculator.setValue(10);

        // 기본 연산 테스트
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

        // 연산 횟수 확인
        uint256 opCount = calculator.getOperationCount();
        assertEq(opCount, 4);

        // 마지막 연산자 확인
        address lastOperator = calculator.getLastOperator();
        assertEq(lastOperator, owner);
    }

    // 여러 Facet 추가/제거 테스트
    function testMultipleFacetAdditionsAndRemovals() public {
        // 함수 시그니처 수정
        string[] memory calculatorFunctions = new string[](8);
        calculatorFunctions[0] = "getResult()";
        calculatorFunctions[1] = "setValue(int256)"; // 수정
        calculatorFunctions[2] = "add(int256)"; // 수정
        calculatorFunctions[3] = "subtract(int256)"; // 수정
        calculatorFunctions[4] = "multiply(int256)"; // 수정
        calculatorFunctions[5] = "divide(int256)"; // 수정
        calculatorFunctions[6] = "getOperationCount()";
        calculatorFunctions[7] = "getLastOperator()";

        // 원래 facet 수 확인
        address[] memory originalFacets = diamondLoupeFacet.facetAddresses();
        uint256 originalFacetCount = originalFacets.length;

        // CalculatorFacet 배포
        CalculatorFacet calculatorFacet = new CalculatorFacet();

        bytes4[] memory calculatorSelectors = getSelectors(calculatorFunctions);

        // CalculatorFacet 추가
        IDiamondCut.FacetCut[] memory addCut = new IDiamondCut.FacetCut[](1);
        addCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(calculatorFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: calculatorSelectors
        });

        IDiamondCut(address(diamond)).diamondCut(addCut, address(0), "");

        // 추가 확인
        address[] memory withCalculatorFacets = diamondLoupeFacet.facetAddresses();
        assertEq(withCalculatorFacets.length, originalFacetCount + 1);

        // CalculatorFacet 제거
        IDiamondCut.FacetCut[] memory removeCut = new IDiamondCut.FacetCut[](1);
        removeCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), action: IDiamondCut.FacetCutAction.Remove, functionSelectors: calculatorSelectors
        });

        IDiamondCut(address(diamond)).diamondCut(removeCut, address(0), "");

        // 제거 확인
        address[] memory afterRemovalFacets = diamondLoupeFacet.facetAddresses();
        assertEq(afterRemovalFacets.length, originalFacetCount);

        // 셀렉터가 제거되었는지 확인
        for (uint256 i = 0; i < calculatorSelectors.length; i++) {
            address facetAddress = diamondLoupeFacet.facetAddress(calculatorSelectors[i]);
            assertEq(facetAddress, address(0));
        }
    }

    // 단일 함수 교체 테스트
    function testReplaceSingleFunction() public {
        // 초기 카운터 값 설정
        counterFacet.increment();
        counterFacet.increment();
        uint256 initialCount = counterFacet.getCount();
        assertEq(initialCount, 2);

        // CounterFacetV2 배포
        CounterFacetV2 counterV2 = new CounterFacetV2();

        // increment 함수만 교체
        bytes4 incrementSelector = counterV2.increment.selector;

        // increment 함수 교체 - bytes4[]로 올바르게 변환
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = incrementSelector;

        IDiamondCut.FacetCut[] memory replaceCut = new IDiamondCut.FacetCut[](1);
        replaceCut[0] = IDiamondCut.FacetCut({
            facetAddress: address(counterV2), action: IDiamondCut.FacetCutAction.Replace, functionSelectors: selectors
        });

        IDiamondCut(address(diamond)).diamondCut(replaceCut, address(0), "");

        // 교체된 increment 함수 호출 (V2 버전은 2씩 증가)
        counterFacet.increment();

        // 결과 확인 - 2 증가해야 함
        uint256 newCount = counterFacet.getCount();
        assertEq(newCount, initialCount + 2);
    }

    // 여러 작업을 동시에 수행하는 Diamond Cut 테스트
    function testMultipleOperationDiamondCut() public {
        // CalculatorFacet 배포
        CalculatorFacet calculatorFacet = new CalculatorFacet();

        // CounterFacetV2 배포
        CounterFacetV2 counterV2 = new CounterFacetV2();

        // 기존 Counter 셀렉터
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";
        bytes4[] memory counterSelectors = getSelectors(counterFunctions);

        // CounterV2 셀렉터
        string[] memory counterV2Functions = new string[](6);
        counterV2Functions[0] = "getCount()";
        counterV2Functions[1] = "increment()";
        counterV2Functions[2] = "decrement()";
        counterV2Functions[3] = "setCount(uint256)";
        counterV2Functions[4] = "doubleIncrement()";
        counterV2Functions[5] = "isMultipleOf(uint256)";
        bytes4[] memory counterV2Selectors = getSelectors(counterV2Functions);

        // Calculator 셀렉터 - 함수 시그니처 수정
        string[] memory calculatorFunctions = new string[](8);
        calculatorFunctions[0] = "getResult()";
        calculatorFunctions[1] = "setValue(int256)"; // 수정
        calculatorFunctions[2] = "add(int256)"; // 수정
        calculatorFunctions[3] = "subtract(int256)"; // 수정
        calculatorFunctions[4] = "multiply(int256)"; // 수정
        calculatorFunctions[5] = "divide(int256)"; // 수정
        calculatorFunctions[6] = "getOperationCount()";
        calculatorFunctions[7] = "getLastOperator()";
        bytes4[] memory calculatorSelectors = getSelectors(calculatorFunctions);

        // 여러 작업이 포함된 다이아몬드 컷 준비
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);

        // 기존 Counter 제거
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), action: IDiamondCut.FacetCutAction.Remove, functionSelectors: counterSelectors
        });

        // CounterV2 추가
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(counterV2),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: counterV2Selectors
        });

        // Calculator 추가
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(calculatorFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: calculatorSelectors
        });

        // 다이아몬드 컷 실행
        IDiamondCut(address(diamond)).diamondCut(cuts, address(0), "");

        // 모든 작업이 성공했는지 확인
        // 1. CounterV2 작동 확인
        CounterFacetV2 counterV2OnDiamond = CounterFacetV2(address(diamond));
        counterV2OnDiamond.increment();
        uint256 count = counterV2OnDiamond.getCount();
        assertEq(count, 2); // V2의 increment는 2씩 증가

        // 2. Calculator 작동 확인 - int256으로 타입 변경
        CalculatorFacet calculatorOnDiamond = CalculatorFacet(address(diamond));
        calculatorOnDiamond.add(10);
        int256 result = calculatorOnDiamond.getResult();
        assertEq(result, 10);

        // 3. 이전 Counter 함수가 CounterV2 주소로 대체되었는지 확인
        bytes4 incrementSelector = counterV2.increment.selector;
        address facetAddressForIncrement = diamondLoupeFacet.facetAddress(incrementSelector);
        assertEq(facetAddressForIncrement, address(counterV2));
    }
}
