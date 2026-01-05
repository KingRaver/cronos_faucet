# CroGas Smart Contracts

Production-ready Solidity smart contracts for the CroGas meta-transaction relay system on Cronos blockchain.

---

## 📦 What's Included

### Core Contracts

#### **CroGasRelay.sol** (Main Contract)
- Executes meta-transactions on behalf of users
- Collects USDC fees from users
- Tracks nonces for replay protection
- Manages relayer and protocol settings

**Lines of Code**: ~250  
**Functions**: 12  
**Security**: EIP-712, ReentrancyGuard, Access Control

---

#### **MockUSDC.sol** (Test Token)
- Mock USDC token for Cronos testnet
- Implements ERC20 + Permit standard
- Includes faucet function for testing

**Lines of Code**: ~35  
**Functions**: 3  
**Network**: Testnet only

---

#### **TestTarget.sol** (Test Contract)
- Simple target contract for relay testing
- Counter and value storage
- Tests all types of function calls

**Lines of Code**: ~85  
**Functions**: 7  
**Purpose**: Integration testing

---

## 🚀 Quick Start

### 1. Install Dependencies
```bash
npm install --save-dev hardhat @openzeppelin/contracts ethers
```

### 2. Setup Environment
```bash
cp .env.example .env
# Fill in: CRONOS_TESTNET_RPC, DEPLOYER_PRIVATE_KEY
```

### 3. Deploy
```bash
npx hardhat run scripts/deploy.js --network cronosTestnet
```

### 4. Verify
```bash
npx hardhat verify --network cronosTestnet <ADDRESS> <ARGS>
```

---

## 🔐 Security Features

### ✅ Access Control
- `onlyOwner` - Administrative functions
- `onlyRelayer` - Transaction execution

### ✅ Replay Protection
- Nonce mapping per user
- Incremented after each transaction
- Prevents duplicate signatures

### ✅ Signature Verification
- EIP-712 typed data signing
- ECDSA signature recovery
- Message hash validation

### ✅ Reentrancy Protection
- OpenZeppelin ReentrancyGuard
- Guards on state-changing functions

### ✅ Balance Validation
- Check USDC balance before execution
- Check relayer CRO balance
- Prevent failed transactions

---

## 📊 Gas Optimization

### Estimated Gas Usage

| Function | Gas | Notes |
|----------|-----|-------|
| `executeTx()` | ~150,000 | Includes target call |
| `withdrawUSDC()` | ~30,000 | ERC20 transfer |
| `setRelayer()` | ~25,000 | Simple state update |
| `increment()` (TestTarget) | ~20,000 | Via relay |

---

## 🧪 Testing

### Run All Tests
```bash
npx hardhat test

# Expected output:
# CroGasRelay
#   Deployment
#     ✓ Should set correct owner
#     ✓ Should set correct relayer
#     ...
#
# 8 passing (2s)
```

### Test Coverage
```bash
npx hardhat coverage

# Expected: 90%+ coverage
```

### Specific Test
```bash
npx hardhat test test/CroGasRelay.test.js
npx hardhat test test/MockUSDC.test.js
npx hardhat test test/TestTarget.test.js
```

---

## 📋 Contract Interfaces

### CroGasRelay

```solidity
// Execute transaction
function executeTx(
    address user,
    address target,
    bytes calldata data,
    bytes calldata signature,
    uint256 usdcAmount
) external returns (bool, bytes memory)

// Execute with permit
function executeTxWithPermit(
    address user,
    address target,
    bytes calldata data,
    bytes calldata signature,
    uint256 usdcAmount,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
) external returns (bool, bytes memory)

// Admin: Withdraw fees
function withdrawUSDC(uint256 amount) external onlyOwner

// Admin: Update relayer
function setRelayer(address _newRelayer) external onlyOwner

// Admin: Update USDC address
function setUSDCAddress(address _newUSDC) external onlyOwner

// Admin: Update fee percentage
function setFeePercentage(uint256 _newFeePercentage) external onlyOwner

// View: Get user nonce
function getNonce(address user) external view returns (uint256)
```

