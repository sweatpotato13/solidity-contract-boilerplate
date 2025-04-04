import { ethers } from "hardhat";

async function main() {
    // 배포된 다이아몬드 주소
    const diamondAddress = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";

    // 네트워크의 provider와 signer 가져오기
    const provider = ethers.provider;
    const [signer] = await ethers.getSigners();
    
    // CounterFacet ABI 가져오기
    const CounterFacet = await ethers.getContractFactory("CounterFacet");
    const counterInterface = CounterFacet.interface;
    
    // 현재 카운터 값 조회 - provider를 통해 호출
    const countData = counterInterface.encodeFunctionData("getCount");
    const countResult = await provider.call({
        to: diamondAddress,
        data: countData
    });
    const count = counterInterface.decodeFunctionResult("getCount", countResult)[0];
    console.log("Initial count:", count.toString());

    // 카운터 증가 - signer를 통해 트랜잭션 전송
    console.log("Incrementing counter...");
    const incrementData = counterInterface.encodeFunctionData("increment");
    const incrementTx = await signer.sendTransaction({
        to: diamondAddress,
        data: incrementData
    });
    await incrementTx.wait();

    // 업데이트된 카운터 값 확인
    const newCountResult = await provider.call({
        to: diamondAddress,
        data: countData
    });
    const newCount = counterInterface.decodeFunctionResult("getCount", newCountResult)[0];
    console.log("New count:", newCount.toString());

    // ERC20Facet ABI 가져오기
    const ERC20Facet = await ethers.getContractFactory("ERC20Facet");
    const erc20Interface = ERC20Facet.interface;

    // 토큰 정보 조회
    const nameData = erc20Interface.encodeFunctionData("name");
    const nameResult = await provider.call({
        to: diamondAddress,
        data: nameData
    });
    const name = erc20Interface.decodeFunctionResult("name", nameResult)[0];

    const symbolData = erc20Interface.encodeFunctionData("symbol");
    const symbolResult = await provider.call({
        to: diamondAddress,
        data: symbolData
    });
    const symbol = erc20Interface.decodeFunctionResult("symbol", symbolResult)[0];

    const decimalsData = erc20Interface.encodeFunctionData("decimals");
    const decimalsResult = await provider.call({
        to: diamondAddress,
        data: decimalsData
    });
    const decimals = erc20Interface.decodeFunctionResult("decimals", decimalsResult)[0];

    console.log(`토큰 정보: ${name} (${symbol}), 소수점: ${decimals}`);

    // 토큰 민팅 (소유자만 가능)
    console.log(`${signer.address}에 1000 토큰 민팅 중...`);
    
    const mintData = erc20Interface.encodeFunctionData("mint", [
        signer.address,
        ethers.parseUnits("1000", decimals)
    ]);
    
    const mintTx = await signer.sendTransaction({
        to: diamondAddress,
        data: mintData
    });
    await mintTx.wait();

    // 잔액 확인
    const balanceOfData = erc20Interface.encodeFunctionData("balanceOf", [signer.address]);
    const balanceResult = await provider.call({
        to: diamondAddress,
        data: balanceOfData
    });
    const balance = erc20Interface.decodeFunctionResult("balanceOf", balanceResult)[0];
    
    console.log(
        `${signer.address}의 잔액: ${ethers.formatUnits(balance, decimals)} ${symbol}`
    );
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });