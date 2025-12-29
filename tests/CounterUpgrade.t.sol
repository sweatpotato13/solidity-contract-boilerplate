// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Counter} from "../src/Counter.sol";
import {CounterInstance} from "../src/CounterInstance.sol";
import {CounterV2} from "../src/CounterV2.sol";
import {CounterInstanceV2} from "../src/CounterInstanceV2.sol";

/**
 * @title CounterUpgradeTest
 * @notice Test suite for Counter upgrade functionality
 */
contract CounterUpgradeTest is Test {
    CounterInstance public implementationV1;
    CounterInstanceV2 public implementationV2;
    TransparentUpgradeableProxy public proxy;
    Counter public counterV1;
    CounterV2 public counterV2;
    ProxyAdmin public proxyAdmin;

    address public owner = address(0x1);
    address public user1 = address(0x2);
    address public user2 = address(0x3);

    event CounterIncremented(address indexed user, uint256 newValue, uint256 timestamp);
    event CounterDecremented(address indexed user, uint256 newValue, uint256 timestamp);

    function setUp() public {
        // Deploy V1 implementation
        implementationV1 = new CounterInstance();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(Counter.initialize.selector, owner);

        // Deploy proxy
        vm.prank(owner);
        proxy = new TransparentUpgradeableProxy(address(implementationV1), owner, initData);

        // Get ProxyAdmin address
        proxyAdmin = ProxyAdmin(
            address(uint160(uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)))))
        );

        // Create V1 interface
        counterV1 = Counter(address(proxy));
    }

    function test_StatePreservation_AfterUpgrade() public {
        // Setup: Create some state in V1
        vm.prank(user1);
        counterV1.increment();
        vm.prank(user1);
        counterV1.increment();
        vm.prank(user1);
        counterV1.increment();

        vm.prank(user2);
        counterV1.increment();

        // Verify V1 state
        assertEq(counterV1.counters(user1), 3, "User1 counter should be 3 before upgrade");
        assertEq(counterV1.counters(user2), 1, "User2 counter should be 1 before upgrade");
        assertEq(counterV1.totalIncrements(), 4, "Total increments should be 4 before upgrade");
        assertEq(counterV1.uniqueUsers(), 2, "Unique users should be 2 before upgrade");

        // Deploy V2 implementation
        implementationV2 = new CounterInstanceV2();

        // Upgrade to V2
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(implementationV2), "");

        // Create V2 interface
        counterV2 = CounterV2(address(proxy));

        // Verify state preservation
        assertEq(counterV2.counters(user1), 3, "User1 counter should be preserved after upgrade");
        assertEq(counterV2.counters(user2), 1, "User2 counter should be preserved after upgrade");
        assertEq(counterV2.totalIncrements(), 4, "Total increments should be preserved after upgrade");
        assertEq(counterV2.uniqueUsers(), 2, "Unique users should be preserved after upgrade");
        assertEq(counterV2.owner(), owner, "Owner should be preserved after upgrade");
    }

    function test_NewFunctionality_AfterUpgrade() public {
        // Setup: Create some state in V1
        vm.startPrank(user1);
        counterV1.increment();
        counterV1.increment();
        counterV1.increment();
        vm.stopPrank();

        assertEq(counterV1.counters(user1), 3, "User1 counter should be 3");

        // Upgrade to V2
        implementationV2 = new CounterInstanceV2();
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(implementationV2), "");

        // Create V2 interface
        counterV2 = CounterV2(address(proxy));

        // Test new decrementBy function
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit CounterDecremented(user1, 1, block.timestamp);
        counterV2.decrementBy(2);

        assertEq(counterV2.counters(user1), 1, "User1 counter should be 1 after decrement");
    }

    function test_VersionFunction_AfterUpgrade() public {
        // Upgrade to V2
        implementationV2 = new CounterInstanceV2();
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(implementationV2), "");

        // Create V2 interface
        counterV2 = CounterV2(address(proxy));

        // Test version function
        string memory version = counterV2.version();
        assertEq(version, "v2.0.0", "Version should be v2.0.0");
    }

    function test_DecrementBy_RequiresSufficientBalance() public {
        // Upgrade to V2
        implementationV2 = new CounterInstanceV2();
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(implementationV2), "");

        counterV2 = CounterV2(address(proxy));

        // User1 increments 3 times
        vm.startPrank(user1);
        counterV2.increment();
        counterV2.increment();
        counterV2.increment();
        vm.stopPrank();

        // Try to decrement more than available
        vm.prank(user1);
        vm.expectRevert("CounterV2: insufficient counter value");
        counterV2.decrementBy(5);
    }

    function test_OldFunctionality_StillWorks_AfterUpgrade() public {
        // Upgrade to V2
        implementationV2 = new CounterInstanceV2();
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(implementationV2), "");

        counterV2 = CounterV2(address(proxy));

        // Test that old increment function still works
        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit CounterIncremented(user1, 1, block.timestamp);
        counterV2.increment();

        assertEq(counterV2.counters(user1), 1, "Increment should still work in V2");
        assertEq(counterV2.totalIncrements(), 1, "Total increments should update in V2");
        assertEq(counterV2.uniqueUsers(), 1, "Unique users should update in V2");
    }

    function test_MultipleUpgrades() public {
        // Setup state in V1
        vm.prank(user1);
        counterV1.increment();

        // Upgrade to V2
        implementationV2 = new CounterInstanceV2();
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(implementationV2), "");

        counterV2 = CounterV2(address(proxy));

        // Use V2 functionality
        vm.prank(user1);
        counterV2.increment();
        vm.prank(user1);
        counterV2.decrementBy(1);

        assertEq(counterV2.counters(user1), 1, "Should be 1 after increment and decrement");

        // Upgrade back to V1 (downgrade)
        CounterInstance newV1Implementation = new CounterInstance();
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(newV1Implementation), "");

        Counter counterBackToV1 = Counter(address(proxy));
        assertEq(counterBackToV1.counters(user1), 1, "State should be preserved after downgrade");
    }

    function testFuzz_DecrementBy(uint8 incrementCount, uint8 decrementAmount) public {
        vm.assume(incrementCount > 0 && incrementCount <= 100);
        vm.assume(decrementAmount > 0 && decrementAmount <= incrementCount);

        // Upgrade to V2
        implementationV2 = new CounterInstanceV2();
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(implementationV2), "");

        counterV2 = CounterV2(address(proxy));

        // Increment
        vm.startPrank(user1);
        for (uint256 i = 0; i < incrementCount; i++) {
            counterV2.increment();
        }
        vm.stopPrank();

        // Decrement
        vm.prank(user1);
        counterV2.decrementBy(decrementAmount);

        assertEq(counterV2.counters(user1), incrementCount - decrementAmount, "Counter should match expected value");
    }

    function test_ProxyAdminOwnership() public view {
        assertEq(proxyAdmin.owner(), owner, "ProxyAdmin owner should be owner");
    }

    function test_OnlyAdminCanUpgrade() public {
        implementationV2 = new CounterInstanceV2();

        // Try to upgrade from non-owner account
        vm.prank(user1);
        vm.expectRevert();
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(implementationV2), "");

        // Owner can upgrade
        vm.prank(owner);
        proxyAdmin.upgradeAndCall(ITransparentUpgradeableProxy(address(proxy)), address(implementationV2), "");
    }
}
