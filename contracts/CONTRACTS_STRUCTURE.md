# 📁 Smart Contracts Directory Structure & Setup

Complete file structure for CroGas smart contracts repository.

---

## 📂 Full Directory Layout

```
CroGas/
│
├── 📁 contracts/                         # Solidity smart contracts
│   ├── CroGasRelay.sol                  # Main relay contract ⭐
│   ├── MockUSDC.sol                     # Test USDC token
│   └── TestTarget.sol                   # Test target contract
│
├── 📁 scripts/                           # Deployment & testing scripts
│   ├── deploy.js                        # Deploy to Cronos testnet
│   ├── deploy-mainnet.js                # Deploy to Cronos mainnet
│   ├── test-transactions.js             # Test transaction execution
│   └── verify-contracts.js              # Verify on block explorer
│
├── 📁 test/                              # Test files
│   ├── CroGasRelay.test.js             # Relay contract tests
│   ├── MockUSDC.test.js                # Token tests
│   ├── TestTarget.test.js              # Target contract tests
│   └── fixtures/                        # Test fixtures
│       └── contracts.js                 # Contract deployment fixtures
│
├── 📁 artifacts/                         # Compiled contracts (generated)
│   ├── CroGasRelay.json
│   ├── MockUSDC.json
│   └── TestTarget.json
│
├── 📁 docs/                              # Documentation
│   ├── CONTRACTS_DEPLOYMENT.md          # Full deployment guide
│   ├── CONTRACTS_README.md              # Contract reference
│   ├── CONTRACTS_SUMMARY.md             # Summary & overview
│   ├── SECURITY_AUDIT.md                # Security audit results
│   └── GAS_OPTIMIZATION.md              # Gas optimization notes
│
├── 🔧 hardhat.config.js                 # Hardhat configuration
├── 📝 package.json                      # Dependencies
├── 🔐 .env.example                      # Environment template
├── 📖 README.md                         # Project README
├── 📄 LICENSE                           # MIT License
└── 🙈 .gitignore                        # Git ignore rules
```

---

## 📋 File Descriptions

### Contracts (3 files)

#### **contracts/CroGasRelay.sol** (250 LOC)
```solidity
// Core meta-transaction relay contract
// - Execute transactions on behalf of users
// - Collect USDC fees
// - Manage nonces for replay protection
// - Admin controls
```
✅ Production-ready  
🔐 High security  
⚡ Optimized gas

#### **contracts/MockUSDC.sol** (35 LOC)
```solidity
// Test USDC token for Cronos testnet
// - ERC20 implementation
// - Permit support (EIP-712)
// - Mint & faucet functions
```
⚠️ Testnet only  
🧪 For testing  

#### **contracts/TestTarget.sol** (85 LOC)
```solidity
// Simple test contract for relay testing
// - Counter, value storage
// - Multiple function types
// - Error testing
```
🧪 Integration testing  
📊 Complete coverage

---

### Scripts (4 files)

#### **scripts/deploy.js**
```bash
# Deploy to Cronos testnet
npx hardhat run scripts/deploy.js --network cronosTestnet

# Output:
# - Deploys CroGasRelay, MockUSDC, TestTarget
# - Mints test USDC
# - Sets up approvals
# - Prints addresses
```

#### **scripts/deploy-mainnet.js**
```bash
# Deploy to Cronos mainnet (when ready)
npx hardhat run scripts/deploy-mainnet.js --network cronosMainnet

# Requirements:
# - Security audit completed
# - Mainnet testnet passed
# - Admin wallet setup
```

#### **scripts/test-transactions.js**
```bash
# Test transactions on testnet
npx hardhat run scripts/test-transactions.js --network cronosTestnet

# Tests:
# - Simple increment
# - Value storage
# - Error handling
# - Gas tracking
```

#### **scripts/verify-contracts.js**
```bash
# Verify contracts on Cronoscan
npx hardhat run scripts/verify-contracts.js --network cronosTestnet

# Verifies:
# - Contract code
# - Compiler version
# - Optimization settings
```

---

### Tests (3 files)

