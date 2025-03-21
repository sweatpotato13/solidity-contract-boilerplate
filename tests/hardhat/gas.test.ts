import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "../../scripts/libraries/diamond";

describe("Diamond Gas Measurements", function () {
    // Deploy diamond fixture
    async function deployDiamondFixture() {
        const [owner, user1] = await ethers.getSigners();

        // Deploy DiamondCutFacet
        const DiamondCutFacet =
            await ethers.getContractFactory("DiamondCutFacet");
        const diamondCutFacet = await DiamondCutFacet.deploy();
        await diamondCutFacet.waitForDeployment();

        // Deploy Diamond
        const Diamond = await ethers.getContractFactory("Diamond");
        const diamond = await Diamond.deploy(
            owner.address,
            await diamondCutFacet.getAddress(),
        );
        await diamond.waitForDeployment();

        // Deploy DiamondInit
        const DiamondInit = await ethers.getContractFactory("DiamondInit");
        const diamondInit = await DiamondInit.deploy();
        await diamondInit.waitForDeployment();

        // Deploy facets
        const FacetNames = [
            "DiamondLoupeFacet",
            "OwnershipFacet",
            "CounterFacet",
            "ERC20Facet",
        ];
        const facets = [];
        const cut = [];

        for (const FacetName of FacetNames) {
            const Facet = await ethers.getContractFactory(FacetName);
            const facet = await Facet.deploy();
            await facet.waitForDeployment();
            facets.push(facet);

            cut.push({
                facetAddress: await facet.getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(facet),
            });
        }

        // Upgrade diamond with facets
        const diamondCut = await ethers.getContractAt(
            "IDiamondCut",
            await diamond.getAddress(),
        );

        // Initialize diamond
        const functionCall = diamondInit.interface.encodeFunctionData("init");
        const tx = await diamondCut.diamondCut(
            cut,
            await diamondInit.getAddress(),
            functionCall,
        );
        await tx.wait();

        const diamondAddress = await diamond.getAddress();

        // Create instances for each facet
        const counterFacet = await ethers.getContractAt(
            "CounterFacet",
            diamondAddress,
        );
        const erc20Facet = (await ethers.getContractAt(
            "ERC20Facet",
            diamondAddress,
        )) as any;

        return {
            diamond,
            diamondCut,
            counterFacet,
            erc20Facet,
            owner,
            user1,
            diamondAddress,
        };
    }

    it("Measures gas cost for function calls across facets", async function () {
        const { counterFacet, erc20Facet, owner, user1 } =
            await loadFixture(deployDiamondFixture);

        // Measure gas for counter operations
        console.log("Gas measurements for Counter operations:");

        // Get initial count - read operation
        const getCountGas = await counterFacet.getCount.estimateGas();
        console.log(`  getCount: ${getCountGas} gas`);

        // Increment counter - write operation
        const incrementGas = await counterFacet.increment.estimateGas();
        console.log(`  increment: ${incrementGas} gas`);

        // Set count - write operation with parameter
        const setCountGas = await counterFacet.setCount.estimateGas(42);
        console.log(`  setCount: ${setCountGas} gas`);

        // Measure gas for ERC20 operations
        console.log("\nGas measurements for ERC20 operations:");

        // Name - read operation
        const nameGas = await erc20Facet.name.estimateGas();
        console.log(`  name: ${nameGas} gas`);

        // Mint tokens - write operation
        const mintAmount = ethers.parseEther("1000");
        const mintGas = await erc20Facet.mint.estimateGas(
            owner.address,
            mintAmount,
        );
        console.log(`  mint: ${mintGas} gas`);

        // Execute the mint to perform transfer test
        await erc20Facet.mint(owner.address, mintAmount);

        // Transfer tokens - write operation
        const transferAmount = ethers.parseEther("100");
        const transferGas = await erc20Facet.transfer.estimateGas(
            user1.address,
            transferAmount,
        );
        console.log(`  transfer: ${transferGas} gas`);

        // Approve tokens - write operation
        const approveGas = await erc20Facet.approve.estimateGas(
            user1.address,
            transferAmount,
        );
        console.log(`  approve: ${approveGas} gas`);

        // Check all operations executed properly
        await counterFacet.increment();
        await counterFacet.setCount(42);
        await erc20Facet.mint(owner.address, mintAmount);
        await erc20Facet.transfer(user1.address, transferAmount);
        await erc20Facet.approve(user1.address, transferAmount);

        // Verify state changes
        expect(await counterFacet.getCount()).to.equal(42);
        expect(await erc20Facet.balanceOf(user1.address)).to.equal(
            transferAmount,
        );
        expect(
            await erc20Facet.allowance(owner.address, user1.address),
        ).to.equal(transferAmount);
    });

    it("Measures gas cost for diamond upgrades", async function () {
        const { diamondCut, diamondAddress } =
            await loadFixture(deployDiamondFixture);

        // Deploy a new facet for replacement
        const CounterFacetV2 = await ethers.getContractFactory("CounterFacet");
        const counterFacetV2 = await CounterFacetV2.deploy();
        await counterFacetV2.waitForDeployment();

        // Get selectors
        const selectors = getSelectors(counterFacetV2);

        console.log("Gas measurements for Diamond cut operations:");

        // Measure gas for replacing a facet
        const replaceFacetGas = await diamondCut.diamondCut.estimateGas(
            [
                {
                    facetAddress: await counterFacetV2.getAddress(),
                    action: FacetCutAction.Replace,
                    functionSelectors: selectors,
                },
            ],
            ethers.ZeroAddress,
            "0x",
        );

        console.log(`  Replace facet: ${replaceFacetGas} gas`);

        // Execute the replacement
        const replaceTx = await diamondCut.diamondCut(
            [
                {
                    facetAddress: await counterFacetV2.getAddress(),
                    action: FacetCutAction.Replace,
                    functionSelectors: selectors,
                },
            ],
            ethers.ZeroAddress,
            "0x",
        );

        await replaceTx.wait();

        // Measure gas for removing a facet
        const removeFacetGas = await diamondCut.diamondCut.estimateGas(
            [
                {
                    facetAddress: ethers.ZeroAddress,
                    action: FacetCutAction.Remove,
                    functionSelectors: selectors,
                },
            ],
            ethers.ZeroAddress,
            "0x",
        );

        console.log(`  Remove facet: ${removeFacetGas} gas`);

        // Just for verification, we won't execute removal to keep tests functional
        console.log("\nVerifying facet replacement was successful");
        const updatedCounter = await ethers.getContractAt(
            "CounterFacet",
            diamondAddress,
        );
        await updatedCounter.setCount(100);
        expect(await updatedCounter.getCount()).to.equal(100);
    });
});
