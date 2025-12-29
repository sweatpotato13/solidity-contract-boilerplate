// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Counter} from "../src/Counter.sol";
import {CounterInstance} from "../src/CounterInstance.sol";
import {CounterLens} from "../src/CounterLens.sol";
import {ICounterLens} from "../src/interfaces/ICounterLens.sol";

/**
 * @title CounterLensTest
 * @notice Test suite for CounterLens contract
 */
contract CounterLensTest is Test {
    CounterInstance public implementation;
    TransparentUpgradeableProxy public proxy;
    Counter public counter;
    CounterLens public lens;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    function setUp() public {
        // Deploy implementation
        implementation = new CounterInstance();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(Counter.initialize.selector, owner);

        // Deploy proxy
        vm.prank(owner);
        proxy = new TransparentUpgradeableProxy(address(implementation), owner, initData);

        // Create interface
        counter = Counter(address(proxy));

        // Deploy lens
        lens = new CounterLens();
    }

    function test_GetCount_NewUser() public view {
        uint256 count = lens.getCount(address(counter), user1);
        assertEq(count, 0, "New user count should be 0");
    }

    function test_GetCount_AfterIncrement() public {
        vm.prank(user1);
        counter.increment();

        uint256 count = lens.getCount(address(counter), user1);
        assertEq(count, 1, "Count should be 1 after increment");
    }

    function test_GetCount_MultipleIncrements() public {
        vm.startPrank(user1);
        for (uint256 i = 0; i < 5; i++) {
            counter.increment();
        }
        vm.stopPrank();

        uint256 count = lens.getCount(address(counter), user1);
        assertEq(count, 5, "Count should be 5 after 5 increments");
    }

    function test_GetUserStats_NewUser() public view {
        ICounterLens.UserStats memory stats = lens.getUserStats(address(counter), user1);
        assertEq(stats.currentCount, 0, "Current count should be 0");
        assertEq(stats.totalIncrements, 0, "Total increments should be 0");
    }

    function test_GetUserStats_AfterIncrements() public {
        vm.startPrank(user1);
        counter.increment();
        counter.increment();
        counter.increment();
        vm.stopPrank();

        ICounterLens.UserStats memory stats = lens.getUserStats(address(counter), user1);
        assertEq(stats.currentCount, 3, "Current count should be 3");
        assertEq(stats.totalIncrements, 3, "Total increments should be 3");
    }

    function test_GetGlobalStats_Initial() public view {
        ICounterLens.GlobalStats memory stats = lens.getGlobalStats(address(counter));
        assertEq(stats.totalIncrements, 0, "Total increments should be 0");
        assertEq(stats.uniqueUsers, 0, "Unique users should be 0");
    }

    function test_GetGlobalStats_SingleUser() public {
        vm.startPrank(user1);
        counter.increment();
        counter.increment();
        vm.stopPrank();

        ICounterLens.GlobalStats memory stats = lens.getGlobalStats(address(counter));
        assertEq(stats.totalIncrements, 2, "Total increments should be 2");
        assertEq(stats.uniqueUsers, 1, "Unique users should be 1");
    }

    function test_GetGlobalStats_MultipleUsers() public {
        vm.prank(user1);
        counter.increment();

        vm.prank(user2);
        counter.increment();

        vm.prank(user3);
        counter.increment();

        ICounterLens.GlobalStats memory stats = lens.getGlobalStats(address(counter));
        assertEq(stats.totalIncrements, 3, "Total increments should be 3");
        assertEq(stats.uniqueUsers, 3, "Unique users should be 3");
    }

    function test_GetCountBatch_EmptyArray() public view {
        address[] memory users = new address[](0);
        uint256[] memory counts = lens.getCountBatch(address(counter), users);
        assertEq(counts.length, 0, "Counts array should be empty");
    }

    function test_GetCountBatch_SingleUser() public {
        vm.prank(user1);
        counter.increment();

        address[] memory users = new address[](1);
        users[0] = user1;

        uint256[] memory counts = lens.getCountBatch(address(counter), users);
        assertEq(counts.length, 1, "Counts array should have 1 element");
        assertEq(counts[0], 1, "User1 count should be 1");
    }

    function test_GetCountBatch_MultipleUsers() public {
        // Setup: user1 increments 3 times, user2 increments 2 times, user3 increments 5 times
        vm.startPrank(user1);
        for (uint256 i = 0; i < 3; i++) {
            counter.increment();
        }
        vm.stopPrank();

        vm.startPrank(user2);
        for (uint256 i = 0; i < 2; i++) {
            counter.increment();
        }
        vm.stopPrank();

        vm.startPrank(user3);
        for (uint256 i = 0; i < 5; i++) {
            counter.increment();
        }
        vm.stopPrank();

        // Query all users
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;

        uint256[] memory counts = lens.getCountBatch(address(counter), users);
        assertEq(counts.length, 3, "Counts array should have 3 elements");
        assertEq(counts[0], 3, "User1 count should be 3");
        assertEq(counts[1], 2, "User2 count should be 2");
        assertEq(counts[2], 5, "User3 count should be 5");
    }

    function test_GetCountBatch_MixedUsersWithZero() public {
        vm.prank(user1);
        counter.increment();

        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2; // Never incremented
        users[2] = user3; // Never incremented

        uint256[] memory counts = lens.getCountBatch(address(counter), users);
        assertEq(counts[0], 1, "User1 count should be 1");
        assertEq(counts[1], 0, "User2 count should be 0");
        assertEq(counts[2], 0, "User3 count should be 0");
    }

    function testFuzz_GetCount(address user, uint8 incrementCount) public {
        vm.assume(user != address(0));
        vm.assume(user != address(proxy));
        vm.assume(incrementCount > 0 && incrementCount <= 100);

        vm.startPrank(user);
        for (uint256 i = 0; i < incrementCount; i++) {
            counter.increment();
        }
        vm.stopPrank();

        uint256 count = lens.getCount(address(counter), user);
        assertEq(count, incrementCount, "Count should match increment count");
    }

    function testFuzz_GetUserStats(address user, uint8 incrementCount) public {
        vm.assume(user != address(0));
        vm.assume(user != address(proxy));
        vm.assume(incrementCount > 0 && incrementCount <= 100);

        vm.startPrank(user);
        for (uint256 i = 0; i < incrementCount; i++) {
            counter.increment();
        }
        vm.stopPrank();

        ICounterLens.UserStats memory stats = lens.getUserStats(address(counter), user);
        assertEq(stats.currentCount, incrementCount, "Current count should match");
        assertEq(stats.totalIncrements, incrementCount, "Total increments should match");
    }

    function test_Integration_ComplexScenario() public {
        // User1: 10 increments
        vm.startPrank(user1);
        for (uint256 i = 0; i < 10; i++) {
            counter.increment();
        }
        vm.stopPrank();

        // User2: 5 increments
        vm.startPrank(user2);
        for (uint256 i = 0; i < 5; i++) {
            counter.increment();
        }
        vm.stopPrank();

        // User3: 3 increments
        vm.startPrank(user3);
        for (uint256 i = 0; i < 3; i++) {
            counter.increment();
        }
        vm.stopPrank();

        // Verify individual counts
        assertEq(lens.getCount(address(counter), user1), 10);
        assertEq(lens.getCount(address(counter), user2), 5);
        assertEq(lens.getCount(address(counter), user3), 3);

        // Verify user stats
        ICounterLens.UserStats memory stats1 = lens.getUserStats(address(counter), user1);
        assertEq(stats1.currentCount, 10);
        assertEq(stats1.totalIncrements, 10);

        // Verify global stats
        ICounterLens.GlobalStats memory globalStats = lens.getGlobalStats(address(counter));
        assertEq(globalStats.totalIncrements, 18);
        assertEq(globalStats.uniqueUsers, 3);

        // Verify batch query
        address[] memory users = new address[](3);
        users[0] = user1;
        users[1] = user2;
        users[2] = user3;
        uint256[] memory counts = lens.getCountBatch(address(counter), users);
        assertEq(counts[0], 10);
        assertEq(counts[1], 5);
        assertEq(counts[2], 3);
    }
}
