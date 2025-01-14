import type { HardhatRuntimeEnvironment } from "hardhat/types";
import type { DeployFunction } from "hardhat-deploy/types";

import type { Storage } from "../typechain-types/Storage";

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;

    const { deployer } = await getNamedAccounts();

    const deployment = await deploy("Storage", {
        from: deployer,
        args: [],
        log: true,
        waitConfirmations: 1,
    });

    const storage = (await hre.ethers.getContractAt(
        deployment.abi,
        deployment.address,
    )) as unknown as Storage;

    const address = await storage.getAddress();
    console.log("Storage deployed to:", address);

    if (hre.network.name !== "hardhat" && 
        hre.network.name !== "localhost" && 
        process.env.ETHERSCAN_API_KEY) {
        try {
            await hre.run("verify:verify", {
                address: deployment.address,
                constructorArguments: [],
            });
            console.log("Contract verified on Etherscan");
        } catch (error) {
            console.log("Verification failed:", error);
        }
    }
};

deploy.tags = ["Storage"];
export default deploy;
