import { ethers } from "hardhat";

async function main() {
    // 배포된 다이아몬드 주소
    const diamondAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

    // CounterFacet 인터페이스로 다이아몬드에 접근
    const counterFacet = await ethers.getContractAt(
        "CounterFacet",
        diamondAddress,
    );

    // 현재 카운터 값 조회
    const count = await counterFacet.getCount();
    console.log("Initial count:", count.toString());

    // 카운터 증가
    console.log("Incrementing counter...");
    const incrementTx = await counterFacet.increment();
    await incrementTx.wait();

    // 업데이트된 카운터 값 확인
    const newCount = await counterFacet.getCount();
    console.log("New count:", newCount.toString());

    // ERC20Facet 인터페이스로 다이아몬드에 접근
    const erc20Facet = await ethers.getContractAt("ERC20Facet", diamondAddress);

    // 토큰 이름, 심볼, 소수점 확인
    const name = await erc20Facet.name();
    const symbol = await erc20Facet.symbol();
    const decimals = await erc20Facet.decimals();

    console.log(`Token info: ${name} (${symbol}), decimals: ${decimals}`);

    // 토큰 민팅 (소유자만 가능)
    const [owner] = await ethers.getSigners();
    console.log(`Minting 1000 tokens to ${owner.address}...`);
    const mintTx = await erc20Facet.mint(
        owner.address,
        ethers.parseUnits("1000", decimals),
    );
    await mintTx.wait();

    // 잔액 확인
    const balance = await erc20Facet.balanceOf(owner.address);
    console.log(
        `Balance of ${owner.address}: ${ethers.formatUnits(balance, decimals)} ${symbol}`,
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
