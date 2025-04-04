import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "./libraries/diamond";

async function main() {
    console.log("=== Counter Facet Upgrade Started ===");

    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];
    const provider = ethers.provider;
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

    // DiamondCut 인터페이스 가져오기
    const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
    const diamondCutInterface = DiamondCutFacet.interface;

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
    
    // diamondCut 함수 호출 데이터 인코딩 (remove)
    const removeCutData = diamondCutInterface.encodeFunctionData("diamondCut", [
        [cutRemove],
        ethers.ZeroAddress,
        "0x",
    ]);
    
    // 트랜잭션 전송 (remove)
    const txRemove = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: removeCutData
    });
    await txRemove.wait();
    console.log("Existing CounterFacet functions removed!");

    console.log("Adding new CounterFacetV2 functions...");
    
    // diamondCut 함수 호출 데이터 인코딩 (add)
    const addCutData = diamondCutInterface.encodeFunctionData("diamondCut", [
        [cutAdd],
        ethers.ZeroAddress,
        "0x",
    ]);
    
    // 트랜잭션 전송 (add)
    const txAdd = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: addCutData
    });
    await txAdd.wait();
    console.log("New CounterFacetV2 functions added!");

    // CounterFacetV2 인터페이스 가져오기
    const counterV2Interface = CounterFacetV2.interface;

    // Verify upgrade - getCount 호출
    const getCountData = counterV2Interface.encodeFunctionData("getCount");
    const countResult = await provider.call({
        to: diamondAddress,
        data: getCountData
    });
    const count = counterV2Interface.decodeFunctionResult("getCount", countResult)[0];
    console.log("Current counter value:", count);

    // Test new function - isMultipleOf(2) 호출
    const isMultipleOfData = counterV2Interface.encodeFunctionData("isMultipleOf", [2]);
    const isMultipleResult = await provider.call({
        to: diamondAddress,
        data: isMultipleOfData
    });
    const isMultipleOfTwo = counterV2Interface.decodeFunctionResult("isMultipleOf", isMultipleResult)[0];
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
