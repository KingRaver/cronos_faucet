# CroGas API Reference

Complete API documentation for CroGas backend endpoints. All endpoints return JSON and are available at `/api/*` paths.

---

## 📡 Base URL

**Development:**
```
http://localhost:3000/api
```

**Production:**
```
https://cro-gas.vercel.app/api
```

---

## 🔐 Authentication

All endpoints are **publicly accessible** on testnet. Production will require API key authentication (planned for Phase 2).

---

## 📋 Endpoints

### 1. GET `/health`

Health check endpoint. Returns relayer status and network connectivity.

**Request:**
```bash
curl -X GET http://localhost:3000/api/health
```

**Response (200 OK):**
```json
{
  "status": "healthy",
  "relayer": {
    "address": "0x1234567890123456789012345678901234567890",
    "balance": {
      "cro": "50.5",
      "usdcReserves": "1000.25"
    }
  },
  "network": {
    "chain": "cronos-testnet",
    "chainId": 338,
    "rpcUrl": "https://evm-t3.cronos.org",
    "gasPrice": "5000000000",
    "blockNumber": 1234567
  },
  "timestamp": "2026-01-05T11:18:00Z"
}
```

**Error (503 Service Unavailable):**
```json
{
  "error": "RPC connection failed",
  "details": "Unable to connect to evm-t3.cronos.org"
}
```

---

### 2. POST `/faucet/usdc`

Request testnet USDC tokens. Rate-limited to prevent abuse.

**Request:**
```bash
curl -X POST http://localhost:3000/api/faucet/usdc \
  -H "Content-Type: application/json" \
  -d '{
    "address": "0x1234567890123456789012345678901234567890",
    "amount": "100"
  }'
```

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `address` | string | ✓ | Recipient wallet address (0x prefixed) |
| `amount` | string | ✓ | Amount of USDC to receive (decimal string) |

**Response (200 OK):**
```json
{
  "success": true,
  "txHash": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
  "recipient": "0x1234567890123456789012345678901234567890",
  "amount": "100",
  "explorerUrl": "https://cronoscan.com/tx/0xabcdef...",
  "status": "pending",
  "estimatedConfirmation": "2026-01-05T11:19:00Z"
}
```

**Error (400 Bad Request):**
```json
{
  "error": "invalid_address",
  "message": "Address must be a valid 0x-prefixed hex string"
}
```

**Error (429 Too Many Requests):**
```json
{
  "error": "rate_limited",
  "message": "Maximum 5 requests per hour per address",
  "retryAfter": 3600
}
```

**Error (503 Service Unavailable):**
```json
{
  "error": "faucet_empty",
  "message": "Faucet has insufficient USDC reserves"
}
```

---

### 3. POST `/x402/facilitate`

Execute a meta-transaction and settle payment in USDC via x402 protocol.

**This is the core CroGas endpoint.**

**Request:**
```bash
curl -X POST http://localhost:3000/api/x402/facilitate \
  -H "Content-Type: application/json" \
  -d '{
    "target": "0x1234567890123456789012345678901234567890",
    "calldata": "0xa9059cbb0000000000000000000000001234567890123456789012345678901234567890000000000000000000000000000000000000000000000056bc75e2d630eb20000",
    "gasLevel": "normal",
    "userAddress": "0xabcdefabcdefabcdefabcdefabcdefabcdefabcd",
    "signature": "0x1234567890...",
    "deadline": 1704465000,
    "nonce": 1
  }'
```

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `target` | string | ✓ | Target contract address (0x prefixed) |
| `calldata` | string | ✓ | Encoded function call (0x prefixed hex) |
| `gasLevel` | string | ✓ | Gas tier: `slow`, `normal`, or `fast` |
| `userAddress` | string | ✓ | User's wallet address (for USDC debit) |
| `signature` | string | ✓ | EIP-712 signed message from user |
| `deadline` | number | ✓ | Unix timestamp (current + 3600s recommended) |
| `nonce` | number | ✓ | User's transaction nonce (increments per tx) |

