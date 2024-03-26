import * as dotenv from "dotenv";
import type { HardhatUserConfig } from "hardhat/config";
import "hardhat-preprocessor";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-verify";
import "hardhat-deploy";

dotenv.config();

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",
    solidity: {
        version: "0.8.11",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    namedAccounts: {
        deployer: 0,
    },
    networks: {
        hardhat: {},
        local: {
            url: `http://127.0.0.1:8545`,
            accounts: [
                `${
                    process.env.DEPLOYER_PRIVATE_KEY ??
                    // use predefined account if deployer not defined
                    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
                }`,
            ],
        },
        sepolia: {
            url: `${process.env.SEPOLIA_PROVIDER_URL}`,
            accounts: [
                `${
                    process.env.DEPLOYER_PRIVATE_KEY ??
                    // use predefined account if deployer not defined
                    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
                }`,
            ],
        },
    },
    etherscan: {
        apiKey: {
            sepolia: `${process.env.ETHERSCAN_API_KEY}`,
        },
    },
    paths: {
        deploy: "./scripts",
        sources: "./src/contracts",
        tests: "./test",
        cache: "./cache",
        artifacts: "./artifacts",
    },
    mocha: {
        timeout: 40000,
    },
};

export default config;
