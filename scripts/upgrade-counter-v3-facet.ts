import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "./libraries/diamond";

async function main() {
    console.log("=== Counter Storage Upgrade Started ===");

    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];
    console.log("Account address:", contractOwner.address);

    // Get diamond address
    const diamondAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"; // Local hardhat default deployment address (change as needed)
    console.log("Diamond address:", diamondAddress);

    // Get latest CounterFacet version (assume V2)
    const CounterFacetV2 = await ethers.getContractFactory("CounterFacetV2");
    const counterFacetV2 = CounterFacetV2.attach(diamondAddress);

    // Check current counter value
    const currentCount = await counterFacetV2.getCount();
    console.log("Current counter value:", currentCount);

    // Deploy new storage library
    console.log("Deploying CounterFacetV3 with new LibCounterV2 library...");
    const CounterFacetV3 = await ethers.getContractFactory("CounterFacetV3");
    const counterFacetV3 = await CounterFacetV3.deploy();
    await counterFacetV3.waitForDeployment();
    const counterFacetV3Address = await counterFacetV3.getAddress();
    console.log("New CounterFacetV3 address:", counterFacetV3Address);

    // Instantiate diamond cut facet (for upgrade execution)
    const diamondCutFacet = await ethers.getContractAt(
        "IDiamondCut",
        diamondAddress,
    );

    // Get selectors for existing V2 functions to remove
    const selectorsV2 = getSelectors(CounterFacetV2);

    // Get selectors for new V3 functions to add
    const selectorsV3 = getSelectors(counterFacetV3);

    // Step 1: Remove existing CounterFacetV2 functionality
    const cutRemove = {
        facetAddress: ethers.ZeroAddress,
        action: FacetCutAction.Remove,
        functionSelectors: selectorsV2,
    };

    // Step 2: Add new CounterFacetV3 functionality
    const cutAdd = {
        facetAddress: counterFacetV3Address,
        action: FacetCutAction.Add,
        functionSelectors: selectorsV3,
    };

    console.log("V2 selectors to remove:", selectorsV2);
    console.log("V3 selectors to add:", selectorsV3);

    // Execute upgrade (remove then add)
    console.log("Removing existing CounterFacetV2 functions...");
    const txRemove = await diamondCutFacet.diamondCut(
        [cutRemove],
        ethers.ZeroAddress,
        "0x",
    );
    await txRemove.wait();
    console.log("Existing CounterFacetV2 functions removed!");

    console.log("Adding new CounterFacetV3 functions...");
    const txAdd = await diamondCutFacet.diamondCut(
        [cutAdd],
        ethers.ZeroAddress,
        "0x",
    );
    await txAdd.wait();
    console.log("New CounterFacetV3 functions added!");

    // Create proxy instance of CounterFacetV3
    const counterFacetV3Proxy = await ethers.getContractAt(
        "CounterFacetV3",
        diamondAddress,
    );

    // Initialize and migrate storage
    console.log("Running storage migration...");
    const txInit = await counterFacetV3Proxy.initializeV3();
    await txInit.wait();
    console.log("Storage migration completed!");

    // Verify upgrade
    const count = await counterFacetV3Proxy.getCount();
    console.log(
        "Counter value after upgrade (should be preserved):",
        count.toString(),
    );

    // Test new functionality
    const counterInfo = await counterFacetV3Proxy.getCounterInfo();
    console.log("Extended counter information:");
    console.log("  Counter value:", counterInfo[0].toString());
    console.log("  Last incremented:", counterInfo[1]);
    console.log("  Last decremented:", counterInfo[2]);
    console.log("  Total increments:", counterInfo[3].toString());
    console.log("  Total decrements:", counterInfo[4].toString());
    console.log("  Last modifier:", counterInfo[5]);

    // Test increment operation
    console.log("Testing counter increment...");
    const txIncrement = await counterFacetV3Proxy.increment();
    await txIncrement.wait();

    // Get updated information
    const updatedCount = await counterFacetV3Proxy.getCount();
    const totalIncrements = await counterFacetV3Proxy.getTotalIncrements();
    const lastModifier = await counterFacetV3Proxy.getLastModifier();

    console.log("Counter value after increment:", updatedCount.toString());
    console.log("Total increments:", totalIncrements.toString());
    console.log("Last modifier:", lastModifier);

    console.log("=== Counter Storage Upgrade Completed ===");
}

// Run script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
