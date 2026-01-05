# CroGas Architecture

Deep technical dive into CroGas system design, data flow, component interactions, and scaling considerations.

---

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         End Users / AI Agents                    │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP (REST API)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│                    Frontend (Next.js 14 + React)                 │
│  ├─ Pages: /, /dashboard, /execute                              │
│  ├─ Components: Stats, Forms, Notifications, Settings           │
│  ├─ State: React Query + useState + localStorage                │
│  └─ Web3: Wagmi + Viem (Cronos testnet)                         │
└──────────────────────────┬──────────────────────────────────────┘
                           │ HTTP (JSON-RPC)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│              Backend API (Express.js + TypeScript)               │
│  ├─ Routes: /health, /faucet/usdc, /x402/facilitate            │
│  ├─ Middleware: Rate limiting, Zod validation, error handling  │
│  ├─ Services: Signature verification, payment settlement       │
│  └─ Data: Viem client for blockchain interaction               │
└──────────────────────────┬──────────────────────────────────────┘
                           │ JSON-RPC
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│       Cronos Testnet (evm-t3.cronos.org - Public RPC)           │
│  ├─ Meta-Transaction Relay Contract                             │
│  ├─ USDC Token Contract (EIP-3009 compatible)                   │
│  ├─ Relayer Account (with CRO + USDC reserves)                 │
│  └─ Target User Contracts (arbitrary execution)                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🔄 Data Flow: Meta-Transaction Execution

### Step 1: User Request (Frontend → Frontend State)

```javascript
// User fills form: target contract, function call, gas tier
const form = {
  target: '0x...',        // Target contract address
  calldata: '0x...',      // Encoded function call (via ethers.js)
  gasLevel: 'normal',     // Tier selection
  deadline: Math.floor(Date.now() / 1000) + 3600
};
```

### Step 2: Message Signing (Frontend → Wagmi)

```javascript
// Create EIP-712 message
const message = {
  types: {
    MetaTransaction: [
      { name: 'target', type: 'address' },
      { name: 'calldata', type: 'bytes' },
      { name: 'gasLevel', type: 'string' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' }
    ]
  },
  primaryType: 'MetaTransaction',
  domain: {
    name: 'CroGas',
    version: '1',
    chainId: 338,
    verifyingContract: RELAY_CONTRACT_ADDRESS
  },
  message: {
    target: form.target,
    calldata: form.calldata,
    gasLevel: form.gasLevel,
    nonce: userNonce,
    deadline: form.deadline
  }
};

// Sign with user's wallet
const signature = await signTypedDataAsync(message);
```

### Step 3: API Request (Frontend → Backend)

```javascript
// POST to /x402/facilitate with signed message
fetch('/api/x402/facilitate', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({
    target: form.target,
    calldata: form.calldata,
    gasLevel: form.gasLevel,
    userAddress: userAccount,
    signature,
    deadline: form.deadline,
    nonce: userNonce
  })
})
.then(res => res.json())
.then(data => console.log(data.transaction.txHash));
```

### Step 4: Backend Validation (Backend Service)

```typescript
// 1. Validate EIP-712 signature
const recoveredAddress = verifySignature(
  message,
  signature,
  chainId
);
if (recoveredAddress !== userAddress) throw new Error('Invalid signature');

// 2. Check nonce (prevent replay)
const userNonce = await getNonceFromStorage(userAddress);
if (message.nonce !== userNonce) throw new Error('Nonce mismatch');

// 3. Estimate gas
const gasEstimate = await relayerClient.estimateGas({
  to: target,
  data: calldata
});

// 4. Calculate USDC charge
const gasCost = gasEstimate * gasPrice * tierMultiplier;
const facilitatorFee = gasCost * 0.01;
const totalUSDC = gasCost + facilitatorFee;

// 5. Check user USDC balance (off-chain read)
const userBalance = await usdcToken.balanceOf(userAddress);
if (userBalance < totalUSDC) throw new Error('Insufficient balance');

// 6. Check relayer CRO balance for gas
const relayerCRO = await getRelayerBalance();
if (relayerCRO < gasCost) throw new Error('Relayer insufficient CRO');
```

### Step 5: On-Chain Execution (Backend → Blockchain)

```typescript
// 1. Prepare meta-transaction (relay contract call)
const relayTx = {
  to: RELAY_CONTRACT_ADDRESS,
  data: encodeABI('executeMetaTx', [
    userAddress,
    target,
    calldata,
    signature,
    nonce,
    deadline
  ])
};

// 2. Execute relay transaction
const txHash = await relayerAccount.sendTransaction(relayTx);

// 3. Wait for confirmation
const receipt = await relayerClient.waitForTransactionReceipt({ hash: txHash });

// 4. Verify execution succeeded
if (receipt.status === 0) throw new Error('Relay execution failed');

// 5. Extract actual gas used
const gasUsed = receipt.gasUsed;
const actualCost = gasUsed * receipt.effectiveGasPrice;
```