**Response (200 OK):**
```json
{
  "success": true,
  "transaction": {
    "txHash": "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890",
    "explorerUrl": "https://cronoscan.com/tx/0xabcdef...",
    "status": "pending",
    "blockNumber": null,
    "confirmations": 0
  },
  "execution": {
    "target": "0x1234567890123456789012345678901234567890",
    "gasUsed": 78932,
    "gasPrice": "5000000000",
    "gasLevel": "normal"
  },
  "payment": {
    "amount": "0.394660",
    "currency": "USDC",
    "breakdown": {
      "baseGasCost": "0.389660",
      "facilitatorFee": "0.005000"
    }
  },
  "timestamp": "2026-01-05T11:18:30Z",
  "estimatedConfirmation": "2026-01-05T11:19:00Z"
}
```

**Error (400 Bad Request):**
```json
{
  "error": "invalid_calldata",
  "message": "Calldata must be hex-encoded function call"
}
```

**Error (402 Payment Required):**
```json
{
  "error": "insufficient_balance",
  "message": "User's USDC balance insufficient for transaction",
  "required": "10.50",
  "available": "5.25"
}
```

**Error (429 Too Many Requests):**
```json
{
  "error": "rate_limited",
  "message": "Address has exceeded 100 requests/hour limit",
  "retryAfter": 1800
}
```

**Error (503 Service Unavailable):**
```json
{
  "error": "relayer_unavailable",
  "message": "Relayer has insufficient CRO reserves for gas"
}
```

---

## 🔄 Request/Response Patterns

### Gas Level Pricing

Gas charges vary by tier. Use these multipliers:

```
Slow (économique):     0.8x base gas price
Normal (standard):     1.0x base gas price
Fast (prioritaire):    1.3x base gas price
```

**Example calculation:**
```
gasUsed = 78,932 wei
gasPrice = 5,000,000,000 wei/gas
gasLevel = "normal" (multiplier = 1.0)
facilitatorFee = 1% of gas cost

baseCost = (78,932 × 5,000,000,000 × 1.0) / 10^18 = 0.39466 USDC
facilitatorFee = 0.39466 × 0.01 = 0.00395 USDC
totalCost = 0.39466 + 0.00395 = 0.39861 USDC
```

### Error Response Format

All errors follow consistent structure:

```json
{
  "error": "error_code",
  "message": "Human-readable description",
  "statusCode": 400,
  "timestamp": "2026-01-05T11:18:00Z",
  "details": {
    "field": "optional detailed information"
  }
}
```

### Status Codes

| Code | Meaning | When It Occurs |
|------|---------|----------------|
| 200 | Success | Transaction relay successful |
| 400 | Bad Request | Invalid input parameters |
| 402 | Payment Required | Insufficient balance for payment |
| 429 | Rate Limited | Too many requests from address |
| 500 | Server Error | Unexpected server error |
| 503 | Service Unavailable | Relayer or network issue |

---

## 🔑 EIP-712 Signature Format

For the `/x402/facilitate` endpoint, the signature must be EIP-712 compliant.

**TypedData Structure:**
```javascript
{
  types: {
    EIP712Domain: [
      { name: 'name', type: 'string' },
      { name: 'version', type: 'string' },
      { name: 'chainId', type: 'uint256' },
      { name: 'verifyingContract', type: 'address' }
    ],
    MetaTransaction: [
      { name: 'target', type: 'address' },
      { name: 'calldata', type: 'bytes' },
      { name: 'gasLevel', type: 'string' },
      { name: 'deadline', type: 'uint256' },
      { name: 'nonce', type: 'uint256' }
    ]
  },
  primaryType: 'MetaTransaction',
  domain: {
    name: 'CroGas',
    version: '1',
    chainId: 338,
    verifyingContract: '0x0000000000000000000000000000000000000000'
  },
  message: {
    target: '0x...',
    calldata: '0x...',
    gasLevel: 'normal',
    deadline: 1704465000,
    nonce: 1
  }
}
```

