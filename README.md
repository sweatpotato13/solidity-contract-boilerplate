# 🛠️ Solidity Contract Boilerplate

> A minimal, production-ready Solidity boilerplate featuring upgradeable smart contracts with the TransparentProxy pattern.

## 📋 Overview

This boilerplate provides a simple **Counter** example demonstrating:
- ✅ Upgradeable contracts using OpenZeppelin's TransparentUpgradeableProxy
- ✅ Separation of concerns (Storage, Logic, Lens)
- ✅ User-specific counters with global statistics
- ✅ Comprehensive test suite with upgrade testing
- ✅ Deployment and upgrade scripts

## 🏗️ Architecture

```
Counter System
├── Counter (Abstract)         - Main logic contract
├── CounterInstance           - Concrete implementation
├── CounterStorage            - Storage layout
├── CounterLens              - Gas-efficient read queries
└── CounterV2                - Example upgrade (adds decrement)
```

### Key Contracts

**Counter.sol** (Upgradeable)
- `increment()` - Increment caller's counter by 1
- Tracks total increments and unique users
- Owner-controlled via OwnableUpgradeable

**CounterLens.sol** (Non-upgradeable)
- `getCount()` - Get user's counter value
- `getUserStats()` - Get user statistics
- `getGlobalStats()` - Get global statistics
- `getCountBatch()` - Batch query multiple users

## 🚀 Quick Start

### Prerequisites

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone the repository
git clone <your-repo>
cd solidity-contract-boilerplate

# Install dependencies
forge install
```

### Build

```bash
forge build
```

### Test

```bash
# Run all tests
forge test

# Run with verbosity
forge test -vvv

# Run specific test file
forge test --match-path tests/Counter.t.sol

# Run with gas reporting
forge test --gas-report
```

### Deploy

```bash
# Local deployment (Anvil)
anvil

# In another terminal
forge script scripts/Deploy.s.sol:DeployTransparentScript --rpc-url http://localhost:8545 --broadcast --private-key <PRIVATE_KEY>

# Deploy to testnet (e.g., Sepolia)
forge script scripts/Deploy.s.sol:DeployTransparentScript --rpc-url $ETH_SEPOLIA_RPC_URL --broadcast --verify
```

### Upgrade

```bash
# Upgrade Counter implementation
forge script scripts/UpgradeCounter.s.sol:UpgradeCounterScript --rpc-url <RPC_URL> --broadcast
```

## 📁 Project Structure

```
├── src/
│   ├── Counter.sol              # Main upgradeable contract
│   ├── CounterInstance.sol      # Concrete implementation
│   ├── CounterStorage.sol       # Storage layout
│   ├── CounterLens.sol          # Read-only queries
│   ├── CounterV2.sol            # Example upgrade
│   ├── CounterInstanceV2.sol    # V2 implementation
│   ├── interfaces/
│   │   ├── ICounter.sol         # Counter interface
│   │   └── ICounterLens.sol     # Lens interface
│   └── mocks/
│       └── MockUSDC.sol         # Mock ERC20 for testing
├── scripts/
│   ├── Deploy.s.sol             # Deployment script
│   └── UpgradeCounter.s.sol     # Upgrade script
├── tests/
│   ├── Counter.t.sol            # Counter tests
│   ├── CounterLens.t.sol        # Lens tests
│   └── CounterUpgrade.t.sol     # Upgrade tests
├── foundry.toml                 # Foundry configuration
└── README.md
```

## 🧪 Test Coverage

- **Counter.t.sol**: Basic functionality, events, multi-user scenarios
- **CounterLens.t.sol**: All read functions, batch queries, integration tests
- **CounterUpgrade.t.sol**: State preservation, new functionality, downgrade scenarios

```bash
# Generate coverage report
forge coverage
```

## 🔄 Upgrade Pattern

This boilerplate demonstrates the **TransparentProxy** upgrade pattern:

1. **Initial Deployment**: Deploy implementation → Deploy proxy → Initialize
2. **Upgrade**: Deploy new implementation → Call `upgradeAndCall()`
3. **State Preservation**: All storage variables remain intact

### Example: V1 → V2 Upgrade

**V1 Features:**
- `increment()` - Increment counter

**V2 Features (Added):**
- `decrementBy(uint256)` - Decrement counter by amount
- `version()` - Returns version string

See `tests/CounterUpgrade.t.sol` for complete upgrade testing examples.

## 📊 Gas Optimization

The boilerplate follows gas optimization best practices:
- ✅ Packed storage slots (CounterStorage)
- ✅ Separate read contract (Lens) to reduce proxy overhead
- ✅ Efficient mappings for user data
- ✅ Events for off-chain indexing

## 🔐 Security Features

- ✅ OpenZeppelin battle-tested contracts
- ✅ Initializer protection with `_disableInitializers()`
- ✅ Owner-only upgrade mechanism via ProxyAdmin
- ✅ Comprehensive test coverage
- ✅ Storage gap for future upgrades

## 🛠️ Customization

### Replace Counter with Your Logic

1. Modify `src/Counter.sol` with your business logic
2. Update `src/CounterStorage.sol` with your state variables
3. Adjust `src/CounterLens.sol` for your read queries
4. Update tests and interfaces accordingly

### Key Principles to Maintain

- Keep storage layout in separate contract
- Maintain storage gap for future upgrades
- Use abstract/concrete pattern for implementation
- Separate write (upgradeable) and read (non-upgradeable) contracts

## 📝 Environment Variables

Create a `.env` file:

```bash
PRIVATE_KEY=your_private_key
ETH_SEPOLIA_RPC_URL=your_sepolia_rpc
ETH_SEPOLIA_SCAN_API_KEY=your_etherscan_api
```

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:
1. Fork the repository
2. Create a feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## 📄 License

MIT License - see LICENSE file for details

## 🔗 Resources

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Upgradeable Contracts](https://docs.openzeppelin.com/upgrades-plugins/1.x/)
- [Solidity Documentation](https://docs.soliditylang.org/)
- [EIP-1967: Proxy Storage Slots](https://eips.ethereum.org/EIPS/eip-1967)

## 📧 Support

For questions and support, please open an issue in the GitHub repository.

---

Built with ❤️ using [Foundry](https://getfoundry.sh/)