### Step 6: Payment Settlement (Backend → Blockchain)

```typescript
// 1. Prepare USDC payment (EIP-3009 transferWithAuthorization)
const usdcPaymentTx = {
  to: USDC_CONTRACT_ADDRESS,
  data: encodeABI('transferWithAuthorization', [
    userAddress,
    relayerAddress,
    actualCost + facilitatorFee,
    deadline,
    nonce,  // Different nonce for USDC contract
    signature  // User pre-signed this authorization
  ])
};

// 2. Execute payment
const paymentTxHash = await relayerAccount.sendTransaction(usdcPaymentTx);

// 3. Wait for confirmation
const paymentReceipt = await relayerClient.waitForTransactionReceipt({ 
  hash: paymentTxHash 
});

// 4. Increment user nonce (prevent replay on next tx)
await incrementNonce(userAddress);
```

### Step 7: Response to Frontend

```json
{
  "success": true,
  "transaction": {
    "txHash": "0x...",
    "explorerUrl": "https://cronoscan.com/tx/0x...",
    "status": "confirmed",
    "blockNumber": 1234567
  },
  "execution": {
    "target": "0x...",
    "gasUsed": 78932,
    "gasPrice": "5000000000"
  },
  "payment": {
    "amount": "0.39466",
    "currency": "USDC",
    "breakdown": {
      "baseGasCost": "0.38966",
      "facilitatorFee": "0.00500"
    }
  }
}
```

### Step 8: Dashboard Update (Frontend)

```javascript
// Update React Query cache
queryClient.invalidateQueries({ queryKey: ['recentTransactions'] });
queryClient.invalidateQueries({ queryKey: ['dashboardMetrics'] });

// Show success notification
showNotification({
  type: 'success',
  message: 'Transaction executed!',
  txHash: data.transaction.txHash
});

// Increment user's local nonce
setUserNonce(prev => prev + 1);
```

---

## 🗂️ Component Architecture

### Frontend Structure

```
crogas_frontend/
├── app/
│   ├── page.tsx                    # / - Home (hero, features, CTAs)
│   ├── dashboard/
│   │   └── page.tsx                # /dashboard - Control panel
│   ├── execute/
│   │   └── page.tsx                # /execute - Meta-tx executor
│   ├── layout.tsx                  # Root layout with providers
│   ├── globals.css                 # Art Deco theme, variables
│   └── api/
│       └── meta/route.ts           # API route proxy (optional)
│
├── components/
│   ├── notifications-dropdown.tsx   # Notification center
│   ├── settings-dropdown.tsx        # Theme, preferences
│   ├── stats-grid.tsx               # 4 metric cards
│   ├── meta-tx-form.tsx             # Execute form + history
│   └── ui/
│       ├── card.tsx                 # Glass morphism card
│       ├── input.tsx                # Styled form input
│       ├── button.tsx               # Button component
│       └── ...
│
├── lib/
│   ├── utils.ts                     # Helper utilities (cn, format)
│   ├── cronos.ts                    # Wagmi config + chain setup
│   └── api.ts                       # API client (getHealth, etc)
│
└── public/
    └── ...                          # Static assets (logos, fonts)
```

**Key Frontend Patterns:**

```typescript
// 1. Wagmi Hook Usage
const { address, isConnected } = useAccount();
const { signTypedDataAsync } = useSignTypedData();

// 2. React Query State
const { data: health } = useQuery({
  queryKey: ['health'],
  queryFn: () => api.getHealth(),
  refetchInterval: 5000  // Refresh every 5s
});

// 3. Local Storage Persistence
const theme = localStorage.getItem('theme') || 'light';
const defaultGasTier = localStorage.getItem('gasLevel') || 'normal';

// 4. Form State
const [formData, setFormData] = useState({
  target: '',
  calldata: '',
  gasLevel: 'normal'
});
```

### Backend Structure

```
crogas_backend/
├── src/
│   ├── index.ts                      # Express app setup
│   ├── routes/
│   │   ├── health.ts                 # GET /health
│   │   ├── faucet.ts                 # POST /faucet/usdc
│   │   └── x402.ts                   # POST /x402/facilitate
│   │
│   ├── middleware/
│   │   ├── rateLimit.ts              # In-memory rate limiting
│   │   ├── validation.ts             # Zod schema validation
│   │   └── errorHandler.ts           # Global error handling
│   │
│   ├── services/
│   │   ├── signature.ts              # EIP-712 verification
│   │   ├── relayer.ts                # Tx execution + key management
│   │   ├── payment.ts                # USDC settlement logic
│   │   └── gas.ts                    # Gas estimation & pricing
│   │
│   ├── config/
│   │   └── viem.ts                   # Viem client setup + decryption
│   │
│   ├── types/
│   │   └── index.ts                  # TypeScript interfaces
│   │
│   └── utils/
│       ├── env.ts                    # Environment variable validation
│       └── logger.ts                 # Pino structured logging
│
└── scripts/
    ├── generate-keys.js              # Generate new relayer key
    ├── encrypt-existing-key.js       # Encrypt existing key
    ├── get-address.js                # Get address from key
    └── README.md
```

