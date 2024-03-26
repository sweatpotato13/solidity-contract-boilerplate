import { expect } from "chai";
import { ethers } from "hardhat";

import type { Storage } from "../typechain-types/Storage";

describe("Storage", function () {
    let storage: Storage;

    beforeEach(async () => {
        storage = (await (
            await ethers.getContractFactory("Storage")
        ).deploy()) as unknown as Storage;
    });

    it("test initial value", async function () {
        const address = await storage.getAddress();
        console.log("storage deployed at:" + address);
        expect(await storage.retrieve()).to.equal(0);
    });

    it("test updating and retrieving updated value", async function () {
        const address = await storage.getAddress();
        const storage2 = await ethers.getContractAt("Storage", address);
        const setValue = await storage2.store(56);
        await setValue.wait();
        expect(await storage2.retrieve()).to.equal(56);
    });
});