**Using Wagmi (Frontend):**
```typescript
import { useSignTypedData } from 'wagmi';

const { signTypedDataAsync } = useSignTypedData();

const signature = await signTypedDataAsync({
  domain: { ... },
  types: { ... },
  primaryType: 'MetaTransaction',
  message: { ... }
});
```

---

## 📊 Example Workflows

### Workflow 1: Get USDC from Faucet

```bash
# 1. Request testnet USDC
curl -X POST http://localhost:3000/api/faucet/usdc \
  -H "Content-Type: application/json" \
  -d '{
    "address": "0x1234567890123456789012345678901234567890",
    "amount": "100"
  }'

# Response:
# {
#   "txHash": "0xabc...",
#   "status": "pending"
# }

# 2. Wait for confirmation (2 seconds typical)
sleep 3

# 3. Verify balance on Cronoscan
# https://cronoscan.com/token/0x..../0x1234567890123456789012345678901234567890
```

### Workflow 2: Execute Meta-Transaction

```bash
# 1. Sign message with Wagmi (frontend code)
const signature = await signTypedDataAsync({...});

# 2. Call x402/facilitate endpoint
curl -X POST http://localhost:3000/api/x402/facilitate \
  -H "Content-Type: application/json" \
  -d '{
    "target": "0x...",
    "calldata": "0x...",
    "gasLevel": "normal",
    "userAddress": "0x...",
    "signature": "'$signature'",
    "deadline": 1704465000,
    "nonce": 1
  }'

# Response:
# {
#   "txHash": "0xdef...",
#   "status": "pending",
#   "payment": {
#     "amount": "0.39466",
#     "currency": "USDC"
#   }
# }

# 3. Monitor transaction
# https://cronoscan.com/tx/0xdef...
```

---

## 🛠️ Testing Endpoints

### Using cURL

```bash
# Health check
curl http://localhost:3000/api/health | jq

# Faucet request
curl -X POST http://localhost:3000/api/faucet/usdc \
  -H "Content-Type: application/json" \
  -d '{"address":"0x...","amount":"100"}' | jq
```

### Using Postman

1. Import collection from `docs/postman-collection.json` (if provided)
2. Set environment variables:
   - `BASE_URL` = `http://localhost:3000/api`
   - `USER_ADDRESS` = your test address
3. Run requests with "Send" button

### Using Node.js

```javascript
const response = await fetch('http://localhost:3000/api/health');
const data = await response.json();
console.log(data);
```

### Using Python

```python
import requests

response = requests.get('http://localhost:3000/api/health')
print(response.json())
```

---

## 📈 Rate Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/faucet/usdc` | 5 requests | 1 hour per address |
| `/x402/facilitate` | 100 requests | 1 hour per address |
| `/health` | Unlimited | — |

**Rate limit response:**
```json
{
  "error": "rate_limited",
  "retryAfter": 3600
}
```

Use `retryAfter` header to determine when to retry:
```bash
curl -i http://localhost:3000/api/faucet/usdc
# Retry-After: 3600
```

---

## 🔍 Debugging

### Enable Verbose Logging

```bash
DEBUG=crogas:* npm run dev
```

### Check Request/Response

```bash
# See full request/response details
curl -v http://localhost:3000/api/health

# Pretty-print JSON
curl http://localhost:3000/api/health | jq .
```

### Common Issues

**"RPC connection failed"**
- Check `CRONOS_RPC_URL` in `.env`
- Verify internet connection
- Ensure RPC URL is valid

**"Invalid signature"**
- Verify EIP-712 domain config matches backend
- Ensure signature is fresh (check deadline)
- Confirm user signed correct message

**"Rate limited"**
- Wait for `retryAfter` seconds
- Use different address for testing
- Contact team for rate limit increase

---

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/KingRaver/CroGas/issues)
- **Discussions**: [GitHub Discussions](https://github.com/KingRaver/CroGas/discussions)
- **Email**: [support contact - coming soon]

---

**API Version**: 1.0.0  
**Last Updated**: January 5, 2026