**Key Backend Patterns:**

```typescript
// 1. Viem Client
import { createPublicClient, createWalletClient, http } from 'viem';
import { cronos } from 'viem/chains';

const publicClient = createPublicClient({
  chain: cronos,
  transport: http('https://evm-t3.cronos.org')
});

// 2. Middleware Stack
app.use(express.json());
app.use(rateLimitMiddleware);
app.use(validationMiddleware);

// 3. Route Handlers with Zod Validation
app.post('/x402/facilitate', async (req, res) => {
  const schema = z.object({
    target: z.string().regex(/^0x[a-f0-9]{40}$/i),
    calldata: z.string().startsWith('0x'),
    gasLevel: z.enum(['slow', 'normal', 'fast']),
    signature: z.string().startsWith('0x')
  });
  
  const data = schema.parse(req.body);
  // Process...
});

// 4. Error Handling
try {
  // Business logic
} catch (error) {
  if (error instanceof InsufficientBalanceError) {
    res.status(402).json({ error: 'insufficient_balance' });
  }
}
```

---

## 🔐 Security Architecture

### Key Management

```
┌─────────────────┐
│ Environment     │  RELAYER_PRIVATE_KEY_ENCRYPTED = "..."
│ Variable        │  RELAYER_ENCRYPTION_KEY = "..."
└────────┬────────┘
         │
         ↓
┌─────────────────────────────┐
│ Config (viem.ts)            │
│ - Read env vars             │
│ - Decrypt with AES-256      │  Only decrypted when needed
│ - Load into memory          │  (never written to disk)
└────────┬────────────────────┘
         │
         ↓
┌─────────────────────────────┐
│ Relayer Service             │
│ - Sign transactions         │
│ - Sign meta-tx relay calls  │
│ - Verify signatures (user)  │
└─────────────────────────────┘
```

**Implementation:**

```typescript
// Encryption (one-time setup)
import crypto from 'crypto';

function encryptKey(privateKey: string, encryptionKey: string): string {
  const cipher = crypto.createCipher('aes-256-cbc', encryptionKey);
  let encrypted = cipher.update(privateKey, 'utf8', 'hex');
  encrypted += cipher.final('hex');
  return encrypted;
}

// Decryption (at startup, never cached)
function decryptKey(encrypted: string, encryptionKey: string): string {
  const decipher = crypto.createDecipher('aes-256-cbc', encryptionKey);
  let decrypted = decipher.update(encrypted, 'hex', 'utf8');
  decrypted += decipher.final('utf8');
  return decrypted;
}

// Usage
const encryptedKey = process.env.RELAYER_PRIVATE_KEY_ENCRYPTED;
const encryptionKey = process.env.RELAYER_ENCRYPTION_KEY;
const relayerPrivateKey = decryptKey(encryptedKey, encryptionKey);

const walletClient = createWalletClient({
  chain: cronos,
  transport: http(),
  account: privateKeyToAccount(`0x${relayerPrivateKey}`)
});
```

### Signature Verification (EIP-712)

```typescript
import { verifyTypedData } from 'viem';

const recovered = verifyTypedData({
  address: userAddress,
  domain: {
    name: 'CroGas',
    version: '1',
    chainId: 338,
    verifyingContract: RELAY_CONTRACT_ADDRESS
  },
  types: {
    MetaTransaction: [
      { name: 'target', type: 'address' },
      { name: 'calldata', type: 'bytes' },
      { name: 'gasLevel', type: 'string' },
      { name: 'nonce', type: 'uint256' },
      { name: 'deadline', type: 'uint256' }
    ]
  },
  primaryType: 'MetaTransaction',
  message: {
    target, calldata, gasLevel, nonce, deadline
  },
  signature
});

if (!recovered) throw new Error('Invalid signature');
```

### Rate Limiting

```typescript
// In-memory store (single process)
const requestCounts = new Map<string, { count: number; resetAt: number }>();

function rateLimit(maxRequests: number, windowMs: number) {
  return (req: Request, res: Response, next: NextFunction) => {
    const key = req.body.userAddress || req.ip;
    const now = Date.now();
    const record = requestCounts.get(key);
    
    if (!record || now > record.resetAt) {
      requestCounts.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }
    
    if (record.count >= maxRequests) {
      return res.status(429).json({ error: 'rate_limited' });
    }
    
    record.count++;
    next();
  };
}
```

