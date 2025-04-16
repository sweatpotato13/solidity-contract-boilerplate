import { ethers, network } from "hardhat";

const isFork = process.env.FORK_ENABLED === "true";

(isFork ? describe : describe.skip)("Forked test", function () {
    it("can impersonate an account", async function () {
        const targetAddress = "0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045"; // vitalik?

        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [targetAddress],
        });

        const signer = await ethers.getSigner(targetAddress);
        const balance = await ethers.provider.getBalance(targetAddress);
        console.log(balance);

        const tx = await signer.sendTransaction({
            to: "0x2f32E86e8fC5e762aa32a09d4970cB3216feFaf4",
            value: ethers.parseEther("1"),
        });
        await tx.wait();

        const newBalance = await ethers.provider.getBalance(
            "0x2f32E86e8fC5e762aa32a09d4970cB3216feFaf4",
        );
        console.log(newBalance);
    });
});
