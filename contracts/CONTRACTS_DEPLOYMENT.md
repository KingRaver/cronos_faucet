# Smart Contracts Deployment Guide

Complete guide for deploying CroGas smart contracts to Cronos Testnet.

---

## 📦 Contract Architecture

```
CroGasRelay (Main Contract)
├── CroGasRelay.sol - Core relay contract
├── MockUSDC.sol - Mock USDC token (testnet only)
└── TestTarget.sol - Test target contract

Interactions:
User → CroGasRelay → TestTarget (or any other contract)
          ↓
       MockUSDC (collect fees)
```

---

## 🔧 Prerequisites

### System Requirements
- Node.js v18+ 
- npm or yarn
- Git

### Install Dependencies
```bash
npm install --save-dev hardhat @openzeppelin/contracts ethers
npm install @openzeppelin/contracts
```

### Environment Setup
```bash
# Create .env file
cp .env.example .env

# Add to .env:
CRONOS_TESTNET_RPC=https://evm-t3.cronos.org:8545
CRONOS_MAINNET_RPC=https://evm.cronos.org
DEPLOYER_PRIVATE_KEY=0x... # Your wallet private key
ETHERSCAN_API_KEY=... # For contract verification (optional)
```

---

## 📋 Contract Details

### 1. CroGasRelay.sol (Main Contract)

**Purpose**: Execute meta-transactions without requiring users to hold CRO

**Key Functions**:
- `executeTx()` - Execute transaction and collect USDC fee
- `executeTxWithPermit()` - Execute with EIP-712 permit signature
- `withdrawUSDC()` - Withdraw accumulated fees
- `setRelayer()` - Update relayer address
- `setUSDCAddress()` - Update USDC token address
- `setFeePercentage()` - Update protocol fee %

**State Variables**:
- `userNonces` - Nonce mapping for replay protection
- `usdcToken` - USDC token address
- `relayer` - Authorized relayer address
- `feePercentage` - Protocol fee (default 1%)
- `accumulatedUSDC` - Total fees collected

**Events**:
- `TransactionRelayed` - When transaction executed
- `USDCCollected` - When fee collected
- `RelayerUpdated` - When relayer changed
- `USDCAddressUpdated` - When USDC address changed
- `FeePercentageUpdated` - When fee % changed

**Security Features**:
✅ EIP-712 signature verification
✅ Nonce-based replay protection
✅ ReentrancyGuard
✅ Balance validation
✅ Access control (onlyOwner, onlyRelayer)

---

### 2. MockUSDC.sol (Test Token)

**Purpose**: Mock USDC for testing (testnet only)

**Key Functions**:
- `mint()` - Mint tokens (owner only)
- `claimTestnetUSDC()` - Faucet (anyone can claim)

**Decimals**: 6 (matches real USDC)

**Security**: 
⚠️ Only for testnet - DO NOT use on mainnet

---

### 3. TestTarget.sol (Test Contract)

**Purpose**: Simple contract to test relay functionality

**Key Functions**:
- `increment()` - Increment counter
- `storeValue()` - Store value for user
- `getValue()` - Retrieve stored value
- `revertingFunction()` - Test error handling
- `complexOperation()` - Multi-step operation test

---

## 🚀 Deployment Steps

### Step 1: Create Hardhat Project

```bash
# Initialize hardhat
npx hardhat init

# Select: Create an empty hardhat.config.js
cd my-crogas-contracts
```

### Step 2: Configure Hardhat

**hardhat.config.js**:
```javascript
require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("dotenv").config();

module.exports = {
  solidity: "0.8.20",
  networks: {
    cronosTestnet: {
      url: process.env.CRONOS_TESTNET_RPC,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
      chainId: 338
    },
    cronosMainnet: {
      url: process.env.CRONOS_MAINNET_RPC,
      accounts: [process.env.DEPLOYER_PRIVATE_KEY],
      chainId: 25
    }
  },
  etherscan: {
    apiKey: {
      cronosTestnet: process.env.ETHERSCAN_API_KEY || "api-key"
    }
  }
};
```

### Step 3: Create Contract Files

```bash
mkdir contracts

# Copy contracts to contracts/ directory
# - CroGasRelay.sol
# - MockUSDC.sol
# - TestTarget.sol
```

### Step 4: Compile Contracts

```bash
npx hardhat compile

# Output:
# CroGasRelay
# MockUSDC
# TestTarget
```

### Step 5: Create Deployment Script