#### **test/CroGasRelay.test.js**
```bash
# Test relay contract
npx hardhat test test/CroGasRelay.test.js

# Covers:
# - Deployment
# - Transaction execution
# - Signature verification
# - Admin functions
# - Error cases
```

#### **test/MockUSDC.test.js**
```bash
# Test token contract
npx hardhat test test/MockUSDC.test.js

# Covers:
# - Minting
# - Transfers
# - Approvals
# - Permit functionality
```

#### **test/TestTarget.test.js**
```bash
# Test target contract
npx hardhat test test/TestTarget.test.js

# Covers:
# - Counter increment
# - Value storage
# - Interaction tracking
# - Complex operations
```

---

## 🚀 Setup Instructions

### 1. Clone Repository
```bash
git clone https://github.com/KingRaver/CroGas.git
cd CroGas
```

### 2. Install Dependencies
```bash
npm install
# or
yarn install

# Installs:
# - hardhat
# - ethers
# - @openzeppelin/contracts
# - dotenv
# - chai (testing)
```

### 3. Configure Environment
```bash
# Create .env from template
cp .env.example .env

# Edit .env with:
CRONOS_TESTNET_RPC=https://evm-t3.cronos.org:8545
CRONOS_MAINNET_RPC=https://evm.cronos.org
DEPLOYER_PRIVATE_KEY=0x... # Your wallet private key
ETHERSCAN_API_KEY=... # For verification (optional)
```

⚠️ **SECURITY**: Never commit .env file with real private keys!

### 4. Compile Contracts
```bash
npx hardhat compile

# Output:
# Compiled 3 contracts
# - CroGasRelay
# - MockUSDC
# - TestTarget
```

### 5. Run Tests
```bash
npx hardhat test

# Output:
# ✓ 8 passing (2s)
# - Deployment: 3 tests
# - Execution: 3 tests
# - Admin: 2 tests
```

### 6. Deploy to Testnet
```bash
npx hardhat run scripts/deploy.js --network cronosTestnet

# Output:
# ✅ Deployed to Cronos testnet
# - CroGasRelay: 0x...
# - MockUSDC: 0x...
# - TestTarget: 0x...
```

---

## 📦 Dependencies

### Core Dependencies
```json
{
  "dependencies": {
    "@openzeppelin/contracts": "^5.0.0",
    "ethers": "^6.0.0"
  },
  "devDependencies": {
    "hardhat": "^2.18.0",
    "@nomicfoundation/hardhat-toolbox": "^3.0.0",
    "@nomicfoundation/hardhat-ethers": "^3.0.0",
    "dotenv": "^16.3.1",
    "chai": "^4.3.10",
    "hardhat-gas-reporter": "^1.0.9"
  }
}
```

---

## 🔑 Environment Variables

### Required
```env
# Cronos RPC endpoints
CRONOS_TESTNET_RPC=https://evm-t3.cronos.org:8545
CRONOS_MAINNET_RPC=https://evm.cronos.org

# Deployer wallet private key
DEPLOYER_PRIVATE_KEY=0x...
```

### Optional
```env
# Block explorer API key for verification
ETHERSCAN_API_KEY=...

# Report gas usage
REPORT_GAS=true

# Coinmarketcap API for gas in USD
COINMARKETCAP_API_KEY=...
```

---

## 🎯 Common Commands

### Development
```bash
# Compile contracts
npx hardhat compile

# Run all tests
npx hardhat test

# Run specific test file
npx hardhat test test/CroGasRelay.test.js

# Run with verbose output
npx hardhat test --verbose

# Run with gas reporting
REPORT_GAS=true npx hardhat test

# Check test coverage
npx hardhat coverage
```

### Deployment
```bash
# Deploy to testnet
npx hardhat run scripts/deploy.js --network cronosTestnet

# Deploy to mainnet
npx hardhat run scripts/deploy-mainnet.js --network cronosMainnet

# Verify contracts
npx hardhat verify --network cronosTestnet <ADDRESS> <ARGS>
```

### Utilities
```bash
# List available tasks
npx hardhat

# View network configuration
npx hardhat networks

# Run custom script
npx hardhat run scripts/custom-script.js --network cronosTestnet

# Clean build artifacts
npx hardhat clean
```

