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
    const { deployments, getNamedAccounts, ethers, network, run } = hre as any;
    const { deploy } = deployments;

    const { deployer } = await getNamedAccounts();

    // Helper function to wait for a specific block number
    async function waitForBlockNumber(provider: any, targetBlockNumber: number) {
        return new Promise<void>((resolve) => {
            const checkBlockNumber = () => {
                provider.getBlockNumber().then((currentBlock: number) => {
                    if (currentBlock >= targetBlockNumber) {
                        resolve();
                        return;
                    }
                    // Poll every 5 seconds
                    setTimeout(checkBlockNumber, 5000);
                });
            };
            checkBlockNumber();
        });
    }

    // Helper function to verify contracts
    async function verifyContract(address: string, constructorArguments: any[] = [], deployment?: any) {
        // Etherscan verification: Check if API key is set
        try {
            if (network.name !== "hardhat" && network.name !== "localhost") {
                // Wait for sufficient confirmations
                if (deployment && deployment.receipt) {
                    // If we have the deployment receipt, we can wait for confirmations
                    const provider = ethers.provider;
                    const txHash = deployment.receipt.transactionHash;
                    
                    console.log(`Waiting for transaction ${txHash} to be confirmed...`);
                    
                    // Wait for 5 confirmations as recommended
                    const targetConfirmations = 5;
                    const currentBlock = await provider.getBlockNumber();
                    const txBlockNumber = deployment.receipt.blockNumber;
                    
                    // Calculate how many confirmations we already have
                    const confirmations = currentBlock - txBlockNumber + 1;
                    
                    if (confirmations < targetConfirmations) {
                        const blocksToWait = targetConfirmations - confirmations;
                        console.log(`Currently at ${confirmations} confirmations, waiting for ${blocksToWait} more blocks...`);
                        
                        // Wait for additional confirmations - use our custom waitForBlockNumber function
                        const targetBlockNumber = currentBlock + blocksToWait;
                        await waitForBlockNumber(provider, targetBlockNumber);
                    }
                    
                    console.log(`Transaction confirmed with ${targetConfirmations}+ confirmations`);
                } else {
                    // If we don't have deployment receipt, fall back to time-based waiting
                    console.log(`No deployment receipt available for ${address}, waiting 30 seconds...`);
                    await new Promise(resolve => setTimeout(resolve, 30000));
                }
                
                // Attempt to verify the contract
                let verified = false;
                let retries = 3; // Maximum number of retry attempts
                
                while (!verified && retries > 0) {
                    try {
                        console.log(`Attempting to verify contract ${address}... (${retries} attempts left)`);
                        await run("verify:verify", {
                            address: address,
                            constructorArguments: constructorArguments
                        });
                        console.log(`${address} verification complete!`);
                        verified = true;
                    } catch (verifyError: any) {
                        if (verifyError.message.includes("Already Verified") || 
                            verifyError.message.includes("Reason: Already Verified")) {
                            console.log(`${address}: ${verifyError.message}`);
                            verified = true; // Consider it verified
                        } else if (verifyError.message.includes("does not have bytecode") || 
                                 verifyError.message.includes("has not been deployed")) {
                            // Contract not found on the blockchain yet, wait and retry
                            retries--;
                            if (retries > 0) {
                                console.log(`Contract not fully propagated to Etherscan yet. Waiting 20 seconds before retry...`);
                                await new Promise(resolve => setTimeout(resolve, 20000));
                            } else {
                                console.error(`Failed to verify ${address} after multiple attempts:`, verifyError.message);
                            }
                        } else if (verifyError.message.includes("Missing or invalid ApiKey")) {
                            console.log(`${address}: ${verifyError.message}`);
                            verified = true; // Skip further attempts if API key is invalid
                        } else {
                            // Other errors
                            console.error(`${address} verification failed:`, verifyError.message);
                            retries--;
                            if (retries > 0) {
                                console.log(`Waiting 10 seconds before retry...`);
                                await new Promise(resolve => setTimeout(resolve, 10000));
                            }
                        }
                    }
                }
            }
        } catch (error: any) {
            console.error(`Error during verification process for ${address}:`, error.message);
        }
    }

    // Deploy DiamondCutFacet
    const diamondCutFacet = await deploy("DiamondCutFacet", {
        from: deployer,
        log: true,
    });

    console.log("DiamondCutFacet deployed:", diamondCutFacet.address);
    
    // Verify DiamondCutFacet
    await verifyContract(diamondCutFacet.address, [], diamondCutFacet);

    // Deploy Diamond
    const diamond = await deploy("Diamond", {
        from: deployer,
        args: [deployer, diamondCutFacet.address],
        log: true,
    });

    console.log("Diamond deployed:", diamond.address);
    
    // Verify Diamond with constructor arguments
    await verifyContract(diamond.address, [deployer, diamondCutFacet.address], diamond);

    // Deploy DiamondInit
    const diamondInit = await deploy("DiamondInit", {
        from: deployer,
        log: true,
    });

    console.log("DiamondInit deployed:", diamondInit.address);
    
    // Verify DiamondInit
    await verifyContract(diamondInit.address, [], diamondInit);

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
        
        // Verify facet
        await verifyContract(facetDeployment.address, [], facetDeployment);

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
