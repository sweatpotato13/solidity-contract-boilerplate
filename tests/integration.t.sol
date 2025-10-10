// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";

// Diamond 관련 컨트랙트들 임포트
import {Diamond} from "../contracts/Diamond.sol";
import {DiamondCutFacet} from "../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../contracts/facets/OwnershipFacet.sol";
import {CounterFacet} from "../contracts/facets/CounterFacet.sol";
import {ERC20Facet} from "../contracts/facets/ERC20Facet.sol";
import {DiamondInit} from "../contracts/upgradeInitializers/DiamondInit.sol";
import {IDiamondCut} from "../contracts/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../contracts/interfaces/IDiamondLoupe.sol";

contract DiamondTest is Test {
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
    address otherAccount;

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
        otherAccount = address(0x123);

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

    // 배포 테스트
    function testDeployment() public {
        // 다이아몬드 주소 확인
        assertTrue(address(diamond) != address(0));

        // 각 facet 주소 확인
        assertTrue(address(diamondCutFacet) != address(0));
        assertTrue(address(diamondLoupeFacet) != address(0));
        assertTrue(address(ownershipFacet) != address(0));
        assertTrue(address(counterFacet) != address(0));
        assertTrue(address(erc20Facet) != address(0));
    }

    function testFacetsRegistration() public {
        // 등록된 facet 수 확인 (DiamondCutFacet + 4개 facet)
        IDiamondLoupe.Facet[] memory facets = diamondLoupeFacet.facets();
        assertEq(facets.length, 5);
    }

    // OwnershipFacet 테스트
    function testOwnership() public {
        // 오너 확인
        assertEq(ownershipFacet.owner(), owner);
    }

    function testTransferOwnership() public {
        // 오너십 이전
        ownershipFacet.transferOwnership(otherAccount);
        assertEq(ownershipFacet.owner(), otherAccount);
    }

    // CounterFacet 테스트
    function testCounterInitialValue() public {
        // 초기값 0 확인
        assertEq(counterFacet.getCount(), 0);
    }

    function testCounterIncrement() public {
        // 증가 테스트
        counterFacet.increment();
        assertEq(counterFacet.getCount(), 1);

        counterFacet.increment();
        assertEq(counterFacet.getCount(), 2);
    }

    function testCounterDecrement() public {
        // 감소 테스트 (언더플로우 방지를 위해 먼저 증가)
        counterFacet.increment();
        counterFacet.increment();
        assertEq(counterFacet.getCount(), 2);

        counterFacet.decrement();
        assertEq(counterFacet.getCount(), 1);
    }

    function testCounterSetValue() public {
        // 특정 값으로 설정
        counterFacet.setCount(100);
        assertEq(counterFacet.getCount(), 100);
    }

    // ERC20Facet 테스트
    function testTokenDetails() public {
        // 토큰 정보 확인
        assertEq(erc20Facet.name(), "Diamond Token");
        assertEq(erc20Facet.symbol(), "DMD");
        assertEq(erc20Facet.decimals(), 18);
    }

    function testMintTokens() public {
        // 토큰 민팅
        uint256 mintAmount = 1000 * 10 ** 18;
        erc20Facet.mint(owner, mintAmount);

        assertEq(erc20Facet.balanceOf(owner), mintAmount);
        assertEq(erc20Facet.totalSupply(), mintAmount);
    }

    function testTokenTransfer() public {
        // 토큰 전송 테스트
        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 transferAmount = 100 * 10 ** 18;

        erc20Facet.mint(owner, mintAmount);
        erc20Facet.transfer(otherAccount, transferAmount);

        assertEq(erc20Facet.balanceOf(owner), mintAmount - transferAmount);
        assertEq(erc20Facet.balanceOf(otherAccount), transferAmount);
    }

    function testTokenApproval() public {
        // 토큰 승인 및 transferFrom 테스트
        uint256 mintAmount = 1000 * 10 ** 18;
        uint256 approvalAmount = 500 * 10 ** 18;
        uint256 transferAmount = 200 * 10 ** 18;

        erc20Facet.mint(owner, mintAmount);
        erc20Facet.approve(otherAccount, approvalAmount);

        assertEq(erc20Facet.allowance(owner, otherAccount), approvalAmount);

        // 다른 계정이 transferFrom을 호출하는 상황 모사
        vm.prank(otherAccount);
        erc20Facet.transferFrom(owner, otherAccount, transferAmount);

        assertEq(erc20Facet.balanceOf(owner), mintAmount - transferAmount);
        assertEq(erc20Facet.balanceOf(otherAccount), transferAmount);
        assertEq(erc20Facet.allowance(owner, otherAccount), approvalAmount - transferAmount);
    }

    function testUpdateTokenDetails() public {
        // 토큰 정보 업데이트
        erc20Facet.setTokenDetails("Updated Token", "UTK", 8);

        assertEq(erc20Facet.name(), "Updated Token");
        assertEq(erc20Facet.symbol(), "UTK");
        assertEq(erc20Facet.decimals(), 8);
    }

    // Diamond 업그레이드 테스트
    function testAddNewFunctions() public {
        // 새 CounterFacet 배포
        CounterFacet newCounterFacet = new CounterFacet();

        // 함수 셀렉터 준비
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";

        // 교체 실행
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(newCounterFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: getSelectors(counterFunctions)
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // 새 기능 테스트
        counterFacet.setCount(42);
        assertEq(counterFacet.getCount(), 42);
    }

    function testRemoveFunctions() public {
        // 함수 셀렉터 준비
        string[] memory counterFunctions = new string[](4);
        counterFunctions[0] = "getCount()";
        counterFunctions[1] = "increment()";
        counterFunctions[2] = "decrement()";
        counterFunctions[3] = "setCount(uint256)";

        // 함수 제거
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(0), // 제거는 주소가 0
            action: IDiamondCut.FacetCutAction.Remove,
            functionSelectors: getSelectors(counterFunctions)
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // 함수 호출이 실패하는지 확인
        vm.expectRevert();
        counterFacet.getCount();
    }
}