---

## 📈 State Management

### Frontend State Layers

```
┌────────────────────────────────────────┐
│ localStorage                           │
│ - theme: 'light' | 'dark'              │
│ - gasLevel: 'slow' | 'normal' | 'fast' │
│ - userPreferences: {...}               │
└────────────────────────────────────────┘
         ↑
         │ Hydrated on page load
         ↓
┌────────────────────────────────────────┐
│ React Context / Zustand (future)       │
│ - Theme state (global)                 │
│ - Notification queue                   │
│ - User preferences                     │
└────────────────────────────────────────┘
         ↑
         │ Updates UI
         ↓
┌────────────────────────────────────────┐
│ React Query (Server State)             │
│ - Health endpoint (refetch 5s)         │
│ - Recent transactions (cache 1m)       │
│ - Dashboard metrics (cache 30s)        │
└────────────────────────────────────────┘
         ↑
         │ Fetches from API
         ↓
┌────────────────────────────────────────┐
│ Component State (useState)              │
│ - Form inputs                          │
│ - Loading states                       │
│ - Validation errors                    │
│ - UI interactions                      │
└────────────────────────────────────────┘
```

### Backend State Management

```
Stateless API (no persistent DB yet)
    ↓
Ephemeral In-Memory State
    ├─ Rate limit counters (reset hourly)
    ├─ Nonce tracking (per-user)
    └─ Request logs (for debugging)
    ↓
Blockchain as Source of Truth
    ├─ User USDC balance (on-chain)
    ├─ User nonce (from relay contract)
    ├─ Transaction history (via events)
    └─ Relayer reserves (on-chain balance)
```

---

## 🚀 Scaling Considerations

### Current Limitations (Phase 1)

```
Single Relayer Bottleneck
    ↓
In-Memory Rate Limiting (single process)
    ↓
No Distributed State
    ↓
RPC Rate Limits (public node)
```

### Phase 2: Scaling Solution

```
Load Balancer
    ↓
Multiple Relayer Instances
    ├─ Relayer A (primary key)
    ├─ Relayer B (backup key)
    └─ Relayer C (spare capacity)
    ↓
Redis Cluster
    ├─ Distributed rate limiting
    ├─ Nonce sequencing
    └─ Transaction queue
    ↓
RPC Provider (Private)
    ├─ Faster response times
    ├─ Higher rate limits
    └─ Better uptime SLA
```

### Phase 3: Decentralized Relayers

```
Permissioned Relayer Network
    ├─ Multiple independent operators
    ├─ Slashing mechanics for misbehavior
    ├─ Revenue sharing model
    └─ Governance (DAO)
    ↓
Off-Chain Coordinator
    ├─ Routes requests to cheapest relayer
    ├─ Handles nonce management
    └─ Settles batches on-chain
```

---

## 📊 Monitoring & Observability

### Logging Strategy

```typescript
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:standard',
      ignore: 'pid,hostname'
    }
  }
});

// Structured logs
logger.info({
  event: 'tx_executed',
  userAddress,
  target,
  gasUsed,
  usdcCharged,
  duration: Date.now() - startTime
});
```

### Metrics to Track

- **Relayer Health**: CRO balance, USDC reserves, gas price, uptime
- **Transaction Volume**: Requests/hour, success rate, average cost
- **Performance**: Response times, P95/P99 latencies
- **Errors**: Invalid signatures, insufficient balance, RPC failures
- **Revenue**: USDC facilitated, fees collected

---

## 🔗 External Integrations

### Cronos Testnet RPC

```
https://evm-t3.cronos.org
  ├─ JSON-RPC for contract calls
  ├─ Event listening via WebSocket
  └─ Rate limits: ~100 req/s per IP
```

### Smart Contracts (On-Chain)

```
Meta-Transaction Relay Contract
    ├─ executeMetaTx(user, target, calldata, sig, nonce, deadline)
    └─ Emits event: MetaTxExecuted(user, target, success)

USDC Contract (EIP-3009)
    ├─ transferWithAuthorization(...)
    └─ Standard ERC20 + permission mechanism
```

---

## 🧪 Testing Strategy

### Unit Tests
- Signature verification
- Gas estimation calculations
- Rate limiting logic

### Integration Tests
- Full meta-transaction flow
- Payment settlement
- Error handling

### E2E Tests (Testnet)
- Real wallet connection
- Actual blockchain interaction
- Faucet distribution

---

**Last Updated**: January 5, 2026  
**Architecture Version**: 1.0.0
