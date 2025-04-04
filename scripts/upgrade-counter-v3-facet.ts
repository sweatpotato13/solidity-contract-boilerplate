import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "./libraries/diamond";

async function main() {
    console.log("=== Counter Storage Upgrade Started ===");

    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];
    const provider = ethers.provider;
    console.log("Account address:", contractOwner.address);

    // Get diamond address
    const diamondAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"; // Local hardhat default deployment address (change as needed)
    console.log("Diamond address:", diamondAddress);

    // CounterFacetV2 인터페이스 가져오기
    const CounterFacetV2 = await ethers.getContractFactory("CounterFacetV2");
    const counterV2Interface = CounterFacetV2.interface;

    // Check current counter value
    const getCountData = counterV2Interface.encodeFunctionData("getCount");
    const countResult = await provider.call({
        to: diamondAddress,
        data: getCountData
    });
    const currentCount = counterV2Interface.decodeFunctionResult("getCount", countResult)[0];
    console.log("Current counter value:", currentCount);

    // Deploy new storage library
    console.log("Deploying CounterFacetV3 with new LibCounterV2 library...");
    const CounterFacetV3 = await ethers.getContractFactory("CounterFacetV3");
    const counterFacetV3 = await CounterFacetV3.deploy();
    await counterFacetV3.waitForDeployment();
    const counterFacetV3Address = await counterFacetV3.getAddress();
    console.log("New CounterFacetV3 address:", counterFacetV3Address);

    // DiamondCut 인터페이스 가져오기
    const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
    const diamondCutInterface = DiamondCutFacet.interface;

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
    console.log("Existing CounterFacetV2 functions removed!");

    console.log("Adding new CounterFacetV3 functions...");
    
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
    console.log("New CounterFacetV3 functions added!");

    // CounterFacetV3 인터페이스 가져오기
    const counterV3Interface = CounterFacetV3.interface;

    // Initialize and migrate storage
    console.log("Running storage migration...");
    const initV3Data = counterV3Interface.encodeFunctionData("initializeV3");
    const txInit = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: initV3Data
    });
    await txInit.wait();
    console.log("Storage migration completed!");

    // Verify upgrade - getCount 호출
    const getCountV3Data = counterV3Interface.encodeFunctionData("getCount");
    const countV3Result = await provider.call({
        to: diamondAddress,
        data: getCountV3Data
    });
    const count = counterV3Interface.decodeFunctionResult("getCount", countV3Result)[0];
    console.log(
        "Counter value after upgrade (should be preserved):",
        count.toString(),
    );

    // Test new functionality - getCounterInfo 호출
    const getCounterInfoData = counterV3Interface.encodeFunctionData("getCounterInfo");
    const counterInfoResult = await provider.call({
        to: diamondAddress,
        data: getCounterInfoData
    });
    
    // 디버깅 정보 출력
    console.log("Raw counterInfoResult:", counterInfoResult);
    
    // 결과 디코딩
    const counterInfoDecoded = counterV3Interface.decodeFunctionResult("getCounterInfo", counterInfoResult);
    console.log("Decoded counterInfo:", counterInfoDecoded);
    
    // counterInfo가 배열이 아닌 객체일 수 있으므로 적절히 처리
    const counterInfo = counterInfoDecoded[0];
    console.log("Extended counter information:");
    
    if (counterInfo && Array.isArray(counterInfo)) {
        console.log("  Counter value:", counterInfo[0]?.toString() || "N/A");
        console.log("  Last incremented:", counterInfo[1] || "N/A");
        console.log("  Last decremented:", counterInfo[2] || "N/A");
        console.log("  Total increments:", counterInfo[3]?.toString() || "N/A");
        console.log("  Total decrements:", counterInfo[4]?.toString() || "N/A");
        console.log("  Last modifier:", counterInfo[5] || "N/A");
    } else if (counterInfo && typeof counterInfo === 'object') {
        // 객체 형태로 반환될 경우
        console.log("  Counter value:", counterInfo.count?.toString() || "N/A");
        console.log("  Last incremented:", counterInfo.lastIncremented || "N/A");
        console.log("  Last decremented:", counterInfo.lastDecremented || "N/A");
        console.log("  Total increments:", counterInfo.totalIncrements?.toString() || "N/A");
        console.log("  Total decrements:", counterInfo.totalDecrements?.toString() || "N/A");
        console.log("  Last modifier:", counterInfo.lastModifier || "N/A");
    } else {
        console.log("  Unable to parse counter info:", counterInfo);
    }

    // Test increment operation
    console.log("Testing counter increment...");
    const incrementData = counterV3Interface.encodeFunctionData("increment");
    const txIncrement = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: incrementData
    });
    await txIncrement.wait();

    // Get updated information
    const updatedCountData = counterV3Interface.encodeFunctionData("getCount");
    const updatedCountResult = await provider.call({
        to: diamondAddress,
        data: updatedCountData
    });
    const updatedCount = counterV3Interface.decodeFunctionResult("getCount", updatedCountResult)[0];
    
    const totalIncrementsData = counterV3Interface.encodeFunctionData("getTotalIncrements");
    const totalIncrementsResult = await provider.call({
        to: diamondAddress,
        data: totalIncrementsData
    });
    const totalIncrements = counterV3Interface.decodeFunctionResult("getTotalIncrements", totalIncrementsResult)[0];
    
    const lastModifierData = counterV3Interface.encodeFunctionData("getLastModifier");
    const lastModifierResult = await provider.call({
        to: diamondAddress,
        data: lastModifierData
    });
    const lastModifier = counterV3Interface.decodeFunctionResult("getLastModifier", lastModifierResult)[0];

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
