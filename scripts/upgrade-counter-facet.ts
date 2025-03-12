import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "./libraries/diamond";

async function main() {
    console.log("=== Counter Facet Upgrade Started ===");

    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];
    console.log("Account address:", contractOwner.address);

    // Get diamond address
    const diamondAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"; // Local hardhat default deployment address (change as needed)
    console.log("Diamond address:", diamondAddress);

    // Instantiate existing CounterFacet
    const CounterFacet = await ethers.getContractFactory("CounterFacet");
    const counterFacet = await CounterFacet.deploy();
    await counterFacet.waitForDeployment();
    const counterFacetAddress = await counterFacet.getAddress();
    console.log("Existing CounterFacet address:", counterFacetAddress);

    // Instantiate new CounterFacetV2
    const CounterFacetV2 = await ethers.getContractFactory("CounterFacetV2");
    const counterFacetV2 = await CounterFacetV2.deploy();
    await counterFacetV2.waitForDeployment();
    const counterFacetV2Address = await counterFacetV2.getAddress();
    console.log("New CounterFacetV2 address:", counterFacetV2Address);

    // Instantiate diamond cut facet (for upgrade execution)
    const diamondCutFacet = await ethers.getContractAt(
        "IDiamondCut",
        diamondAddress,
    );

    // Get selectors for existing functions to remove
    const selectors = getSelectors(counterFacet);

    // Get selectors for new V2 functions to add
    const selectorsV2 = getSelectors(counterFacetV2);

    // Step 1: Remove existing CounterFacet functionality
    const cutRemove = {
        facetAddress: ethers.ZeroAddress,
        action: FacetCutAction.Remove,
        functionSelectors: selectors,
    };

    // Step 2: Add new CounterFacetV2 functionality
    const cutAdd = {
        facetAddress: counterFacetV2Address,
        action: FacetCutAction.Add,
        functionSelectors: selectorsV2,
    };

    console.log("Selectors to remove:", selectors);
    console.log("Selectors to add:", selectorsV2);

    // Execute upgrade (remove then add)
    console.log("Removing existing CounterFacet functions...");
    const txRemove = await diamondCutFacet.diamondCut(
        [cutRemove],
        ethers.ZeroAddress,
        "0x",
    );
    await txRemove.wait();
    console.log("Existing CounterFacet functions removed!");

    console.log("Adding new CounterFacetV2 functions...");
    const txAdd = await diamondCutFacet.diamondCut(
        [cutAdd],
        ethers.ZeroAddress,
        "0x",
    );
    await txAdd.wait();
    console.log("New CounterFacetV2 functions added!");

    // Verify upgrade
    const counterFacetV2Test = await ethers.getContractAt(
        "CounterFacetV2",
        diamondAddress,
    );
    const count = await counterFacetV2Test.getCount();
    console.log("Current counter value:", count);

    // Test new function
    const isMultipleOfTwo = await counterFacetV2Test.isMultipleOf(2);
    console.log("Is counter a multiple of 2?", isMultipleOfTwo);

    console.log("=== Counter Facet Upgrade Completed ===");
}

// Run script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
