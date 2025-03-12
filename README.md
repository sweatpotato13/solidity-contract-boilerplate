# 🛠️ solidity-contract-boilerplate

> **TLDR;** pre-configured hardhat project to run, debug, test and deploy your next solidity smart contract.
>
> This project should be your personal and always reliable swiss knife available in your pocket when you need to create a new Solidity project to be released on the Ethereum Blockchain.

## What is inside?

- Example of well-made Solidity Contract
- Example of a well-made test suite for your Solidity Contract
- Pre-configured Hardhat project
- Automatically generate TypeScript bindings

## Hardhat plugins included

- [hardhat-ethers](https://hardhat.org/plugins/nomiclabs-hardhat-ethers.html): injects `ethers.js` into the Hardhat Runtime Environment
- [hardhat-waffle](https://hardhat.org/plugins/nomiclabs-hardhat-waffle.html): adds a Waffle-compatible provider to the Hardhat Runtime Environment and automatically initializes the Waffle Chai matchers
- [TypeChain](https://hardhat.org/plugins/typechain-hardhat.html): automatically generate TypeScript bindings for smartcontracts
- [hardhat-solhint](https://hardhat.org/plugins/nomiclabs-hardhat-solhint.html): easily run solhint to lint your Solidity code
- [hardhat-etherscan](https://hardhat.org/plugins/nomiclabs-hardhat-etherscan.html): automatically verify contracts on Etherscan

## How to use it

1.  Click the "Use this template" green button
2.  `pnpm install`
3.  Modify the contract/test case
4.  Run the contract locally with `pnpm node` and `pnpm deploy:local` (deploy to local hardhat network)
5.  Test the contract with `pnpm test`
6.  Change `.env.example` into `.env` and configure it
7.  Deploy your contract where you want!

## Diamond Upgrade Guide

This guide demonstrates the upgrade process using the Diamond pattern. It explains two types of upgrades:

1. **Facet Upgrade**: Replacing an existing facet with a new version that extends functionality
2. **Storage Upgrade**: Extending storage structure while maintaining backward compatibility

### Local Development Setup

1. Run the local hardhat node:

```bash
npx hardhat node
```

2. Deploy the diamond and initial CounterFacet:

```bash
npx hardhat run scripts/deployDiamond.ts --network localhost
```

### Execute Facet Upgrade (CounterFacet → CounterFacetV2)

CounterFacetV2 adds the following features:

- Events emitted for counter operations
- Double increment (doubleIncrement) functionality
- Multiple checking (isMultipleOf) functionality

```bash
npx hardhat run scripts/upgradeCounterFacet.ts --network localhost
```

### Storage Upgrade (CounterFacetV2 → CounterFacetV3)

CounterFacetV3 with extended storage structure (LibCounterV2) adds the following new states:

- Last increment/decrement timestamp tracking
- Total increment/decrement count tracking
- Last modifier address tracking

```bash
npx hardhat run scripts/upgradeCounterStorage.ts --network localhost
```

### Upgrade Process Explanation

#### Facet Upgrade Process

1. Deploy new CounterFacetV2 contract
2. Remove function selectors from existing CounterFacet
3. Add function selectors from new CounterFacetV2

#### Storage Upgrade Process

1. Implement new library (LibCounterV2) with extended storage structure
2. Implement CounterFacetV3 using this library
3. Remove function selectors from existing CounterFacetV2
4. Add function selectors from new CounterFacetV3
5. Execute storage migration function (initializeV3)

## Compile

```bash
npx hardhat compile
```

## Test

```bash
npx hardhat test
```

## Mainnet Deployment

```bash
npx hardhat run scripts/deployDiamond.ts --network mainnet
```

## License

MIT
