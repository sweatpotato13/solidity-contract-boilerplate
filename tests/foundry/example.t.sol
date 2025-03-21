pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";

contract ContractBTest is Test {
    uint256 testNumber;

    function setUp() public {
        testNumber = 42;
    }

    function testNumberIs42() public {
        assertEq(testNumber, 42);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function testRevertSubtract43() public {
        vm.expectRevert();
        testNumber -= 43;
    }
}
