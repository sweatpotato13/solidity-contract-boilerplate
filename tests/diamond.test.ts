import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "../scripts/libraries/diamond";

describe("Diamond Contract Tests", function () {
    // Deploy diamond fixture
    async function deployDiamondFixture() {
        const [owner, otherAccount] = await ethers.getSigners();

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

        return {
            diamond,
            diamondCutFacet,
            facets,
            owner,
            otherAccount,
            diamondAddress: await diamond.getAddress(),
        };
    }

    describe("Deployment", function () {
        it("Should deploy the diamond and all facets", async function () {
            const { diamond, facets } = await loadFixture(deployDiamondFixture);
            expect(await diamond.getAddress()).to.not.equal(ethers.ZeroAddress);

            for (const facet of facets) {
                expect(await facet.getAddress()).to.not.equal(
                    ethers.ZeroAddress,
                );
            }
        });

        it("Should register facets in the diamond", async function () {
            const { diamondAddress } = await loadFixture(deployDiamondFixture);

            // Get DiamondLoupeFacet from the diamond address
            const diamondLoupe = await ethers.getContractAt(
                "DiamondLoupeFacet",
                diamondAddress,
            );

            // Get all facets
            const facetsFromDiamond = await diamondLoupe.facets();

            // We should have 5 facets (DiamondCutFacet + 4 others)
            expect(facetsFromDiamond.length).to.equal(5);
        });
    });

    describe("OwnershipFacet", function () {
        it("Should correctly set the owner", async function () {
            const { diamondAddress, owner } =
                await loadFixture(deployDiamondFixture);

            const ownershipFacet = await ethers.getContractAt(
                "OwnershipFacet",
                diamondAddress,
            );
            expect(await ownershipFacet.owner()).to.equal(owner.address);
        });

        it("Should allow owner to transfer ownership", async function () {
            const { diamondAddress, otherAccount } =
                await loadFixture(deployDiamondFixture);

            const ownershipFacet = await ethers.getContractAt(
                "OwnershipFacet",
                diamondAddress,
            );

            await ownershipFacet.transferOwnership(otherAccount.address);
            expect(await ownershipFacet.owner()).to.equal(otherAccount.address);
        });
    });

    describe("CounterFacet", function () {
        it("Should initialize counter to 0", async function () {
            const { diamondAddress } = await loadFixture(deployDiamondFixture);

            const counterFacet = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );
            expect(await counterFacet.getCount()).to.equal(0);
        });

        it("Should increment counter", async function () {
            const { diamondAddress } = await loadFixture(deployDiamondFixture);

            const counterFacet = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );

            await counterFacet.increment();
            expect(await counterFacet.getCount()).to.equal(1);

            await counterFacet.increment();
            expect(await counterFacet.getCount()).to.equal(2);
        });

        it("Should decrement counter", async function () {
            const { diamondAddress } = await loadFixture(deployDiamondFixture);

            const counterFacet = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );

            // First increment to avoid underflow
            await counterFacet.increment();
            await counterFacet.increment();
            expect(await counterFacet.getCount()).to.equal(2);

            await counterFacet.decrement();
            expect(await counterFacet.getCount()).to.equal(1);
        });

        it("Should set counter to specific value", async function () {
            const { diamondAddress } = await loadFixture(deployDiamondFixture);

            const counterFacet = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );

            await counterFacet.setCount(100);
            expect(await counterFacet.getCount()).to.equal(100);
        });
    });

    describe("ERC20Facet", function () {
        it("Should have correct token details", async function () {
            const { diamondAddress } = await loadFixture(deployDiamondFixture);

            const erc20Facet = await ethers.getContractAt(
                "ERC20Facet",
                diamondAddress,
            );

            expect(await erc20Facet.name()).to.equal("Diamond Token");
            expect(await erc20Facet.symbol()).to.equal("DMD");
            expect(await erc20Facet.decimals()).to.equal(18);
        });

        it("Should allow owner to mint tokens", async function () {
            const { diamondAddress, owner } =
                await loadFixture(deployDiamondFixture);

            const erc20Facet = await ethers.getContractAt(
                "ERC20Facet",
                diamondAddress,
            );

            const mintAmount = ethers.parseEther("1000");
            await erc20Facet.mint(owner.address, mintAmount);

            expect(await erc20Facet.balanceOf(owner.address)).to.equal(
                mintAmount,
            );
            expect(await erc20Facet.totalSupply()).to.equal(mintAmount);
        });

        it("Should allow transfers between accounts", async function () {
            const { diamondAddress, owner, otherAccount } =
                await loadFixture(deployDiamondFixture);

            const erc20Facet = await ethers.getContractAt(
                "ERC20Facet",
                diamondAddress,
            );

            // Mint tokens to owner
            const mintAmount = ethers.parseEther("1000");
            await erc20Facet.mint(owner.address, mintAmount);

            // Transfer to other account
            const transferAmount = ethers.parseEther("100");
            await erc20Facet.transfer(otherAccount.address, transferAmount);

            expect(await erc20Facet.balanceOf(owner.address)).to.equal(
                mintAmount - transferAmount,
            );
            expect(await erc20Facet.balanceOf(otherAccount.address)).to.equal(
                transferAmount,
            );
        });

        it("Should support approvals and transferFrom", async function () {
            const { diamondAddress, owner, otherAccount } =
                await loadFixture(deployDiamondFixture);

            const erc20Facet = (await ethers.getContractAt(
                "ERC20Facet",
                diamondAddress,
            )) as any;

            // Mint tokens to owner
            const mintAmount = ethers.parseEther("1000");
            await erc20Facet.mint(owner.address, mintAmount);

            // Approve other account to spend tokens
            const approvalAmount = ethers.parseEther("500");
            await erc20Facet.approve(otherAccount.address, approvalAmount);

            expect(
                await erc20Facet.allowance(owner.address, otherAccount.address),
            ).to.equal(approvalAmount);

            // Other account transfers from owner
            const transferAmount = ethers.parseEther("200");
            await erc20Facet
                .connect(otherAccount)
                .transferFrom(
                    owner.address,
                    otherAccount.address,
                    transferAmount,
                );

            expect(await erc20Facet.balanceOf(owner.address)).to.equal(
                mintAmount - transferAmount,
            );
            expect(await erc20Facet.balanceOf(otherAccount.address)).to.equal(
                transferAmount,
            );
            expect(
                await erc20Facet.allowance(owner.address, otherAccount.address),
            ).to.equal(approvalAmount - transferAmount);
        });

        it("Should allow token details to be updated", async function () {
            const { diamondAddress } = await loadFixture(deployDiamondFixture);

            const erc20Facet = await ethers.getContractAt(
                "ERC20Facet",
                diamondAddress,
            );

            await erc20Facet.setTokenDetails("Updated Token", "UTK", 8);

            expect(await erc20Facet.name()).to.equal("Updated Token");
            expect(await erc20Facet.symbol()).to.equal("UTK");
            expect(await erc20Facet.decimals()).to.equal(8);
        });
    });

    describe("Diamond Upgrades", function () {
        it("Should allow adding new functions", async function () {
            const { diamondAddress } = await loadFixture(deployDiamondFixture);

            // Deploy a new facet
            const NewFacet = await ethers.getContractFactory("CounterFacet");
            const newFacet = await NewFacet.deploy();
            await newFacet.waitForDeployment();

            // Get diamond cut facet
            const diamondCut = await ethers.getContractAt(
                "IDiamondCut",
                diamondAddress,
            );

            // Replace with the new facet
            const selectors = getSelectors(newFacet);
            const tx = await diamondCut.diamondCut(
                [
                    {
                        facetAddress: await newFacet.getAddress(),
                        action: FacetCutAction.Replace,
                        functionSelectors: selectors,
                    },
                ],
                ethers.ZeroAddress,
                "0x",
            );

            await tx.wait();

            // Verify the new facet is working
            const counterFacet = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );
            await counterFacet.setCount(42);
            expect(await counterFacet.getCount()).to.equal(42);
        });

        it("Should allow removing functions", async function () {
            const { diamondAddress } = await loadFixture(deployDiamondFixture);

            // Get all counter facet selectors
            const CounterFactory =
                await ethers.getContractFactory("CounterFacet");
            const counterImpl = await CounterFactory.deploy();
            await counterImpl.waitForDeployment();
            const counterSelectors = getSelectors(counterImpl);

            // Get diamond cut facet
            const diamondCut = await ethers.getContractAt(
                "IDiamondCut",
                diamondAddress,
            );

            // Remove the counter facet
            const tx = await diamondCut.diamondCut(
                [
                    {
                        facetAddress: ethers.ZeroAddress, // Zero address for removal
                        action: FacetCutAction.Remove,
                        functionSelectors: counterSelectors,
                    },
                ],
                ethers.ZeroAddress,
                "0x",
            );

            await tx.wait();

            // Verify the function is no longer available
            const counter = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );

            // This should revert since the function was removed
            await expect(counter.getCount()).to.be.reverted;
        });
    });
});
