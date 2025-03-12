/* eslint prefer-const: "off" */

import "@nomicfoundation/hardhat-ethers";

import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

import { FacetCutAction,getSelectors } from "../scripts/libraries/diamond";

// Define interfaces for better type safety
interface FacetCut {
    facetAddress: string;
    action: FacetCutAction;
    functionSelectors: string[];
}

const deployDiamond: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts, ethers } = hre as any;
    const { deploy } = deployments;
    const { deployer } = await getNamedAccounts();

    // Deploy DiamondCutFacet
    const diamondCutFacet = await deploy("DiamondCutFacet", {
        from: deployer,
        log: true,
    });

    console.log("DiamondCutFacet deployed:", diamondCutFacet.address);

    // Deploy Diamond
    const diamond = await deploy("Diamond", {
        from: deployer,
        args: [deployer, diamondCutFacet.address],
        log: true,
    });

    console.log("Diamond deployed:", diamond.address);

    // Deploy DiamondInit
    // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
    // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
    const diamondInit = await deploy("DiamondInit", {
        from: deployer,
        log: true,
    });

    console.log("DiamondInit deployed:", diamondInit.address);

    // Deploy facets
    console.log("");
    console.log("Deploying facets");
    const FacetNames = ["DiamondLoupeFacet", "OwnershipFacet", "CounterFacet", "ERC20Facet"];

    const cut: FacetCut[] = [];
    for (const FacetName of FacetNames) {
        const facetDeployment = await deploy(FacetName, {
            from: deployer,
            log: true,
        });

        console.log(`${FacetName} deployed: ${facetDeployment.address}`);

        const facetContract = await ethers.getContractAt(FacetName, facetDeployment.address);

        cut.push({
            facetAddress: facetDeployment.address,
            action: FacetCutAction.Add,
            functionSelectors: getSelectors(facetContract) || [],
        });
    }

    // Upgrade diamond with facets
    console.log("");
    console.log("Diamond Cut:", cut);

    const diamondCutContract = await ethers.getContractAt("IDiamondCut", diamond.address);
    const diamondInitContract = await ethers.getContractAt("DiamondInit", diamondInit.address);

    // Call to init function
    let functionCall = diamondInitContract.interface.encodeFunctionData("init");
    const tx = await diamondCutContract.diamondCut(cut, diamondInit.address, functionCall);
    console.log("Diamond cut tx: ", tx.hash);

    const receipt = await tx.wait();
    if (!receipt || !receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`);
    }

    console.log("Completed diamond cut");
    return true; // hardhat-deploy expects a boolean or void return
};

deployDiamond.tags = ["diamond", "all"];
deployDiamond.id = "diamond";

export default deployDiamond;
