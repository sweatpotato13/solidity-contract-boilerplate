// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../src/Counter.sol";
import "../src/CounterInstance.sol";
import "../src/CounterLens.sol";

/**
 * @title DeployTransparentScript
 * @notice Deployment script for TransparentUpgradeableProxy + Counter + Lens
 * @dev Usage: forge script scripts/Deploy.s.sol:DeployTransparentScript --rpc-url <RPC_URL> --broadcast
 */
contract DeployTransparentScript is Script {
    // Deployed contracts
    ProxyAdmin public proxyAdmin;
    CounterInstance public implementation;
    TransparentUpgradeableProxy public proxy;
    Counter public counter;
    CounterLens public lens;
    
    // Configuration
    address public deployer;
    
    function setUp() public {
        deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
    }
    
    function run() public {
        console.log("=== TransparentUpgradeableProxy Deployment ===");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        // 1. Deploy CounterInstance Implementation
        implementation = new CounterInstance();
        console.log("CounterInstance Implementation deployed at:", address(implementation));
        
        // 2. Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(Counter.initialize.selector, deployer);
        
        // 3. Deploy TransparentUpgradeableProxy (v5 creates ProxyAdmin internally!)
        proxy = new TransparentUpgradeableProxy(
            address(implementation),
            deployer, // initialOwner (becomes ProxyAdmin owner)
            initData
        );
        console.log("TransparentUpgradeableProxy deployed at:", address(proxy));
        
        // 4. Get the auto-created ProxyAdmin address
        proxyAdmin = ProxyAdmin(
            address(
                uint160(
                    uint256(vm.load(address(proxy), bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)))
                )
            )
        );
        console.log("ProxyAdmin (auto-created) at:", address(proxyAdmin));
        
        // 5. Create interface to interact with proxy
        counter = Counter(address(proxy));
        
        // 6. Deploy CounterLens (no proxy needed!)
        lens = new CounterLens();
        console.log("CounterLens deployed at:", address(lens));
        
        // 7. Verify deployment
        _verifyDeployment();
        
        // 8. Save deployment addresses
        _saveDeployment();
        
        vm.stopBroadcast();
        
        console.log("\n=== Deployment Complete ===");
        console.log("Use these addresses:");
        console.log("- Counter (Proxy):", address(proxy));
        console.log("- CounterLens:", address(lens));
        console.log("- ProxyAdmin:", address(proxyAdmin));
    }
    
    function _verifyDeployment() internal {
        console.log("\n=== Verifying Deployment ===");
        
        // Verify owner
        address contractOwner = counter.owner();
        require(contractOwner == deployer, "Owner mismatch");
        console.log("Owner verified:", contractOwner);
        
        // Verify initial state
        uint256 totalIncrements = counter.totalIncrements();
        require(totalIncrements == 0, "Initial state mismatch");
        console.log("Total increments (should be 0):", totalIncrements);
        
        uint256 uniqueUsers = counter.uniqueUsers();
        require(uniqueUsers == 0, "Unique users mismatch");
        console.log("Unique users (should be 0):", uniqueUsers);
        
        // Verify Lens can read from counter
        uint256 deployerCount = lens.getCount(address(counter), deployer);
        require(deployerCount == 0, "Lens read failed");
        console.log("Lens verification successful");
        
        console.log("All verifications passed!");
    }
    
    function _saveDeployment() internal {
        string memory obj = "deployment";
        
        // Chain and deployment info
        vm.serializeUint(obj, "chainId", block.chainid);
        vm.serializeUint(obj, "timestamp", block.timestamp);
        vm.serializeAddress(obj, "deployer", deployer);
        
        // Contract addresses
        vm.serializeAddress(obj, "proxyAdmin", address(proxyAdmin));
        vm.serializeAddress(obj, "implementation", address(implementation));
        vm.serializeAddress(obj, "proxy", address(proxy));
        vm.serializeAddress(obj, "counter", address(proxy));
        vm.serializeAddress(obj, "lens", address(lens));
        
        string memory json = vm.serializeString(obj, "network", _getNetworkName());
        
        // Write to file
        string memory path = string.concat("deployments/", vm.toString(block.chainid), ".json");
        vm.writeJson(json, path);
        
        console.log("\nDeployment info saved to:", path);
    }
    
    function _getNetworkName() internal view returns (string memory) {
        uint256 chainId = block.chainid;
        if (chainId == 1) return "ethereum";
        if (chainId == 11155111) return "sepolia";
        if (chainId == 8453) return "base";
        if (chainId == 84532) return "base-sepolia";
        if (chainId == 31337) return "local";
        return "unknown";
    }
}