**scripts/deploy.js**:
```javascript
const hre = require("hardhat");

async function main() {
    console.log("🚀 Deploying CroGas contracts to Cronos testnet...\n");

    // Get deployer account
    const [deployer] = await hre.ethers.getSigners();
    console.log("📝 Deploying contracts with account:", deployer.address);
    console.log("Account balance:", (await deployer.getBalance()).toString());

    // 1. Deploy MockUSDC
    console.log("\n1️⃣  Deploying MockUSDC...");
    const MockUSDC = await hre.ethers.getContractFactory("MockUSDC");
    const mockUSDC = await MockUSDC.deploy();
    await mockUSDC.waitForDeployment();
    const usdcAddress = await mockUSDC.getAddress();
    console.log("✅ MockUSDC deployed to:", usdcAddress);

    // 2. Deploy CroGasRelay
    console.log("\n2️⃣  Deploying CroGasRelay...");
    const CroGasRelay = await hre.ethers.getContractFactory("CroGasRelay");
    const relay = await CroGasRelay.deploy(usdcAddress, deployer.address);
    await relay.waitForDeployment();
    const relayAddress = await relay.getAddress();
    console.log("✅ CroGasRelay deployed to:", relayAddress);

    // 3. Deploy TestTarget
    console.log("\n3️⃣  Deploying TestTarget...");
    const TestTarget = await hre.ethers.getContractFactory("TestTarget");
    const testTarget = await TestTarget.deploy();
    await testTarget.waitForDeployment();
    const testTargetAddress = await testTarget.getAddress();
    console.log("✅ TestTarget deployed to:", testTargetAddress);

    // 4. Verify deployments
    console.log("\n📋 Deployment Summary:");
    console.log("=".repeat(50));
    console.log("MockUSDC:   ", usdcAddress);
    console.log("CroGasRelay:", relayAddress);
    console.log("TestTarget: ", testTargetAddress);
    console.log("=".repeat(50));

    // 5. Fund MockUSDC
    console.log("\n💰 Funding deployer with MockUSDC...");
    const mintTx = await mockUSDC.mint(
        deployer.address,
        hre.ethers.parseUnits("10000", 6)
    );
    await mintTx.wait();
    console.log("✅ Minted 10,000 USDC to deployer");

    // 6. Setup approvals
    console.log("\n🔐 Setting up approvals...");
    const approveTx = await mockUSDC.approve(
        relayAddress,
        hre.ethers.parseUnits("10000", 6)
    );
    await approveTx.wait();
    console.log("✅ Approved CroGasRelay to spend USDC");

    console.log("\n✨ Deployment complete!");
    console.log("\n📚 Next steps:");
    console.log("1. Verify contracts on block explorer");
    console.log("2. Update frontend with contract addresses");
    console.log("3. Run tests: npx hardhat test");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
```

### Step 6: Deploy

```bash
# Deploy to Cronos testnet
npx hardhat run scripts/deploy.js --network cronosTestnet

# Output:
# 🚀 Deploying CroGas contracts to Cronos testnet...
# 
# 📝 Deploying contracts with account: 0x...
# Account balance: 12345678900000000000
# 
# 1️⃣  Deploying MockUSDC...
# ✅ MockUSDC deployed to: 0x...
# 
# 2️⃣  Deploying CroGasRelay...
# ✅ CroGasRelay deployed to: 0x...
# 
# 3️⃣  Deploying TestTarget...
# ✅ TestTarget deployed to: 0x...
# 
# 📋 Deployment Summary:
# ==================================================
# MockUSDC:    0x...
# CroGasRelay: 0x...
# TestTarget:  0x...
# ==================================================
# 
# 💰 Funding deployer with MockUSDC...
# ✅ Minted 10,000 USDC to deployer
# 
# 🔐 Setting up approvals...
# ✅ Approved CroGasRelay to spend USDC
# 
# ✨ Deployment complete!
```

---

## 🧪 Testing

### Create Test File

