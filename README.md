# 🌊 CroGas: The Gas Station for AI Agents

> **Gasless transactions for the agentic economy.** Let AI agents execute Cronos transactions without holding CRO. Pay gas fees in USDC via the **x402 HTTP payment protocol**—turning the internet into a programmable payment layer.

---

## 🎯 Executive Summary

**CroGas** bridges AI agents and blockchain by enabling **gasless, USDC-denominated transactions** on Cronos through the emerging **x402 payment standard**. Instead of requiring users or agents to hold native tokens (CRO), CroGas facilitates meta-transactions where a relayer covers gas costs and recovers payment in stablecoins—directly over HTTP.

### Why This Matters

- **Agentic Economy**: AI agents can now participate in Web3 autonomously—discovering APIs, purchasing services, and executing transactions on-chain, all programmatically.
- **Developer Friction Reduction**: No wallet setup, no gas estimation, no bridge liquidity issues. Just sign and send USDC.
- **x402 Pioneer**: Built on Coinbase's cutting-edge x402 protocol, bringing instant blockchain settlement to standard HTTP.
- **Cronos Expansion**: Drives adoption and liquidity to the Cronos chain by removing the friction of acquiring CRO.

---

## 🏗️ Architecture Overview

### System Components

```
┌─────────────────────────────────────────────────────────────┐
│                     Frontend (Next.js 14)                    │
│  - Dashboard: Relayer status, metrics, transaction history  │
│  - Executor: Meta-tx form, gas tier selection (3 tiers)     │
│  - Settings: Theme, preferences, notifications              │
└────────────────────┬────────────────────────────────────────┘
                     │ HTTP + Wagmi
                     ↓
┌─────────────────────────────────────────────────────────────┐
│              Backend (Express + TypeScript)                  │
│  - Health checks & relayer monitoring                       │
│  - USDC Faucet endpoint (test token distribution)           │
│  - x402 Facilitator: Meta-tx relay & payment settlement     │
└────────────────────┬────────────────────────────────────────┘
                     │ Viem + Encrypted Keys
                     ↓
┌─────────────────────────────────────────────────────────────┐
│         Cronos Testnet (evm-t3.cronos.org)                  │
│  - Meta-transaction relay contract (x402 compatible)        │
│  - Target contracts (user execution scope)                  │
│  - Relayer account funding & USDC reserves                  │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
User/Agent Request
    ↓
[Frontend] Form submission (target, calldata, tier)
    ↓
[Frontend] Sign message (Wagmi + EIP-712)
    ↓
[Backend] POST /x402/facilitate
    ├─ Validate signature & request
    ├─ Extract USDC payment amount (tier-based)
    ├─ Check relayer balance sufficiency
    ├─ Execute meta-transaction (relay on-chain)
    ├─ Verify payment settlement
    └─ Return tx hash + explorer link
    ↓
[Blockchain] Transaction confirmed on Cronos
    ↓
[Frontend] Update dashboard metrics & history
```

---

## ✨ Key Features

### 1. **Three-Tier Gas Pricing Model**

Meta-transaction execution with flexible pricing tiers:

| Tier | Name (EN/FR) | Gas Limit | Use Case |
|------|-------------|----------|----------|
| 🟢 **Slow** | Économique | Low | Non-urgent txs, batch operations |
| 🟡 **Normal** | Standard | Medium | General DeFi, routine interactions |
| 🔴 **Fast** | Prioritaire | High | Time-sensitive, MEV-sensitive ops |

**Smart Calculation**: USDC charge = `(gasUsed × gasPrice × tier) + facilitatorFee`

---

### 2. **Relayer Infrastructure & Monitoring**

- **Health Dashboard**: Real-time relayer status, CRO balance, USDC reserves, gas price feeds
- **Encrypted Key Management**: Private keys stored encrypted (AES-256), only decrypted in-memory at execution time
- **Rate Limiting**: Per-address throttling to prevent abuse; per-relayer balance safeguards
- **Signature Validation**: EIP-712 typed data verification before relay

---

### 3. **x402 Protocol Implementation**

Fully compliant with the **Coinbase x402 specification**:

- **HTTP-Native**: Payments flow through `X-PAYMENT` and `X-PAYMENT-RESPONSE` headers
- **EIP-3009 Compatible**: Uses `transferWithAuthorization()` for gasless USDC transfers
- **Instant Settlement**: ~2-second on-chain confirmation (Cronos block time)
- **Automatic Routing**: Facilitator handles signature verification, nonce tracking, and replay protection

---

### 4. **Developer-Friendly UI**

**Art Deco-Themed Design System**:
- **Aesthetic**: Geometric patterns, vintage luxury aesthetic (Poiret One headings, DM Sans body)
- **Accessibility**: WCAG AA contrast, keyboard navigation, focus indicators
- **Responsive**: Mobile-first, works on all breakpoints
- **Dark/Light Themes**: Parisian Light, Noir, Midnight Teal variants

**Core Pages**:
- `/dashboard` – Metrics, relayer status, transaction feed
- `/execute` – Dedicated meta-tx executor with live gas estimates
- `/` – Home page with feature showcase and CTAs

