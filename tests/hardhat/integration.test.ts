import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

import { FacetCutAction, getSelectors } from "../../scripts/libraries/diamond";

describe("Diamond Integration Tests", function () {
    // Deploy diamond fixture
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
        const ownershipFacet = await ethers.getContractAt(
            "OwnershipFacet",
            diamondAddress,
        );
        const diamondLoupeFacet = await ethers.getContractAt(
            "DiamondLoupeFacet",
            diamondAddress,
        );

        return {
            diamond,
            diamondCutFacet,
            facets,
            counterFacet,
            erc20Facet,
            ownershipFacet,
            diamondLoupeFacet,
            owner,
            user1,
            user2,
            diamondAddress,
        };
    }

    it("Should correctly track separate state for all facets", async function () {
        const { counterFacet, erc20Facet, owner, user1 } =
            await loadFixture(deployDiamondFixture);

        // Test initial states
        expect(await counterFacet.getCount()).to.equal(0);
        expect(await erc20Facet.name()).to.equal("Diamond Token");
        expect(await erc20Facet.totalSupply()).to.equal(0);

        // Modify states
        await counterFacet.increment();
        await erc20Facet.mint(owner.address, ethers.parseEther("100"));

        // Verify states updated correctly
        expect(await counterFacet.getCount()).to.equal(1);
        expect(await erc20Facet.balanceOf(owner.address)).to.equal(
            ethers.parseEther("100"),
        );

        // Modify more
        await counterFacet.setCount(50);
        await erc20Facet.transfer(user1.address, ethers.parseEther("30"));

        // Verify all states correctly track changes
        expect(await counterFacet.getCount()).to.equal(50);
        expect(await erc20Facet.balanceOf(owner.address)).to.equal(
            ethers.parseEther("70"),
        );
        expect(await erc20Facet.balanceOf(user1.address)).to.equal(
            ethers.parseEther("30"),
        );
    });

    it("Should maintain state when upgrading facets", async function () {
        const { diamondAddress, counterFacet, erc20Facet, owner, user1 } =
            await loadFixture(deployDiamondFixture);

        // Setup initial state
        await counterFacet.setCount(100);
        await erc20Facet.mint(owner.address, ethers.parseEther("500"));
        await erc20Facet.transfer(user1.address, ethers.parseEther("200"));

        // Deploy new version of counter facet
        const CounterFacetV2 = await ethers.getContractFactory("CounterFacet");
        const counterFacetV2 = await CounterFacetV2.deploy();
        await counterFacetV2.waitForDeployment();

        // Upgrade diamond
        const diamondCut = await ethers.getContractAt(
            "IDiamondCut",
            diamondAddress,
        );

        // Replace the counter facet
        const tx = await diamondCut.diamondCut(
            [
                {
                    facetAddress: await counterFacetV2.getAddress(),
                    action: FacetCutAction.Replace,
                    functionSelectors: getSelectors(counterFacetV2),
                },
            ],
            ethers.ZeroAddress,
            "0x",
        );

        await tx.wait();

        // Get updated contract instances
        const updatedCounterFacet = await ethers.getContractAt(
            "CounterFacet",
            diamondAddress,
        );
        const updatedERC20Facet = await ethers.getContractAt(
            "ERC20Facet",
            diamondAddress,
        );

        // Verify state was maintained
        expect(await updatedCounterFacet.getCount()).to.equal(100);
        expect(await updatedERC20Facet.balanceOf(owner.address)).to.equal(
            ethers.parseEther("300"),
        );
        expect(await updatedERC20Facet.balanceOf(user1.address)).to.equal(
            ethers.parseEther("200"),
        );

        // Verify new functionality still works
        await updatedCounterFacet.increment();
        expect(await updatedCounterFacet.getCount()).to.equal(101);
    });

    it("Should handle complex interactions between facets", async function () {
        const { counterFacet, erc20Facet, owner, user1, user2 } =
            await loadFixture(deployDiamondFixture);

        // Setup initial states
        await counterFacet.setCount(10);
        await erc20Facet.mint(owner.address, ethers.parseEther("1000"));

        // Series of interleaved operations
        // 1. Transfer tokens to user1
        await erc20Facet.transfer(user1.address, ethers.parseEther("400"));
        // 2. Increment counter
        await counterFacet.increment();
        // 3. User1 transfers to user2
        await erc20Facet
            .connect(user1)
            .transfer(user2.address, ethers.parseEther("150"));
        // 4. Decrement counter
        await counterFacet.decrement();
        // 5. Mint more tokens
        await erc20Facet.mint(owner.address, ethers.parseEther("200"));

        // Verify final states
        expect(await counterFacet.getCount()).to.equal(10); // 10 -> 11 -> 10
        expect(await erc20Facet.balanceOf(owner.address)).to.equal(
            ethers.parseEther("800"),
        ); // 1000 - 400 + 200
        expect(await erc20Facet.balanceOf(user1.address)).to.equal(
            ethers.parseEther("250"),
        ); // 400 - 150
        expect(await erc20Facet.balanceOf(user2.address)).to.equal(
            ethers.parseEther("150"),
        );
        expect(await erc20Facet.totalSupply()).to.equal(
            ethers.parseEther("1200"),
        ); // 1000 + 200
    });

    it("Should properly handle access control across facets", async function () {
        const { erc20Facet, ownershipFacet, owner, user1 } =
            await loadFixture(deployDiamondFixture);

        // Only owner can mint
        await erc20Facet.mint(owner.address, ethers.parseEther("100"));
        await expect(
            erc20Facet
                .connect(user1)
                .mint(user1.address, ethers.parseEther("100")),
        ).to.be.reverted;

        // Transfer ownership
        await ownershipFacet.transferOwnership(user1.address);

        // Now user1 is owner and can mint
        await erc20Facet
            .connect(user1)
            .mint(user1.address, ethers.parseEther("100"));

        // Original owner can no longer mint
        await expect(erc20Facet.mint(owner.address, ethers.parseEther("100")))
            .to.be.reverted;

        // Verify balances
        expect(await erc20Facet.balanceOf(owner.address)).to.equal(
            ethers.parseEther("100"),
        );
        expect(await erc20Facet.balanceOf(user1.address)).to.equal(
            ethers.parseEther("100"),
        );
    });

    it("Should support Diamond Loupe functions", async function () {
        const { diamondLoupeFacet } = await loadFixture(deployDiamondFixture);

        // Get all facet addresses
        const facetAddresses = await diamondLoupeFacet.facetAddresses();

        // Should have 5 facets (DiamondCutFacet + our 4 added facets)
        expect(facetAddresses.length).to.equal(5);

        // Get all facets with their function selectors
        const facets = await diamondLoupeFacet.facets();
        expect(facets.length).to.equal(5);

        // Get facet for a specific function selector
        // ERC20 transfer function selector
        const transferSelector = "0xa9059cbb"; // transfer(address,uint256)
        const facetAddress =
            await diamondLoupeFacet.facetAddress(transferSelector);

        // Verify the ERC20 functions are correctly registered
        const erc20Selectors =
            await diamondLoupeFacet.facetFunctionSelectors(facetAddress);
        expect(erc20Selectors.includes(transferSelector)).to.equal(true);
    });
});
