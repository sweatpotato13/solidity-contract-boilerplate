// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

// Diamond 관련 컨트랙트들 임포트
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
    // 컨트랙트 변수들
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    CounterFacet counterFacet;
    ERC20Facet erc20Facet;
    DiamondInit diamondInit;

    // 인터페이스 IDs - 정확한 값으로 수정
    bytes4 constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 constant DIAMOND_LOUPE_INTERFACE_ID = 0x48e2b093;
    bytes4 constant DIAMOND_CUT_INTERFACE_ID = 0x1f931c1c;

    // 주소들
    address owner;
    address[] facetAddresses;

    // 셀렉터-주소 매핑
    mapping(bytes4 => address) selectorToFacetMap;

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

        // 셀렉터 얻기
        bytes4[] memory loupeSelectors = getSelectors(diamondLoupeFunctions);
        bytes4[] memory ownershipSelectors = getSelectors(ownershipFunctions);
        bytes4[] memory counterSelectors = getSelectors(counterFunctions);
        bytes4[] memory erc20Selectors = getSelectors(erc20Functions);

        // 셀렉터-주소 매핑 생성
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

        // facet 주소 저장
        facetAddresses.push(address(diamondLoupeFacet));
        facetAddresses.push(address(ownershipFacet));
        facetAddresses.push(address(counterFacet));
        facetAddresses.push(address(erc20Facet));

        // Facet 추가를 위한 다이아몬드 컷 준비
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

        // 초기화 함수 데이터 준비
        bytes memory functionCall = abi.encodeWithSignature("init()");

        // 다이아몬드 컷 실행
        IDiamondCut(address(diamond)).diamondCut(cut, address(diamondInit), functionCall);

        // 프록시를 통해 컨트랙트 인터페이스 생성
        diamondLoupeFacet = DiamondLoupeFacet(address(diamond));
    }

    // facets() 테스트
    function testFacets() public view {
        IDiamondLoupe.Facet[] memory facets = diamondLoupeFacet.facets();

        // DiamondCutFacet + 4개 facet = 5개
        assertEq(facets.length, 5);

        // 각 facet은 유효한 주소와 셀렉터를 가져야 함
        for (uint256 i = 0; i < facets.length; i++) {
            assertTrue(facets[i].facetAddress != address(0));
            assertTrue(facets[i].functionSelectors.length > 0);
        }
    }

    // facetFunctionSelectors() 테스트
    function testFacetFunctionSelectors() public view {
        // 각 facet 주소에 대해 테스트
        for (uint256 i = 0; i < facetAddresses.length; i++) {
            address facetAddress = facetAddresses[i];
            bytes4[] memory selectors = diamondLoupeFacet.facetFunctionSelectors(facetAddress);

            // 셀렉터가 존재해야 함
            assertTrue(selectors.length > 0);
        }
    }

    // 존재하지 않는 facet 주소에 대한 테스트
    function testFacetFunctionSelectorsForNonExistentAddress() public view {
        address nonExistentAddress = address(0x1);
        bytes4[] memory selectors = diamondLoupeFacet.facetFunctionSelectors(nonExistentAddress);

        // 빈 배열을 반환해야 함
        assertEq(selectors.length, 0);
    }

    // facetAddresses() 테스트
    function testFacetAddresses() public view {
        address[] memory addresses = diamondLoupeFacet.facetAddresses();

        // DiamondCutFacet + 4개 facet = 5개
        assertEq(addresses.length, 5);

        // 배포된 각 facet 주소가 포함되어 있는지 확인
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

    // facetAddress() 테스트
    function testFacetAddress() public view {
        // 배열 변수 선언 후 각 요소 설정
        string[] memory loupeFunctionSignatures = new string[](4);
        loupeFunctionSignatures[0] = "facets()";
        loupeFunctionSignatures[1] = "facetFunctionSelectors(address)";
        loupeFunctionSignatures[2] = "facetAddresses()";
        loupeFunctionSignatures[3] = "facetAddress(bytes4)";

        // 셀렉터 얻기
        bytes4[] memory loupeSelectors = getSelectors(loupeFunctionSignatures);

        // 테스트 로직
        for (uint256 i = 0; i < loupeSelectors.length; i++) {
            address expectedFacetAddress = selectorToFacetMap[loupeSelectors[i]];
            address actualFacetAddress = diamondLoupeFacet.facetAddress(loupeSelectors[i]);
            assertEq(actualFacetAddress, expectedFacetAddress);
        }
    }

    // 존재하지 않는 함수 셀렉터에 대한 테스트
    function testFacetAddressForNonExistentSelector() public view {
        bytes4 nonExistentSelector = bytes4(keccak256("nonExistentFunction()"));
        address facetAddress = diamondLoupeFacet.facetAddress(nonExistentSelector);

        // 주소(0)을 반환해야 함
        assertEq(facetAddress, address(0));
    }

    // supportsInterface() 테스트
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
