// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {Counter} from "../src/Counter.sol";
import {CounterInstance} from "../src/CounterInstance.sol";

/**
 * @title CounterTest
 * @notice Test suite for Counter contract
 */
contract CounterTest is Test {
    CounterInstance public implementation;
    TransparentUpgradeableProxy public proxy;
    Counter public counter;
    ProxyAdmin public proxyAdmin;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);
    address public user3 = address(0x4);

    event CounterIncremented(address indexed user, uint256 newValue, uint256 timestamp);

    function setUp() public {
        // Deploy implementation
        implementation = new CounterInstance();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(Counter.initialize.selector, owner);

        // Deploy proxy
        vm.prank(owner);
        proxy = new TransparentUpgradeableProxy(address(implementation), owner, initData);

        // Get ProxyAdmin address
        proxyAdmin = ProxyAdmin(
            address(uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)))))
        );

        // Create interface
        counter = Counter(address(proxy));
    }

    function test_Initialization() public view {
        assertEq(counter.owner(), owner, "Owner should be set correctly");
        assertEq(counter.totalIncrements(), 0, "Total increments should be 0");
        assertEq(counter.uniqueUsers(), 0, "Unique users should be 0");
    }

    function test_Increment_SingleUser() public {
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit CounterIncremented(user1, 1, block.timestamp);
        counter.increment();

        assertEq(counter.counters(user1), 1, "User1 counter should be 1");
        assertEq(counter.totalIncrements(), 1, "Total increments should be 1");
        assertEq(counter.userIncrementCount(user1), 1, "User1 increment count should be 1");
        assertEq(counter.uniqueUsers(), 1, "Unique users should be 1");
    }

    function test_Increment_MultipleTimesOneUser() public {
        vm.startPrank(user1);

        // First increment
        counter.increment();
        assertEq(counter.counters(user1), 1);
        assertEq(counter.uniqueUsers(), 1, "Unique users should be 1 after first increment");

        // Second increment
        counter.increment();
        assertEq(counter.counters(user1), 2);
        assertEq(counter.uniqueUsers(), 1, "Unique users should still be 1");

        // Third increment
        counter.increment();
        assertEq(counter.counters(user1), 3);
        assertEq(counter.totalIncrements(), 3);
        assertEq(counter.userIncrementCount(user1), 3);
        assertEq(counter.uniqueUsers(), 1, "Unique users should still be 1");

        vm.stopPrank();
    }

    function test_Increment_MultipleUsers() public {
        // User1 increments
        vm.prank(user1);
        counter.increment();

        // User2 increments
        vm.prank(user2);
        counter.increment();

        // User3 increments
        vm.prank(user3);
        counter.increment();

        assertEq(counter.counters(user1), 1, "User1 counter should be 1");
        assertEq(counter.counters(user2), 1, "User2 counter should be 1");
        assertEq(counter.counters(user3), 1, "User3 counter should be 1");
        assertEq(counter.totalIncrements(), 3, "Total increments should be 3");
        assertEq(counter.uniqueUsers(), 3, "Unique users should be 3");
    }

    function test_Increment_IndependentCounters() public {
        // User1 increments 5 times
        vm.startPrank(user1);
        for (uint256 i = 0; i < 5; i++) {
            counter.increment();
        }
        vm.stopPrank();

        // User2 increments 3 times
        vm.startPrank(user2);
        for (uint256 i = 0; i < 3; i++) {
            counter.increment();
        }
        vm.stopPrank();

        assertEq(counter.counters(user1), 5, "User1 counter should be 5");
        assertEq(counter.counters(user2), 3, "User2 counter should be 3");
        assertEq(counter.userIncrementCount(user1), 5, "User1 increment count should be 5");
        assertEq(counter.userIncrementCount(user2), 3, "User2 increment count should be 3");
        assertEq(counter.totalIncrements(), 8, "Total increments should be 8");
        assertEq(counter.uniqueUsers(), 2, "Unique users should be 2");
    }

    function test_Increment_EmitsEvent() public {
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit CounterIncremented(user1, 1, block.timestamp);
        counter.increment();

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit CounterIncremented(user1, 2, block.timestamp);
        counter.increment();
    }

    function testFuzz_Increment(address user) public {
        vm.assume(user != address(0));
        vm.assume(user != address(proxy));
        vm.assume(user != address(proxyAdmin));

        uint256 incrementsBefore = counter.totalIncrements();
        uint256 uniqueUsersBefore = counter.uniqueUsers();

        vm.prank(user);
        counter.increment();

        assertEq(counter.counters(user), 1, "User counter should be 1");
        assertEq(counter.totalIncrements(), incrementsBefore + 1, "Total increments should increase by 1");
        assertEq(counter.uniqueUsers(), uniqueUsersBefore + 1, "Unique users should increase by 1");
    }

    function testFuzz_MultipleIncrements(address user, uint8 count) public {
        vm.assume(user != address(0));
        vm.assume(user != address(proxy));
        vm.assume(user != address(proxyAdmin));
        vm.assume(count > 0 && count <= 100); // Reasonable range

        vm.startPrank(user);
        for (uint256 i = 0; i < count; i++) {
            counter.increment();
        }
        vm.stopPrank();

        assertEq(counter.counters(user), count, "User counter should match count");
        assertEq(counter.userIncrementCount(user), count, "User increment count should match count");
        assertEq(counter.totalIncrements(), count, "Total increments should match count");
        assertEq(counter.uniqueUsers(), 1, "Unique users should be 1");
    }

    function test_Ownership() public view {
        assertEq(counter.owner(), owner, "Owner should be set correctly");
    }

    function test_GetCounterValue_NewUser() public view {
        assertEq(counter.counters(user1), 0, "New user counter should be 0");
        assertEq(counter.userIncrementCount(user1), 0, "New user increment count should be 0");
    }

    // ============================================
    // SECURITY TESTS
    // ============================================

    /**
     * @notice Test that proxy cannot be reinitialized
     * @dev Verifies initializer modifier prevents double initialization
     */
    function test_Security_CannotReinitialize() public {
        // Attempt to reinitialize should revert
        vm.expectRevert();
        counter.initialize(user1);
    }

    /**
     * @notice Test that implementation contract cannot be initialized directly
     * @dev Verifies _disableInitializers() is called in constructor
     */
    function test_Security_ImplementationCannotBeInitialized() public {
        // Attempt to initialize implementation directly should revert
        vm.expectRevert();
        implementation.initialize(user1);
    }

    /**
     * @notice Test increment behavior at extreme counter values
     * @dev Verifies no overflow issues near uint256 max (though practically unreachable)
     */
    function test_Security_IncrementDoesNotOverflow() public {
        // Set counter to near max value using vm.store
        // Slot calculation: counters mapping is at slot 0 in CounterStorage
        bytes32 slot = keccak256(abi.encode(user1, uint256(0)));
        vm.store(address(proxy), slot, bytes32(type(uint256).max - 1));

        assertEq(counter.counters(user1), type(uint256).max - 1, "Counter should be max - 1");

        // Increment should work
        vm.prank(user1);
        counter.increment();

        assertEq(counter.counters(user1), type(uint256).max, "Counter should be max");

        // Next increment should revert due to overflow protection
        vm.prank(user1);
        vm.expectRevert();
        counter.increment();
    }

    /**
     * @notice Test that zero address can still increment (no special restrictions)
     * @dev This documents current behavior - may want to restrict in production
     */
    function test_Security_ZeroAddressCanIncrement() public {
        // Note: In production, you may want to add require(msg.sender != address(0))
        // but address(0) cannot actually send transactions, so this is mainly for documentation
        vm.prank(address(0));
        // This would revert in real blockchain but we test it for documentation
        counter.increment();
        assertEq(counter.counters(address(0)), 1, "Zero address counter should be 1");
    }

    /**
     * @notice Test ownership is correctly set and cannot be changed by non-owner
     * @dev Verifies access control on ownership functions
     */
    function test_Security_OnlyOwnerCanTransferOwnership() public {
        // Non-owner cannot transfer ownership
        vm.prank(user1);
        vm.expectRevert();
        counter.transferOwnership(user1);

        // Owner can transfer ownership
        vm.prank(owner);
        counter.transferOwnership(user1);
        assertEq(counter.owner(), user1, "Owner should be transferred to user1");
    }

    /**
     * @notice Test that counters are independent between users
     * @dev Ensures one user cannot affect another user's counter
     */
    function test_Security_CountersAreIndependent() public {
        // User1 increments
        vm.prank(user1);
        counter.increment();

        // User2's counter should remain 0
        assertEq(counter.counters(user2), 0, "User2 counter should be unaffected");

        // User2 increments
        vm.prank(user2);
        counter.increment();

        // Both counters should be independent
        assertEq(counter.counters(user1), 1, "User1 counter should be 1");
        assertEq(counter.counters(user2), 1, "User2 counter should be 1");
    }
}
