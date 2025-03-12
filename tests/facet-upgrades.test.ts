import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "../scripts/libraries/diamond";

describe("Diamond Facet Upgrades Tests", function () {
    // Deploy diamond fixture with initial facets
    async function deployDiamondFixture() {
        const [owner, user1, user2] = await ethers.getSigners();

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

        // Deploy initial facets
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

        // Cut diamond with facets
        const diamondCut = await ethers.getContractAt(
            "IDiamondCut",
            await diamond.getAddress(),
        );

        // Call to init function
        const functionCall = diamondInit.interface.encodeFunctionData("init");
        const tx = await diamondCut.diamondCut(
            cut,
            await diamondInit.getAddress(),
            functionCall,
        );
        await tx.wait();

        return {
            diamond,
            diamondCut,
            diamondCutFacet,
            diamondInit,
            facets,
            owner,
            user1,
            user2,
        };
    }

    // Test suite for upgrading a facet
    describe("Facet Upgrades", function () {
        it("Should upgrade from CounterFacet to CounterFacetV2", async function () {
            const { diamond, diamondCut } =
                await loadFixture(deployDiamondFixture);
            const diamondAddress = await diamond.getAddress();

            // Get the current counter value
            const counterFacet = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );
            await counterFacet.increment();
            await counterFacet.increment();
            const initialCount = await counterFacet.getCount();
            expect(initialCount).to.equal(2);

            // Deploy CounterFacetV2
            const CounterFacetV2 =
                await ethers.getContractFactory("CounterFacetV2");
            const counterFacetV2 = await CounterFacetV2.deploy();
            await counterFacetV2.waitForDeployment();

            // Get selectors to remove from original facet
            const selectorsToRemove = getSelectors(counterFacet);

            // Get selectors to add from the new facet
            const selectorsToAdd = getSelectors(counterFacetV2);

            // Remove old selectors
            const cutRemove = {
                facetAddress: ethers.ZeroAddress,
                action: FacetCutAction.Remove,
                functionSelectors: selectorsToRemove,
            };

            const txRemove = await diamondCut.diamondCut(
                [cutRemove],
                ethers.ZeroAddress,
                "0x",
            );
            await txRemove.wait();

            // Add new selectors
            const cutAdd = {
                facetAddress: await counterFacetV2.getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: selectorsToAdd,
            };

            const txAdd = await diamondCut.diamondCut(
                [cutAdd],
                ethers.ZeroAddress,
                "0x",
            );
            await txAdd.wait();

            // Test new functionality in V2
            const counterFacetV2OnDiamond = await ethers.getContractAt(
                "CounterFacetV2",
                diamondAddress,
            );
            const countV2 = await counterFacetV2OnDiamond.getCount();

            // Counter value should be preserved from V1
            expect(countV2).to.equal(initialCount);

            // Test new function from V2
            const isMultipleOf2 = await counterFacetV2OnDiamond.isMultipleOf(2);
            expect(isMultipleOf2).to.equal(true);

            const isMultipleOf3 = await counterFacetV2OnDiamond.isMultipleOf(3);
            expect(isMultipleOf3).to.equal(false);

            // Double the counter with doubleIncrement V2 function
            await counterFacetV2OnDiamond.doubleIncrement();
            const doubledCount = await counterFacetV2OnDiamond.getCount();
            expect(doubledCount).to.equal(Number(initialCount) + 2);
        });

        it("Should upgrade to CounterFacetV3 with storage layout changes", async function () {
            const { diamond, diamondCut } =
                await loadFixture(deployDiamondFixture);
            const diamondAddress = await diamond.getAddress();

            // First upgrade to CounterFacetV2
            const counterFacet = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );
            await counterFacet.increment();
            await counterFacet.increment();
            await counterFacet.increment();
            const initialCount = await counterFacet.getCount();
            expect(initialCount).to.equal(3);

            // Deploy CounterFacetV2
            const CounterFacetV2 =
                await ethers.getContractFactory("CounterFacetV2");
            const counterFacetV2 = await CounterFacetV2.deploy();
            await counterFacetV2.waitForDeployment();

            // First remove V1
            const cutRemoveV1 = {
                facetAddress: ethers.ZeroAddress,
                action: FacetCutAction.Remove,
                functionSelectors: getSelectors(counterFacet),
            };

            await (
                await diamondCut.diamondCut(
                    [cutRemoveV1],
                    ethers.ZeroAddress,
                    "0x",
                )
            ).wait();

            // Add V2
            const cutAddV2 = {
                facetAddress: await counterFacetV2.getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(counterFacetV2),
            };

            await (
                await diamondCut.diamondCut(
                    [cutAddV2],
                    ethers.ZeroAddress,
                    "0x",
                )
            ).wait();

            // Now deploy V3 which has completely different storage layout
            const CounterFacetV3 =
                await ethers.getContractFactory("CounterFacetV3");
            const counterFacetV3 = await CounterFacetV3.deploy();
            await counterFacetV3.waitForDeployment();

            // Connect V2 interface to perform migration first
            const counterV2 = await ethers.getContractAt(
                "CounterFacetV2",
                diamondAddress,
            );
            const v2Count = await counterV2.getCount();
            expect(v2Count).to.equal(initialCount);

            // Remove V2
            const cutRemoveV2 = {
                facetAddress: ethers.ZeroAddress,
                action: FacetCutAction.Remove,
                functionSelectors: getSelectors(counterV2),
            };

            await (
                await diamondCut.diamondCut(
                    [cutRemoveV2],
                    ethers.ZeroAddress,
                    "0x",
                )
            ).wait();

            // Add V3
            const cutAddV3 = {
                facetAddress: await counterFacetV3.getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(counterFacetV3),
            };

            await (
                await diamondCut.diamondCut(
                    [cutAddV3],
                    ethers.ZeroAddress,
                    "0x",
                )
            ).wait();

            // Call initialization/migration function on V3 to copy data from old storage to new
            const counterV3 = await ethers.getContractAt(
                "CounterFacetV3",
                diamondAddress,
            );
            await counterV3.initializeV3();

            // Test V3 functionality and events
            // Let's increment and see what the count is (should be incremented by 3 in V3)
            await counterV3.increment();

            // V3 increment adds 3 to the count
            const incrementedCount = await counterV3.getCount();
            expect(incrementedCount).to.equal(Number(v2Count) + 3);
        });
    });

    // Test suite for adding a new facet
    describe("Adding New Facets", function () {
        it("Should add CalculatorFacet and use its functions", async function () {
            const { diamond, diamondCut, owner } =
                await loadFixture(deployDiamondFixture);
            const diamondAddress = await diamond.getAddress();

            // Deploy CalculatorFacet
            const CalculatorFacet =
                await ethers.getContractFactory("CalculatorFacet");
            const calculatorFacet = await CalculatorFacet.deploy();
            await calculatorFacet.waitForDeployment();

            // Add CalculatorFacet to diamond
            const cut = {
                facetAddress: await calculatorFacet.getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: getSelectors(calculatorFacet),
            };

            await (
                await diamondCut.diamondCut([cut], ethers.ZeroAddress, "0x")
            ).wait();

            // Get calculator interface
            const calculator = await ethers.getContractAt(
                "CalculatorFacet",
                diamondAddress,
            );

            // Initial value should be 0
            const initialValue = await calculator.getResult();
            expect(initialValue).to.equal(0);

            // Set value to 10 (only owner can do this)
            await (calculator as any).connect(owner).setValue(10);

            // Test basic arithmetic
            await calculator.add(5);
            let result = await calculator.getResult();
            expect(result).to.equal(15);

            await calculator.subtract(3);
            result = await calculator.getResult();
            expect(result).to.equal(12);

            await calculator.multiply(2);
            result = await calculator.getResult();
            expect(result).to.equal(24);

            await calculator.divide(4);
            result = await calculator.getResult();
            expect(result).to.equal(6);

            // Check operation count
            const opCount = await calculator.getOperationCount();
            expect(opCount).to.equal(4);

            // Check last operator
            const lastOperator = await calculator.getLastOperator();
            expect(lastOperator).to.equal(owner.address);

            // Reset calculator
            await calculator.reset();
            result = await calculator.getResult();
            expect(result).to.equal(0);
        });

        it("Should handle multiple facet additions and removals", async function () {
            const { diamond, diamondCut } =
                await loadFixture(deployDiamondFixture);
            const diamondAddress = await diamond.getAddress();

            // Get DiamondLoupeFacet interface for inspection
            const loupe = await ethers.getContractAt(
                "DiamondLoupeFacet",
                diamondAddress,
            );

            // First get the original number of facets
            const originalFacets = await loupe.facetAddresses();
            const originalFacetCount = originalFacets.length;

            // Add CalculatorFacet
            const CalculatorFacet =
                await ethers.getContractFactory("CalculatorFacet");
            const calculatorFacet = await CalculatorFacet.deploy();
            await calculatorFacet.waitForDeployment();

            // Get selectors for Calculator
            const calculatorSelectors = getSelectors(calculatorFacet);

            // Add CalculatorFacet to diamond
            const addCut = {
                facetAddress: await calculatorFacet.getAddress(),
                action: FacetCutAction.Add,
                functionSelectors: calculatorSelectors,
            };

            await (
                await diamondCut.diamondCut([addCut], ethers.ZeroAddress, "0x")
            ).wait();

            // Verify facet was added
            const withCalculatorFacets = await loupe.facetAddresses();
            expect(withCalculatorFacets.length).to.equal(
                originalFacetCount + 1,
            );

            // Remove CalculatorFacet
            const removeCut = {
                facetAddress: ethers.ZeroAddress,
                action: FacetCutAction.Remove,
                functionSelectors: calculatorSelectors,
            };

            await (
                await diamondCut.diamondCut(
                    [removeCut],
                    ethers.ZeroAddress,
                    "0x",
                )
            ).wait();

            // Verify facet was removed
            const afterRemovalFacets = await loupe.facetAddresses();
            expect(afterRemovalFacets.length).to.equal(originalFacetCount);

            // Verify the selectors are gone
            for (const selector of calculatorSelectors) {
                const facetAddress = await loupe.facetAddress(selector);
                expect(facetAddress).to.equal(ethers.ZeroAddress);
            }
        });
    });

    // Test suite for replacing functionality
    describe("Replacing Functionality", function () {
        it("Should replace a single function in a facet", async function () {
            const { diamond, diamondCut } =
                await loadFixture(deployDiamondFixture);
            const diamondAddress = await diamond.getAddress();

            // Get current Counter interface
            const counter = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );

            // Set up initial state
            await counter.increment();
            await counter.increment();
            const initialCount = await counter.getCount();
            expect(initialCount).to.equal(2);

            // Deploy a modified Counter that will replace just the increment function
            // For testing purposes, we'll use CounterFacetV2 but only replace increment
            const CounterFacetV2 =
                await ethers.getContractFactory("CounterFacetV2");
            const counterV2 = await CounterFacetV2.deploy();
            await counterV2.waitForDeployment();

            // Get the increment function selector from V2
            const incrementFunctionSignature = "increment()";
            const incrementSelector = counterV2.interface.getFunction(
                incrementFunctionSignature,
            ).selector;

            // Replace just the increment function
            const replaceCut = {
                facetAddress: await counterV2.getAddress(),
                action: FacetCutAction.Replace,
                functionSelectors: [incrementSelector],
            };

            await (
                await diamondCut.diamondCut(
                    [replaceCut],
                    ethers.ZeroAddress,
                    "0x",
                )
            ).wait();

            // Now when we call increment, it should increment by 2 (V2 behavior) instead of by 1
            await counter.increment();

            // CounterFacetV2's increment adds 2 instead of 1
            const newCount = await counter.getCount();
            expect(newCount).to.equal(Number(initialCount) + 2);
        });

        it("Should handle diamond cuts with multiple operations", async function () {
            const { diamond, diamondCut } =
                await loadFixture(deployDiamondFixture);
            const diamondAddress = await diamond.getAddress();

            // Deploy CalculatorFacet
            const CalculatorFacet =
                await ethers.getContractFactory("CalculatorFacet");
            const calculatorFacet = await CalculatorFacet.deploy();
            await calculatorFacet.waitForDeployment();

            // Deploy CounterFacetV2
            const CounterFacetV2 =
                await ethers.getContractFactory("CounterFacetV2");
            const counterV2 = await CounterFacetV2.deploy();
            await counterV2.waitForDeployment();

            // Get the existing Counter interface
            const counter = await ethers.getContractAt(
                "CounterFacet",
                diamondAddress,
            );

            // Get calculator selectors
            const calculatorSelectors = getSelectors(calculatorFacet);

            // Get counter selectors to remove
            const counterSelectors = getSelectors(counter);

            // Get CounterV2 selectors to add
            const counterV2Selectors = getSelectors(counterV2);

            // Prepare multi-operation cut
            const cuts = [
                // Remove existing counter
                {
                    facetAddress: ethers.ZeroAddress,
                    action: FacetCutAction.Remove,
                    functionSelectors: counterSelectors,
                },
                // Add CounterV2
                {
                    facetAddress: await counterV2.getAddress(),
                    action: FacetCutAction.Add,
                    functionSelectors: counterV2Selectors,
                },
                // Add Calculator
                {
                    facetAddress: await calculatorFacet.getAddress(),
                    action: FacetCutAction.Add,
                    functionSelectors: calculatorSelectors,
                },
            ];

            // Execute multi-operation cut
            await (
                await diamondCut.diamondCut(cuts, ethers.ZeroAddress, "0x")
            ).wait();

            // Verify all operations were successful
            // 1. CounterV2 is working
            const counterV2OnDiamond = await ethers.getContractAt(
                "CounterFacetV2",
                diamondAddress,
            );
            await counterV2OnDiamond.increment();
            const count = await counterV2OnDiamond.getCount();
            expect(count).to.equal(2); // CounterFacetV2's increment adds 2

            // 2. Calculator is working
            const calculatorOnDiamond = await ethers.getContractAt(
                "CalculatorFacet",
                diamondAddress,
            );
            await calculatorOnDiamond.add(10);
            const result = await calculatorOnDiamond.getResult();
            expect(result).to.equal(10);

            // 3. Old Counter interface is not accessible
            const loupe = await ethers.getContractAt(
                "DiamondLoupeFacet",
                diamondAddress,
            );
            const incrementFunctionSignature = "increment()";
            const incrementSelector = counter.interface.getFunction(
                incrementFunctionSignature,
            ).selector;
            const facetAddressForIncrement =
                await loupe.facetAddress(incrementSelector);

            // It should now point to CounterFacetV2's address, not the original
            expect(facetAddressForIncrement).to.equal(
                await counterV2.getAddress(),
            );
        });
    });
});