---

### 5. **Notification System & Settings**

- **Event-Driven Notifications**: Success, error, pending, info types with unread badges
- **Theme Switching**: Apply theme instantly (no page reload)
- **Sound Effects**: Toggle transaction confirmation audio
- **Default Gas Tier**: User preference persistence via localStorage

---

## 🛠️ Technology Stack

### Frontend
- **Framework**: Next.js 14+ (App Router, React 18)
- **Styling**: Tailwind CSS 3.4.17 + custom Art Deco theme
- **Web3**: Wagmi 3.1.3, Viem 2.43.4 (Ethereum libraries for Cronos)
- **State**: TanStack React Query 5.59.15 (server state), useState (local state)
- **Icons**: Lucide React 0.441.0
- **Graphics**: Three.js 0.169.0 (available for future 3D enhancements)

### Backend
- **Runtime**: Node.js 18+ with TypeScript
- **Server**: Express.js (lightweight, proven)
- **Blockchain**: Viem 2.43.4 (type-safe Ethereum/Cronos client)
- **Validation**: Zod (schema validation)
- **Logging**: Pino (high-performance structured logging)
- **Security**: AES-256 encryption (crypto module), in-memory key storage
- **Rate Limiting**: In-memory throttling middleware

### Infrastructure
- **Deployment**: Vercel (frontend + serverless backend)
- **Blockchain RPC**: Cronos testnet (evm-t3.cronos.org)
- **Database**: None (stateless; future: Redis for distributed rate-limiting, metrics)

---

## 🚀 Getting Started

### Prerequisites
- Node.js 18+
- Git
- Wallet with Cronos testnet tokens (faucet available)

### Installation

```bash
# Clone repository
git clone https://github.com/KingRaver/cronos_faucet.git
cd CroGas

# Install dependencies
npm install

# Setup environment variables
cp .env.example .env
# Edit .env with relayer private key, API endpoints, etc.

# Generate/manage relayer keys (see scripts/)
npm run keys:generate
npm run keys:encrypt <your-key>

# Run development server
npm run dev
# Frontend: http://localhost:3000
# Backend API: http://localhost:3000/api/*

# Build for production
npm run build
npm run start
```

### Environment Variables (Backend)

```bash
# Relayer & Blockchain
RELAYER_PRIVATE_KEY_ENCRYPTED=<AES-256 encrypted key>
RELAYER_ENCRYPTION_KEY=<32-byte hex key for decryption>
CRONOS_RPC_URL=https://evm-t3.cronos.org  # Testnet
CRONOS_CHAIN_ID=338

# USDC Configuration
USDC_TOKEN_ADDRESS=0x<USDC contract on Cronos>
USDC_DECIMALS=6

# Facilitator Settings
FACILITATOR_FEE_PERCENT=1  # 1% commission on USDC payments
GAS_PRICE_MULTIPLIER_SLOW=0.8
GAS_PRICE_MULTIPLIER_NORMAL=1.0
GAS_PRICE_MULTIPLIER_FAST=1.3

# Rate Limiting
RATE_LIMIT_WINDOW_MS=3600000  # 1 hour
RATE_LIMIT_MAX_REQUESTS=100

# Node Environment
NODE_ENV=development
```

---

## 📊 Use Cases & Examples

### **Use Case 1: AI Agent DeFi Arbitrage**
```
1. Agent detects price discrepancy on Cronos DEX
2. Agent calls `/x402/facilitate` with swap calldata
3. Agent authorizes 50 USDC payment (x402 signature)
4. CroGas relayer executes swap + receives USDC
5. Agent captures profit, relayer captures fee
```

### **Use Case 2: Autonomous Service Orchestration**
```
1. AI agent needs to stake liquidity on Cronos
2. Instead of managing wallet, calls CroGas endpoint
3. Specifies target contract, function, params
4. Pays gas in USDC (no CRO required)
5. Service executes on-chain
```

### **Use Case 3: Batch Operations for DAOs**
```
1. DAO member wants to batch vote + delegate
2. Submits multi-step transaction via executor
3. Single USDC payment covers all gas
4. CroGas relayer executes atomically
5. DAO maintains low operational friction
```

---

## 🔐 Security Considerations

### Key Management
- **Encrypted Storage**: Relayer private key stored AES-256 encrypted
- **In-Memory Decryption**: Key decrypted only during transaction signing
- **Per-Operation Signing**: Each relay operation signs independently; no key reuse vulnerabilities

### Transaction Validation
- **EIP-712 Signature Verification**: Type-safe message hashing per Ethereum standard
- **Nonce Tracking**: Prevents replay attacks
- **Rate Limiting**: Per-address request throttling + per-relayer fund checks
- **Calldata Inspection**: Validates target contract before relay (whitelist pattern available)

### On-Chain Safety
- **Meta-Transaction Pattern**: Follows ERC-2771 best practices
- **x402 Compliance**: Uses standardized authorization (EIP-3009) for USDC transfers
- **Reversal Protection**: Failed transactions don't debit user; relayer absorbs gas cost