---

## 🔄 Transaction Flow

```
1. User signs EIP-712 message
   ├─ User address
   ├─ Target contract
   ├─ Calldata
   ├─ User nonce
   └─ Deadline

2. Frontend sends to backend:
   POST /x402/facilitate {
     userAddress,
     targetContract,
     calldata,
     signature,
     usdcAmount
   }

3. Backend validates:
   ├─ Signature verification ✓
   ├─ Nonce check ✓
   ├─ USDC balance ✓
   └─ Rate limiting ✓

4. Backend calls executeTx():
   ├─ Verify signature
   ├─ Increment nonce
   ├─ Execute target call
   ├─ Transfer USDC from user
   └─ Emit events

5. Return result to frontend
   ├─ Success flag
   ├─ Transaction hash
   └─ Return data
```

---

## 🔐 Security Audit Checklist

- [x] Access control implemented
- [x] Replay protection via nonces
- [x] Signature verification
- [x] Reentrancy guard
- [x] Balance validation
- [x] Event logging
- [x] Error handling
- [x] Gas optimization
- [ ] External audit (TODO)
- [ ] Mainnet deployment (TODO)

---

## 📝 Contract Deployment Checklist

### Before Testnet
- [x] All tests passing
- [x] No compiler warnings
- [x] Gas estimation done
- [x] Comments added

### Before Mainnet
- [ ] Security audit completed
- [ ] Mainnet testnet deployment successful
- [ ] Admin keys secured (multisig)
- [ ] Emergency pause mechanism added
- [ ] Rate limiting configured
- [ ] Relayer funding strategy defined
- [ ] Monitoring setup

---

## 🐛 Known Issues & Limitations

### Current
- Testnet only (no mainnet yet)
- Single relayer (consider decentralized relayer network)
- Fixed fee percentage (could be dynamic)
- No pause mechanism (recommend adding)

### Future Improvements
- [ ] Multi-relayer support
- [ ] Dynamic fee calculation
- [ ] Emergency pause function
- [ ] Rate limiting per user
- [ ] Custom calldata validation
- [ ] Batch transaction support
- [ ] Upgradeable contracts (proxy)

---

## 📚 Related Documentation

- **[TECHNICAL_FLOW.md](TECHNICAL_FLOW.md)** - Complete transaction flow with code
- **[API.md](API.md)** - Backend API reference
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design overview
- **[SECURITY.md](SECURITY.md)** - Security measures
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development guidelines

---

## 🔗 External References

### Standards
- [EIP-712: Typed structured data hashing](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-3009: Transfer With Authorization](https://eips.ethereum.org/EIPS/eip-3009)
- [ERC-20: Token Standard](https://eips.ethereum.org/EIPS/eip-20)

### Tools
- [Hardhat Documentation](https://hardhat.org/docs)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts)
- [Ethers.js](https://docs.ethers.org)

### Cronos
- [Cronos Docs](https://docs.cronos.org)
- [Cronos Testnet Faucet](https://testnet.cronoscan.com/faucet)
- [Cronoscan Block Explorer](https://testnet.cronoscan.com)

---

## 📞 Support

### Issues & Bug Reports
- [GitHub Issues](https://github.com/KingRaver/CroGas/issues)
- [GitHub Discussions](https://github.com/KingRaver/CroGas/discussions)

### Security Issues
- ⚠️ DO NOT open public issue for security bugs
- Email: security@crogas.dev
- Include: Description, reproduction steps, impact

---

## 📄 License

MIT License - See LICENSE file

---

## 🙏 Acknowledgments

- OpenZeppelin for secure contract libraries
- Cronos team for blockchain infrastructure
- Community testers and auditors

---

## 📅 Changelog

### Version 1.0.0 (January 5, 2026)
- Initial release
- CroGasRelay implementation
- MockUSDC for testing
- TestTarget for validation
- Full test suite
- Deployment guide

---

**Last Updated**: January 5, 2026  
**Latest Version**: 1.0.0  
**Status**: Ready for Testnet Deployment
