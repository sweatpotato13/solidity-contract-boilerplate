import { expect } from "chai";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { FacetCutAction, getSelectors } from "../scripts/libraires/diamond";
import { Contract } from "ethers";

describe("Diamond Loupe Tests", function () {
    // Deploy diamond fixture
    async function deployDiamondFixture() {
        const [owner] = await ethers.getSigners();

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
        const facets: Contract[] = [];
        const cut = [];
        const facetContracts: Record<string, Contract> = {};

        for (const FacetName of FacetNames) {
            const Facet = await ethers.getContractFactory(FacetName);
            const facet = await Facet.deploy();
            await facet.waitForDeployment();
            facets.push(facet);
            facetContracts[FacetName] = facet;

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

        // Create a mapping of function selectors to facet addresses
        const selectorToFacetMap: Record<string, string> = {};
        for (const FacetName of FacetNames) {
            const facet = facetContracts[FacetName];
            const selectors = getSelectors(facet);

            for (const selector of selectors) {
                selectorToFacetMap[selector] = await facet.getAddress();
            }
        }

        // Get diamond loupe facet from diamond address
        const diamondLoupe = await ethers.getContractAt(
            "DiamondLoupeFacet",
            await diamond.getAddress(),
        );

        return {
            diamond,
            diamondCut,
            diamondLoupe,
            facets,
            facetContracts,
            selectorToFacetMap,
            owner,
            diamondAddress: await diamond.getAddress(),
        };
    }

    describe("facets", function () {
        it("should return all facet addresses and function selectors", async function () {
            const { diamondLoupe } = await loadFixture(deployDiamondFixture);

            const facets = await diamondLoupe.facets();

            // DiamondCutFacet + 4 other facets = 5
            expect(facets.length).to.equal(5);

            // Each facet should have a valid address and selectors
            for (const facet of facets) {
                expect(facet.facetAddress).to.not.equal(ethers.ZeroAddress);
                expect(facet.functionSelectors.length).to.be.greaterThan(0);
            }
        });
    });

    describe("facetFunctionSelectors", function () {
        it("should return function selectors for a facet address", async function () {
            const { diamondLoupe, facetContracts } =
                await loadFixture(deployDiamondFixture);

            // Test for each facet
            for (const [facetName, facetContract] of Object.entries(
                facetContracts,
            )) {
                const facetAddress = await facetContract.getAddress();
                const selectors =
                    await diamondLoupe.facetFunctionSelectors(facetAddress);

                // Verify number of selectors matches expected
                expect(selectors.length).to.be.greaterThan(0);

                // Get expected selectors
                const expectedSelectors = getSelectors(facetContract);

                // Verify selectors match expected
                expect(selectors.length).to.equal(expectedSelectors.length);

                // Verify each selector is included
                for (const selector of expectedSelectors) {
                    expect(selectors).to.include(selector);
                }
            }
        });

        it("should return empty array for non-existent facet address", async function () {
            const { diamondLoupe } = await loadFixture(deployDiamondFixture);

            // Use a non-existent facet address
            const nonExistentAddress =
                "0x0000000000000000000000000000000000000001";

            // Should return empty array, not revert
            const selectors =
                await diamondLoupe.facetFunctionSelectors(nonExistentAddress);
            expect(selectors.length).to.equal(0);
        });
    });

    describe("facetAddresses", function () {
        it("should return all facet addresses", async function () {
            const { diamondLoupe, facetContracts } =
                await loadFixture(deployDiamondFixture);

            const facetAddresses = await diamondLoupe.facetAddresses();

            // DiamondCutFacet + 4 other facets = 5
            expect(facetAddresses.length).to.equal(5);

            // Verify each deployed facet address is included
            for (const facetContract of Object.values(facetContracts)) {
                const facetAddress = await facetContract.getAddress();
                expect(facetAddresses).to.include(facetAddress);
            }
        });
    });

    describe("facetAddress", function () {
        it("should return the correct facet address for each function selector", async function () {
            const { diamondLoupe, selectorToFacetMap } =
                await loadFixture(deployDiamondFixture);

            // Test for each selector
            for (const [selector, expectedAddress] of Object.entries(
                selectorToFacetMap,
            )) {
                const facetAddress = await diamondLoupe.facetAddress(selector);
                expect(facetAddress).to.equal(expectedAddress);
            }
        });

        it("should return zero address for non-existent function selector", async function () {
            const { diamondLoupe } = await loadFixture(deployDiamondFixture);

            // Use a non-existent function selector
            const nonExistentSelector = "0x12345678";

            // Should return zero address, not revert
            const facetAddress =
                await diamondLoupe.facetAddress(nonExistentSelector);
            expect(facetAddress).to.equal(ethers.ZeroAddress);
        });
    });

    describe("supportsInterface", function () {
        it("should support ERC-165 interface", async function () {
            const { diamondLoupe } = await loadFixture(deployDiamondFixture);

            // ERC-165 interface ID
            const ERC165_INTERFACE_ID = "0x01ffc9a7";

            // Should support ERC-165
            expect(await diamondLoupe.supportsInterface(ERC165_INTERFACE_ID)).to
                .be.true;
        });

        it("should support IDiamondLoupe interface", async function () {
            const { diamondLoupe } = await loadFixture(deployDiamondFixture);

            // IDiamondLoupe interface ID
            const DIAMOND_LOUPE_INTERFACE_ID = "0x48e2b093";

            // Should support IDiamondLoupe
            expect(
                await diamondLoupe.supportsInterface(
                    DIAMOND_LOUPE_INTERFACE_ID,
                ),
            ).to.be.true;
        });

        it("should support IDiamondCut interface", async function () {
            const { diamondLoupe } = await loadFixture(deployDiamondFixture);

            // IDiamondCut interface ID
            const DIAMOND_CUT_INTERFACE_ID = "0x1f931c1c";

            // Should support IDiamondCut
            expect(
                await diamondLoupe.supportsInterface(DIAMOND_CUT_INTERFACE_ID),
            ).to.be.true;
        });
    });
});