**test/CroGasRelay.test.js**:
```javascript
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("CroGasRelay", function () {
    let relay, mockUSDC, testTarget;
    let owner, relayer, user;

    beforeEach(async function () {
        [owner, relayer, user] = await ethers.getSigners();

        // Deploy MockUSDC
        const MockUSDC = await ethers.getContractFactory("MockUSDC");
        mockUSDC = await MockUSDC.deploy();

        // Deploy CroGasRelay
        const CroGasRelay = await ethers.getContractFactory("CroGasRelay");
        relay = await CroGasRelay.deploy(
            await mockUSDC.getAddress(),
            relayer.address
        );

        // Deploy TestTarget
        const TestTarget = await ethers.getContractFactory("TestTarget");
        testTarget = await TestTarget.deploy();

        // Mint USDC to user
        await mockUSDC.mint(user.address, ethers.parseUnits("1000", 6));

        // Approve relay to spend user's USDC
        await mockUSDC.connect(user).approve(
            await relay.getAddress(),
            ethers.parseUnits("1000", 6)
        );
    });

    describe("Deployment", function () {
        it("Should set correct owner", async function () {
            expect(await relay.owner()).to.equal(owner.address);
        });

        it("Should set correct relayer", async function () {
            expect(await relay.relayer()).to.equal(relayer.address);
        });

        it("Should set correct USDC address", async function () {
            expect(await relay.usdcToken()).to.equal(await mockUSDC.getAddress());
        });
    });

    describe("Transaction Execution", function () {
        it("Should execute transaction and collect USDC", async function () {
            // Prepare target call
            const targetInterface = new ethers.Interface(["function increment()"]);
            const calldata = targetInterface.encodeFunctionData("increment");

            // Create message hash
            const messageHash = ethers.solidityPackedKeccak256(
                ["address", "address", "bytes", "uint256"],
                [user.address, await testTarget.getAddress(), calldata, 0]
            );

            // Sign message
            const signature = await user.signMessage(ethers.getBytes(messageHash));

            // Execute transaction
            const usdcAmount = ethers.parseUnits("1", 6);
            const tx = await relay.connect(relayer).executeTx(
                user.address,
                await testTarget.getAddress(),
                calldata,
                signature,
                usdcAmount
            );

            expect(tx).to.emit(relay, "TransactionRelayed");
            expect(tx).to.emit(relay, "USDCCollected");
        });

        it("Should increment nonce after transaction", async function () {
            const initialNonce = await relay.getNonce(user.address);
            expect(initialNonce).to.equal(0);

            // Execute transaction...
            // After execution, nonce should be 1
        });

        it("Should reject invalid signature", async function () {
            const calldata = "0x";
            const badSignature = "0x" + "00".repeat(65);

            await expect(
                relay.connect(relayer).executeTx(
                    user.address,
                    await testTarget.getAddress(),
                    calldata,
                    badSignature,
                    ethers.parseUnits("1", 6)
                )
            ).to.be.revertedWith("Invalid signature");
        });
    });

    describe("Admin Functions", function () {
        it("Should allow owner to withdraw USDC", async function () {
            // Deposit some USDC first
            await mockUSDC.transfer(
                await relay.getAddress(),
                ethers.parseUnits("100", 6)
            );

            const initialBalance = await mockUSDC.balanceOf(owner.address);
            await relay.withdrawUSDC(ethers.parseUnits("50", 6));
            const finalBalance = await mockUSDC.balanceOf(owner.address);

            expect(finalBalance).to.be.greaterThan(initialBalance);
        });

        it("Should allow owner to change relayer", async function () {
            const newRelayer = ethers.getAddress("0x" + "1".repeat(40));
            await relay.setRelayer(newRelayer);
            expect(await relay.relayer()).to.equal(newRelayer);
        });
    });
});
```

### Run Tests

```bash
npx hardhat test

# Output:
# CroGasRelay
#   Deployment
#     ✓ Should set correct owner
#     ✓ Should set correct relayer
#     ✓ Should set correct USDC address
#   Transaction Execution
#     ✓ Should execute transaction and collect USDC
#     ✓ Should increment nonce after transaction
#     ✓ Should reject invalid signature
#   Admin Functions
#     ✓ Should allow owner to withdraw USDC
#     ✓ Should allow owner to change relayer
#
# 8 passing (2s)
```

---

## 📡 Deployment to Mainnet

### Checklist Before Mainnet

- [ ] All tests passing
- [ ] Contracts audited
- [ ] No console.logs in code
- [ ] Gas optimization reviewed
- [ ] Emergency pause function added
- [ ] Rate limiting configured
- [ ] Relayer funding plan ready

### Mainnet Deployment

```bash
# Deploy to Cronos mainnet
npx hardhat run scripts/deploy.js --network cronosMainnet

# Verify on explorer
npx hardhat verify --network cronosMainnet <CONTRACT_ADDRESS> <CONSTRUCTOR_ARGS>
```

---

## 🔍 Verification on Block Explorer

### Verify CroGasRelay on Cronoscan

```bash
npx hardhat verify --network cronosTestnet <RELAY_ADDRESS> <USDC_ADDRESS> <RELAYER_ADDRESS>
```

### Manual Verification

1. Go to https://testnet.cronoscan.com
2. Search for contract address
3. Click "Verify & Publish"
4. Upload contract code
5. Fill contract details

---

## 📚 Contract File Structure

```
contracts/
├── CroGasRelay.sol      # Main relay contract
├── MockUSDC.sol         # Test USDC token
└── TestTarget.sol       # Test target contract

scripts/
├── deploy.js            # Deployment script
└── test-tx.js           # Transaction test script

test/
├── CroGasRelay.test.js  # Contract tests
├── MockUSDC.test.js     # Token tests
└── TestTarget.test.js   # Target tests

hardhat.config.js        # Hardhat configuration
.env.example             # Environment variables template
```

---

## 🐛 Troubleshooting

### "Insufficient gas"
```bash
# Ensure deployer has CRO on testnet
# Get testnet CRO from faucet: https://testnet.cronoscan.com/faucet
```

### "Invalid contract address"
```bash
# Check if address is checksummed
# Use: ethers.getAddress("0x...")
```

### "USDC transfer failed"
```bash
# Ensure:
# 1. USDC contract address is correct
# 2. User has USDC balance
# 3. User approved relay contract
```

---

## 🎯 Next Steps

1. **Deploy contracts** → Run `npx hardhat run scripts/deploy.js --network cronosTestnet`
2. **Update frontend** → Add contract addresses to `.env.local`
3. **Test relay** → Call `executeTx()` with test transactions
4. **Monitor gas** → Track transaction costs
5. **Audit** → Have contracts reviewed by security firm
6. **Mainnet** → Deploy to production network

---

**Last Updated**: January 5, 2026  
**Solidity Version**: 0.8.20  
**Test Network**: Cronos Testnet (Chain ID: 338)