### Future Hardening
- [ ] Multi-signature relayer authority
- [ ] Timelock governance for parameter changes
- [ ] Insurance pool for failed transactions
- [ ] Decentralized relayer network (remove single point of failure)

---

## 📈 Metrics & Analytics

**Current Dashboard Tracks**:
- Relayer CRO balance (gas reserve)
- Relayer USDC reserves (payment buffer)
- Current network gas price (Cronos)
- Total transactions relayed (lifetime)

**Extensible to**:
- Average gas saved per transaction
- Total USDC facilitated
- Relayer profitability metrics
- User adoption funnels
- Network effects (agents onboarded, value locked)

---

## 🗓️ Roadmap

### Phase 1: Cronos Testnet (Current)
- ✅ Basic meta-transaction relay
- ✅ x402 facilitator endpoint
- ✅ Dashboard + executor UI
- ⏳ Community testing & feedback

### Phase 2: Mainnet & Scale
- [ ] Cronos mainnet deployment
- [ ] Multi-chain support (Polygon, Base, Arbitrum)
- [ ] Decentralized relayer network
- [ ] Advanced pricing (dynamic fees based on network load)

### Phase 3: Ecosystem Integration
- [ ] OpenAI Plugin for native x402 payments in GPT agents
- [ ] Integration with major AI agent frameworks (AutoGPT, LangChain)
- [ ] DAO governance layer for relayer parameters
- [ ] Insurance & slashing mechanics

### Phase 4: Web3 Infrastructure
- [ ] Become standard gas facilitation layer for Cronos
- [ ] Integrate with Account Abstraction (ERC-4337) for enhanced UX
- [ ] Cross-chain atomic swaps for gas payments
- [ ] zk-proof based privacy for transaction details

---

## 🤝 Contributing

We welcome contributions across all areas:

- **Smart Contracts**: Enhanced relay mechanisms, gas optimizations
- **Backend**: Distributed relayer network, advanced rate limiting
- **Frontend**: UX improvements, additional metrics, new themes
- **DevOps**: Monitoring, analytics, deployment automation

**Development Workflow**:
```bash
git checkout -b feature/your-feature
# Make changes
npm run test
npm run lint
git commit -m "feat: describe your change"
git push origin feature/your-feature
# Open PR for review
```

---

## 📜 License

MIT License – See LICENSE file for details. Feel free to fork, modify, and deploy.

---

## 💡 Why CroGas Matters

### For Users
- **Simplicity**: No gas worries. Just sign and transact.
- **Cost Efficiency**: Competitive USDC rates vs. traditional relayers
- **Speed**: 2-second settlement on Cronos

### For Developers
- **HTTP-Native**: Works with existing frameworks; no special wallet SDKs required
- **Open Protocol**: Built on x402 standard; not vendor-locked
- **Testnet-Friendly**: Easy to prototype with Cronos testnet

### For Investors/Partners
- **Market Timing**: x402 protocol just launched; CroGas is early-mover
- **Revenue Model**: Take facilitation fees (1%+) on every transaction
- **Multi-Chain Ready**: Architecture supports rollout to Polygon, Base, Arbitrum
- **Strategic Moat**: Becomes critical infrastructure for Cronos ecosystem

### For AI/Agents
- **Autonomous Participation**: Agents can now do DeFi, governance, services without managing wallets
- **Programmable Value**: HTTP payment layer enables real economic interactions
- **Scalability**: Facilitates billions of agentic transactions at minimal cost

---

## 🌐 Links & Resources

- **Website**: [cro-gas.vercel.app](https://cro-gas.vercel.app/)
- **GitHub**: [github.com/0xShortx/CroGas](https://github.com/KingRaver/cronos_faucet)
- **Cronos Docs**: [docs.cronos.org](https://docs.cronos.org)
- **x402 Protocol**: [x402.org](https://x402.org) | [Coinbase Docs](https://docs.cdp.coinbase.com/x402/welcome)
- **Cronos Testnet Faucet**: [cronos.org/faucet](https://cronos.org/faucet)

---

## 👨‍💻 Team & Contact

**Developed by**: KingRaver ([@github](https://github.com/KingRaver))

**Questions? Ideas? Partners?**
- Open an issue on GitHub
- Reach out on Twitter/X
- Join the community Discord (coming soon)

---

## 🙏 Acknowledgments

- **Coinbase**: x402 protocol & foundational work on HTTP payment standards
- **Cronos**: Testnet infrastructure & community support
- **Web3 Community**: Inspiration from meta-transaction pioneers (OpenGSN, Gelato, etc.)

---

## 📊 Quick Stats

| Metric | Value |
|--------|-------|
| **Lines of Code** | ~5,000 (frontend + backend) |
| **TypeScript Coverage** | 100% |
| **Components** | 8 core UI components |
| **API Endpoints** | 3 main routes (/health, /faucet, /x402) |
| **Supported Blockchains** | 1 (Cronos testnet); Multi-chain ready |
| **Time to Deploy** | ~5 minutes with Vercel |

---

**Built with ❤️ for the agentic economy.**

*Last updated: January 5, 2026*
