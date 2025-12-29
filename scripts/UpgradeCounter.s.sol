// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from
    "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../src/Counter.sol";
import "../src/CounterInstance.sol";

/**
 * @title UpgradeCounterScript
 * @notice Script for upgrading Counter implementation
 * @dev Usage: forge script scripts/UpgradeCounter.s.sol:UpgradeCounterScript --rpc-url <RPC_URL> --broadcast
 */
contract UpgradeCounterScript is Script {
    function run() public {
        // Load deployment info
        uint256 chainId = block.chainid;
        string memory root = vm.projectRoot();
        string memory path = string.concat(root, "/deployments/", vm.toString(chainId), ".json");
        string memory json = vm.readFile(path);

        address proxyAdminAddress = vm.parseJsonAddress(json, ".proxyAdmin");
        address proxyAddress = vm.parseJsonAddress(json, ".proxy");
        address oldImplementation = vm.parseJsonAddress(json, ".implementation");

        console.log("=== Counter Upgrade ===");
        console.log("Chain ID:", chainId);
        console.log("ProxyAdmin:", proxyAdminAddress);
        console.log("Proxy:", proxyAddress);
        console.log("Old Implementation:", oldImplementation);

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));

        // 1. Deploy new implementation
        CounterInstance newImplementation = new CounterInstance();
        console.log("New CounterInstance Implementation deployed at:", address(newImplementation));

        // 2. Get ProxyAdmin
        ProxyAdmin proxyAdmin = ProxyAdmin(proxyAdminAddress);

        // 3. Upgrade the proxy (OpenZeppelin v5 uses upgradeAndCall)
        // Pass empty data "" if no initialization function needs to be called
        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(proxyAddress),
            address(newImplementation),
            "" // Empty data = upgrade only, no function call
        );
        console.log("Upgrade transaction executed");

        // 4. Verify state preservation
        Counter counter = Counter(proxyAddress);
        console.log("Owner after upgrade:", counter.owner());
        console.log("Total increments after upgrade:", counter.totalIncrements());
        console.log("Unique users after upgrade:", counter.uniqueUsers());

        vm.stopBroadcast();

        // 5. Update deployment file
        _updateDeploymentFile(chainId, path, address(newImplementation), oldImplementation);

        console.log("\n=== Upgrade Complete ===");
        console.log("New implementation:", address(newImplementation));
        console.log("Proxy (unchanged):", proxyAddress);
    }

    function _updateDeploymentFile(
        uint256 chainId,
        string memory path,
        address newImplementation,
        address oldImplementation
    ) internal {
        // Read existing deployment
        string memory existingJson = vm.readFile(path);

        // Create updated deployment object
        string memory obj = "deployment";

        // Copy existing values
        vm.serializeUint(obj, "chainId", chainId);
        vm.serializeUint(obj, "timestamp", block.timestamp);
        vm.serializeAddress(obj, "deployer", vm.parseJsonAddress(existingJson, ".deployer"));

        // Update implementation address
        vm.serializeAddress(obj, "proxyAdmin", vm.parseJsonAddress(existingJson, ".proxyAdmin"));
        vm.serializeAddress(obj, "implementation", newImplementation);
        vm.serializeAddress(obj, "oldImplementation", oldImplementation);
        vm.serializeAddress(obj, "proxy", vm.parseJsonAddress(existingJson, ".proxy"));
        vm.serializeAddress(obj, "counter", vm.parseJsonAddress(existingJson, ".proxy"));
        vm.serializeAddress(obj, "lens", vm.parseJsonAddress(existingJson, ".lens"));

        vm.serializeUint(obj, "upgradeTimestamp", block.timestamp);
        string memory json = vm.serializeString(obj, "network", vm.parseJsonString(existingJson, ".network"));

        // Write updated file
        vm.writeJson(json, path);
        console.log("Deployment file updated:", path);
    }
}
