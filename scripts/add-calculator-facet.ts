import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "./libraries/diamond";

async function main() {
    console.log("=== Calculator Facet Addition Started ===");

    const accounts = await ethers.getSigners();
    const contractOwner = accounts[0];
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

    // Get diamond cut facet for adding the new facet
    const diamondCutFacet = await ethers.getContractAt(
        "IDiamondCut",
        diamondAddress,
    );

    // Prepare the cut
    const cut = [
        {
            facetAddress: calculatorFacetAddress,
            action: FacetCutAction.Add,
            functionSelectors: selectors,
        },
    ];

    // Add the CalculatorFacet to the diamond
    console.log("Adding CalculatorFacet to diamond...");
    const tx = await diamondCutFacet.diamondCut(cut, ethers.ZeroAddress, "0x");
    await tx.wait();
    console.log("CalculatorFacet added to diamond!");

    // Get the facet from the diamond for testing
    const calculatorFacetOnDiamond = await ethers.getContractAt(
        "CalculatorFacet",
        diamondAddress,
    );

    // Test the calculator functions
    console.log("\n=== Testing Calculator Functions ===");

    // Set initial value to 10
    console.log("Setting initial value to 10...");
    await calculatorFacetOnDiamond.setValue(10);

    // Check result
    let result = await calculatorFacetOnDiamond.getResult();
    console.log("Initial value:", result);

    // Add 5
    console.log("Adding 5...");
    await calculatorFacetOnDiamond.add(5);
    result = await calculatorFacetOnDiamond.getResult();
    console.log("After adding 5:", result);

    // Subtract 3
    console.log("Subtracting 3...");
    await calculatorFacetOnDiamond.subtract(3);
    result = await calculatorFacetOnDiamond.getResult();
    console.log("After subtracting 3:", result);

    // Multiply by 2
    console.log("Multiplying by 2...");
    await calculatorFacetOnDiamond.multiply(2);
    result = await calculatorFacetOnDiamond.getResult();
    console.log("After multiplying by 2:", result);

    // Divide by 4
    console.log("Dividing by 4...");
    await calculatorFacetOnDiamond.divide(4);
    result = await calculatorFacetOnDiamond.getResult();
    console.log("After dividing by 4:", result);

    // Get operation count
    const opCount = await calculatorFacetOnDiamond.getOperationCount();
    console.log("Total operations performed:", opCount);

    // Get last operator
    const lastOperator = await calculatorFacetOnDiamond.getLastOperator();
    console.log("Last operator:", lastOperator);

    // Reset the calculator
    console.log("Resetting calculator...");
    await calculatorFacetOnDiamond.reset();
    result = await calculatorFacetOnDiamond.getResult();
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