---

## 📚 Documentation Map

```
docs/
├── CONTRACTS_DEPLOYMENT.md
│   ├── Setup & installation
│   ├── Step-by-step deployment
│   ├── Full test suite
│   └── Mainnet checklist
│
├── CONTRACTS_README.md
│   ├── Contract overview
│   ├── Quick start
│   ├── Security features
│   └── Interface documentation
│
├── CONTRACTS_SUMMARY.md
│   ├── What was created
│   ├── Deployment timeline
│   └── Pre-deployment checklist
│
├── SECURITY_AUDIT.md (TODO)
│   ├── Audit results
│   ├── Findings & fixes
│   └── Certification
│
└── GAS_OPTIMIZATION.md (TODO)
    ├── Gas costs
    ├── Optimization strategies
    └── Benchmark results
```

---

## ✅ Pre-Deployment Checklist

### Code Quality
- [ ] All contracts compile without errors
- [ ] No warnings or linting issues
- [ ] Code follows Solidity style guide
- [ ] Comments are comprehensive
- [ ] No hardcoded values

### Testing
- [ ] All unit tests pass
- [ ] Integration tests pass
- [ ] Coverage >90%
- [ ] Error cases tested
- [ ] Edge cases covered

### Security
- [ ] Access control verified
- [ ] Signature verification tested
- [ ] Replay protection confirmed
- [ ] Reentrancy guard in place
- [ ] No known vulnerabilities

### Documentation
- [ ] Contract docs complete
- [ ] Function docs complete
- [ ] Deployment guide ready
- [ ] API reference done
- [ ] Examples provided

### Deployment
- [ ] Environment variables set
- [ ] Private keys secured
- [ ] Testnet deployment successful
- [ ] Contracts verified on explorer
- [ ] All addresses documented

---

## 🔗 Integration Checklist

### For Frontend Integration
- [ ] Copy contract ABIs to frontend/public/abis/
- [ ] Update contract addresses in .env
- [ ] Test contract interactions
- [ ] Verify signature generation
- [ ] Check gas estimates

### For Backend Integration
- [ ] Setup relayer address
- [ ] Configure USDC token address
- [ ] Implement signature verification
- [ ] Add transaction logging
- [ ] Setup monitoring

### For DevOps
- [ ] Setup deployment pipeline
- [ ] Configure monitoring
- [ ] Setup alerts
- [ ] Plan scaling
- [ ] Document runbooks

---

## 🐛 Troubleshooting

### Compilation Errors
```bash
# Clear build cache
npx hardhat clean

# Reinstall dependencies
npm install

# Try again
npx hardhat compile
```

### Test Failures
```bash
# Run with verbose output
npx hardhat test --verbose

# Run specific test
npx hardhat test test/CroGasRelay.test.js --grep "specific test name"

# Check for flaky tests
npx hardhat test --reporter json > test-results.json
```

### Deployment Issues
```bash
# Verify RPC connection
npx hardhat accounts --network cronosTestnet

# Check gas prices
npx hardhat run scripts/check-gas.js --network cronosTestnet

# Retry with higher gas price
# Edit scripts/deploy.js, increase gasPrice
```

---

## 📞 Getting Help

### Documentation
- **CONTRACTS_DEPLOYMENT.md** - Setup & deployment
- **CONTRACTS_README.md** - Contract reference
- **CONTRACTS_SUMMARY.md** - Overview & summary

### Community
- [GitHub Issues](https://github.com/KingRaver/CroGas/issues)
- [GitHub Discussions](https://github.com/KingRaver/CroGas/discussions)

### Security
- ⚠️ Email: security@crogas.dev
- DO NOT open public issue for security bugs

---

## 📄 Related Files

- [TECHNICAL_FLOW.md](../TECHNICAL_FLOW.md) - Complete transaction flow
- [ARCHITECTURE.md](../ARCHITECTURE.md) - System design
- [API.md](../API.md) - Backend API reference
- [README.md](../README.md) - Project overview

---

**Last Updated**: January 5, 2026  
**Status**: Production Ready for Testnet ✅  
**Version**: 1.0.0 Complete
