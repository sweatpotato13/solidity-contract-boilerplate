import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "./libraries/diamond";

async function main() {
    console.log("=== Calculator Facet Addition Started ===");

    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];
    const provider = ethers.provider;
    console.log("Account address:", contractOwner.address);

    // Get diamond address - update this with your actual diamond address
    const diamondAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"; // Local hardhat default deployment address (change as needed)
    console.log("Diamond address:", diamondAddress);

    // Deploy CalculatorFacet
    const CalculatorFacet = await ethers.getContractFactory("CalculatorFacet");
    const calculatorFacet = await CalculatorFacet.deploy();
    await calculatorFacet.waitForDeployment();
    const calculatorFacetAddress = await calculatorFacet.getAddress();
    console.log("CalculatorFacet deployed at:", calculatorFacetAddress);

    // Get selectors for CalculatorFacet
    const selectors = getSelectors(calculatorFacet);
    console.log("CalculatorFacet selectors:", selectors);

    // DiamondCut 인터페이스 가져오기
    const DiamondCutFacet = await ethers.getContractFactory("DiamondCutFacet");
    const diamondCutInterface = DiamondCutFacet.interface;

    // Prepare the cut
    const cut = [
        {
            facetAddress: calculatorFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: selectors,
        },
    ];

    // Add the CalculatorFacet to the diamond (fallback 함수 사용)
    console.log("Adding CalculatorFacet to diamond...");

    // diamondCut 함수 호출 데이터 인코딩
    const diamondCutData = diamondCutInterface.encodeFunctionData(
        "diamondCut",
        [cut, ethers.ZeroAddress, "0x"],
    );

    // 트랜잭션 전송
    const tx = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: diamondCutData,
    });
    await tx.wait();
    console.log("CalculatorFacet added to diamond!");

    // 테스트를 위한 CalculatorFacet 인터페이스 가져오기
    const calculatorInterface = CalculatorFacet.interface;

    // Test the calculator functions
    console.log("\n=== Testing Calculator Functions ===");

    // Set initial value to 10
    console.log("Setting initial value to 10...");
    const setValueData = calculatorInterface.encodeFunctionData("setValue", [
        10,
    ]);
    const tx1 = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: setValueData,
    });
    await tx1.wait();

    // Check result
    const getResultData = calculatorInterface.encodeFunctionData("getResult");
    const resultData = await provider.call({
        to: diamondAddress,
        data: getResultData,
    });
    let result = calculatorInterface.decodeFunctionResult(
        "getResult",
        resultData,
    )[0];
    console.log("Initial value:", result);

    // Add 5
    console.log("Adding 5...");
    const addData = calculatorInterface.encodeFunctionData("add", [5]);
    const tx2 = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: addData,
    });
    await tx2.wait();

    const resultData2 = await provider.call({
        to: diamondAddress,
        data: getResultData,
    });
    result = calculatorInterface.decodeFunctionResult(
        "getResult",
        resultData2,
    )[0];
    console.log("After adding 5:", result);

    // Subtract 3
    console.log("Subtracting 3...");
    const subtractData = calculatorInterface.encodeFunctionData("subtract", [
        3,
    ]);
    const tx3 = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: subtractData,
    });
    await tx3.wait();

    const resultData3 = await provider.call({
        to: diamondAddress,
        data: getResultData,
    });
    result = calculatorInterface.decodeFunctionResult(
        "getResult",
        resultData3,
    )[0];
    console.log("After subtracting 3:", result);

    // Multiply by 2
    console.log("Multiplying by 2...");
    const multiplyData = calculatorInterface.encodeFunctionData("multiply", [
        2,
    ]);
    const tx4 = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: multiplyData,
    });
    await tx4.wait();

    const resultData4 = await provider.call({
        to: diamondAddress,
        data: getResultData,
    });
    result = calculatorInterface.decodeFunctionResult(
        "getResult",
        resultData4,
    )[0];
    console.log("After multiplying by 2:", result);

    // Divide by 4
    console.log("Dividing by 4...");
    const divideData = calculatorInterface.encodeFunctionData("divide", [4]);
    const tx5 = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: divideData,
    });
    await tx5.wait();

    const resultData5 = await provider.call({
        to: diamondAddress,
        data: getResultData,
    });
    result = calculatorInterface.decodeFunctionResult(
        "getResult",
        resultData5,
    )[0];
    console.log("After dividing by 4:", result);

    // Get operation count
    const getOpCountData =
        calculatorInterface.encodeFunctionData("getOperationCount");
    const opCountData = await provider.call({
        to: diamondAddress,
        data: getOpCountData,
    });
    const opCount = calculatorInterface.decodeFunctionResult(
        "getOperationCount",
        opCountData,
    )[0];
    console.log("Total operations performed:", opCount);

    // Get last operator
    const getLastOpData =
        calculatorInterface.encodeFunctionData("getLastOperator");
    const lastOpData = await provider.call({
        to: diamondAddress,
        data: getLastOpData,
    });
    const lastOperator = calculatorInterface.decodeFunctionResult(
        "getLastOperator",
        lastOpData,
    )[0];
    console.log("Last operator:", lastOperator);

    // Reset the calculator
    console.log("Resetting calculator...");
    const resetData = calculatorInterface.encodeFunctionData("reset");
    const tx6 = await contractOwner.sendTransaction({
        to: diamondAddress,
        data: resetData,
    });
    await tx6.wait();

    const resultData6 = await provider.call({
        to: diamondAddress,
        data: getResultData,
    });
    result = calculatorInterface.decodeFunctionResult(
        "getResult",
        resultData6,
    )[0];
    console.log("After reset:", result);

    console.log("\n=== Calculator Facet Addition and Tests Completed ===");
}

// Run script
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
