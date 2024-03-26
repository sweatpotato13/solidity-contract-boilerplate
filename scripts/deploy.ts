import type { HardhatRuntimeEnvironment } from "hardhat/types";
import type { DeployFunction } from "hardhat-deploy/types";

import type { Storage } from "../typechain-types/Storage";

const deploy: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
    const { deployments, getNamedAccounts } = hre;
    const { deploy } = deployments;

    const { deployer } = await getNamedAccounts();

    const deployment = await deploy("Storage", {
        from: deployer,
        log: true,
    });

    const storage = (await hre.ethers.getContractAt(
        deployment.abi,
        deployment.address,
    )) as unknown as Storage;

    const address = await storage.getAddress();
    console.log("Storage deployed to:", address);

    if (hre.network.name != "hardhat") {
        await hre.run("etherscan-verify", {
            network: hre.network.name,
        });
    }
};

export default deploy;
