// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

// Diamond 관련 컨트랙트들 임포트
import {Diamond} from "../../src/contracts/Diamond.sol";
import {DiamondCutFacet} from "../../src/contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../src/contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../../src/contracts/facets/OwnershipFacet.sol";
import {CounterFacet} from "../../src/contracts/facets/CounterFacet.sol";
import {ERC20Facet} from "../../src/contracts/facets/ERC20Facet.sol";
import {DiamondInit} from "../../src/contracts/upgradeInitializers/DiamondInit.sol";
import {IDiamondCut} from "../../src/contracts/interfaces/IDiamondCut.sol";

contract GasTest is Test {
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

    // 카운터 작업의 가스 비용 측정
    function testCounterOperationsGas() public {        
        // getCount - 읽기 작업
        uint256 startGas = gasleft();
        counterFacet.getCount();
        uint256 gasUsed = startGas - gasleft();
        
        // increment - 쓰기 작업
        startGas = gasleft();
        counterFacet.increment();
        gasUsed = startGas - gasleft();
        
        // setCount - 매개변수가 있는 쓰기 작업
        startGas = gasleft();
        counterFacet.setCount(42);
        gasUsed = startGas - gasleft();
        
        // 상태 변경 확인
        assertEq(counterFacet.getCount(), 42);
    }
    
    // ERC20 작업의 가스 비용 측정
    function testERC20OperationsGas() public {
        // name - 읽기 작업
        uint256 startGas = gasleft();
        erc20Facet.name();
        uint256 gasUsed = startGas - gasleft();

        // mint 토큰 - 쓰기 작업
        uint256 mintAmount = 1000 * 10**18;
        startGas = gasleft();
        erc20Facet.mint(owner, mintAmount);
        gasUsed = startGas - gasleft();
        
        
        // transfer 토큰 - 쓰기 작업
        uint256 transferAmount = 100 * 10**18;
        startGas = gasleft();
        erc20Facet.transfer(user1, transferAmount);
        gasUsed = startGas - gasleft();
        
        // approve 토큰 - 쓰기 작업
        startGas = gasleft();
        erc20Facet.approve(user1, transferAmount);
        gasUsed = startGas - gasleft();
        
        // 상태 변경 확인
        assertEq(erc20Facet.balanceOf(user1), transferAmount);
        assertEq(erc20Facet.allowance(owner, user1), transferAmount);
    }
    
    // Diamond 업그레이드 작업의 가스 비용 측정
    function testDiamondUpgradeGas() public {
        // 교체를 위한 새 CounterFacet 배포
        CounterFacet newCounterFacet = new CounterFacet();
        
        // 셀렉터 준비
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";
        bytes4[] memory selectors = getSelectors(counterFunctions);
        
        // facet 교체 가스 측정
        uint256 startGas = gasleft();
        
        // 배열 리터럴 대신 메모리 배열 사용
        IDiamondCut.FacetCut[] memory replaceCuts = new IDiamondCut.FacetCut[](1);
        replaceCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(newCounterFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: selectors
        });
        
        IDiamondCut(address(diamond)).diamondCut(
            replaceCuts,
            address(0),
            ""
        );
        uint256 gasUsed = startGas - gasleft();
        
        // facet 제거 가스 측정
        startGas = gasleft();
        
        // 배열 리터럴 대신 메모리 배열 사용
        IDiamondCut.FacetCut[] memory removeCuts = new IDiamondCut.FacetCut[](1);
        removeCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(0),
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: selectors
        });
        
        IDiamondCut(address(diamond)).diamondCut(
            removeCuts,
            address(0),
            ""
        );
        gasUsed = startGas - gasleft();
        
        // 복잡한 다중 작업 가스 측정 (추가, 교체, 제거 포함)
        CounterFacet anotherCounterFacet = new CounterFacet();
        
        startGas = gasleft();
        
        // 배열 리터럴 대신 메모리 배열 사용
        IDiamondCut.FacetCut[] memory addCuts = new IDiamondCut.FacetCut[](1);
        addCuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(anotherCounterFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
        
        IDiamondCut(address(diamond)).diamondCut(
            addCuts,
            address(0),
            ""
        );
        gasUsed = startGas - gasleft();
        
        // 업그레이드 확인
        counterFacet.setCount(100);
        assertEq(counterFacet.getCount(), 100);
    }
}