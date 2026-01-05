# Security Policy

CroGas prioritizes the security of user funds and data. This document outlines security practices, known limitations, and reporting procedures.

---

## 🔐 Current Security Measures

### 1. Relayer Key Management

**Encryption**: AES-256
```typescript
// Private key is encrypted at rest
RELAYER_PRIVATE_KEY_ENCRYPTED = "encrypted-hex-string"

// Decrypted only in memory at startup, never persisted to disk
const decrypted = crypto.createDecipher('aes-256-cbc', encryptionKey)
  .update(encrypted, 'hex', 'utf8');
```

**No Key Reuse**: Each transaction is independently signed
```typescript
// Each relay operation uses fresh signature
const signature = await walletClient.signTransaction(tx);
```

**Key Rotation**: Can be performed without downtime
```bash
# 1. Generate new key
npm run scripts/generate-keys.js

# 2. Encrypt new key
npm run scripts/encrypt-existing-key.js

# 3. Update in Vercel environment variables
# 4. Restart deployment

# 5. Transfer remaining balance to new relayer address
```

---

### 2. Transaction Validation

**EIP-712 Signature Verification**
- Type-safe message hashing per Ethereum standard
- Domain separator includes chain ID and contract address
- Signature replay prevention via nonce tracking

```typescript
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
  message: { target, calldata, gasLevel, nonce, deadline },
  signature
});

if (recovered !== userAddress) throw new Error('Invalid signature');
```

**Nonce Tracking**
- Each user has independent nonce counter
- Nonce must increment sequentially
- Prevents replay attacks across transactions

```typescript
const storedNonce = await getNonceFromStorage(userAddress);
if (message.nonce !== storedNonce) {
  throw new Error('Nonce mismatch: expected ' + storedNonce + ', got ' + message.nonce);
}
// After tx success:
await incrementNonce(userAddress);
```

**Deadline Enforcement**
- Each request includes Unix timestamp deadline
- Requests older than deadline are rejected
- Recommended: deadline = now + 3600 seconds

```typescript
const now = Math.floor(Date.now() / 1000);
if (message.deadline < now) {
  throw new Error('Request expired');
}
```

---

### 3. Rate Limiting

**Per-Address Throttling**
```typescript
// Default: 100 requests per hour per address
RATE_LIMIT_WINDOW_MS=3600000
RATE_LIMIT_MAX_REQUESTS=100

// Faucet specifically: 5 requests per hour per address
const FAUCET_LIMIT = 5;
const FAUCET_WINDOW = 3600000; // 1 hour
```

**Balance Safeguards**
- Relayer CRO balance verified before each transaction
- Request rejected if insufficient funds for gas
- Prevents relayer insolvency

```typescript
const relayerBalance = await getRelayerBalance();
if (relayerBalance < estimatedGasCost) {
  return res.status(503).json({
    error: 'relayer_insufficient_balance',
    required: estimatedGasCost,
    available: relayerBalance
  });
}
```

---

### 4. Input Validation

**Zod Schema Validation**
```typescript
const requestSchema = z.object({
  target: z.string()
    .regex(/^0x[a-f0-9]{40}$/i, 'Invalid address format'),
  calldata: z.string()
    .startsWith('0x', 'Calldata must be hex-encoded'),
  gasLevel: z.enum(['slow', 'normal', 'fast']),
  signature: z.string()
    .regex(/^0x[a-f0-9]{130}$/i, 'Invalid signature format'),
  deadline: z.number()
    .int()
    .positive('Deadline must be positive Unix timestamp'),
  nonce: z.number()
    .int()
    .nonnegative()
});

const data = requestSchema.parse(req.body);
```

**Calldata Inspection** (Future)
```typescript
// Whitelist pattern (planned for Phase 2)
const ALLOWED_TARGETS = [
  '0xUSDCAddress...',
  '0xDEXAddress...',
  // etc
];

if (!ALLOWED_TARGETS.includes(target)) {
  throw new Error('Target contract not whitelisted');
}
```

---

### 5. Error Handling

**No Information Leakage**
```typescript
// ❌ BAD - Leaks sensitive information
throw new Error(`Relayer key is 0x${relayerAddress}`);

// ✅ GOOD - Generic error message
throw new Error('Relay execution failed');
```

**Structured Error Responses**
```json
{
  "error": "insufficient_balance",
  "message": "User USDC balance insufficient",
  "statusCode": 402,
  "timestamp": "2026-01-05T12:00:00Z"
}
```

---

## ⚠️ Known Limitations

### Single Relayer (Phase 1)

**Risk**: Single point of failure
```
If relayer account is compromised:
├─ Attacker can execute arbitrary transactions
├─ But CANNOT steal user USDC (requires user's signature)
└─ Can only drain relayer's CRO/USDC reserves
```

**Mitigation**:
- Monitor relayer balance closely
- Rotate keys monthly
- Keep reserves minimal
- Have backup relayer ready

**Solution (Phase 2)**:
- Multi-signature relayer authority
- Decentralized relayer network
- Insurance pool for compromises

---

### In-Memory Rate Limiting (Single Process)

**Risk**: No distributed state across multiple instances
```
Current architecture:
  Single Vercel Serverless Function → In-Memory State

Limitation:
  - Each function invocation has separate memory
  - Rate limits not enforced across instances
  - Function restart clears limits
```

**Mitigation**:
- Deploy as single instance initially
- Monitor request volume
- Cap max concurrent requests

**Solution (Phase 2)**:
- Redis-based rate limiting
- Distributed nonce tracking
- Persistent request logs

---

### Public RPC Endpoint (Testnet)

**Risk**: Rate limits and potential downtime
```
Using public RPC: https://evm-t3.cronos.org
├─ ~100 requests/second per IP
├─ Subject to provider's rate changes
└─ No guaranteed uptime SLA
```

**Mitigation**:
- Cache responses where possible
- Implement retry logic with exponential backoff
- Monitor RPC health

**Solution (Production)**:
- Use private RPC endpoint (QuickNode, Alchemy, etc.)
- Subscribe to Cronos's paid RPC tier
- Set up RPC fallback/redundancy

---

### No Insurance Pool (Phase 1)

**Risk**: Failed transactions consume gas without execution
```
Current behavior:
  If relay fails on-chain:
    ├─ User still pays gas to relayer
    └─ Transaction has no effect

User protection:
  - Relayer absorbs cost (current policy)
  - May be unsustainable long-term
```

**Solution (Phase 3)**:
- Insurance pool funded by facilitation fees
- Reimburse users for failed transactions
- Slashing mechanics for relayer misbehavior

---

## 🔍 Security Audit Checklist

### Signature Verification
- [ ] EIP-712 domain matches between frontend and backend
- [ ] Chain ID included in domain separator
- [ ] Contract address included in domain separator
- [ ] Signature verification uses correct algorithm
- [ ] Nonce is checked before signature verification

### Nonce Management
- [ ] Nonce storage is persistent (not lost on restart)
- [ ] Nonce must increment sequentially (no gaps, no duplicates)
- [ ] Nonce is independent per user
- [ ] Nonce increment happens only after successful execution

### Rate Limiting
- [ ] In-memory state properly initialized
- [ ] Rate limit window is enforced
- [ ] Rate limit is per-address (not global)
- [ ] Rate limit applies to faucet requests
- [ ] Rate limit applies to meta-tx requests

### Balance Checks
- [ ] User USDC balance checked before relay
- [ ] Relayer CRO balance checked before relay
- [ ] Sufficient gas buffer allocated (not exact estimate)
- [ ] Balance checks use fresh on-chain read

### Error Handling
- [ ] No secrets leaked in error messages
- [ ] Generic error messages for security issues
- [ ] Proper HTTP status codes (402 for payment, 429 for rate limit)
- [ ] Errors logged for debugging

---

## 🚨 Reporting Security Issues

### Do NOT open public GitHub issues for security vulnerabilities

Instead, email security details to:
```
[security-contact-email-coming]
```

Include:
1. **Description**: What is the vulnerability?
2. **Impact**: What can an attacker accomplish?
3. **Reproduction**: Step-by-step to trigger the issue
4. **Suggested Fix**: (Optional) your proposed solution
5. **Timeline**: How urgent is this?

### Security Response SLA

| Severity | Response Time | Fix Timeline |
|----------|---------------|--------------|
| Critical | 1 hour | 24 hours |
| High | 4 hours | 1 week |
| Medium | 1 day | 2 weeks |
| Low | 3 days | 1 month |

**Critical**: Funds can be stolen, system is down, RCE vulnerability
**High**: Data leakage, unauthorized access, signature bypass
**Medium**: DoS possible, information disclosure, edge case bugs
**Low**: Minor issues, cosmetic bugs, non-security related

### Disclosure Policy

- We will work with you to fix the issue
- Please give us time before public disclosure
- Public credit given upon request
- Acknowledgment in security.md

---

## 🔐 Best Practices for Users

### When Using CroGas

1. **Verify contract address** before executing
   - Frontend should display target contract
   - Confirm it matches your intention
   - Check on Cronoscan if unsure

2. **Use reasonable gas tiers**
   - `slow`: Fine for non-urgent transactions
   - `normal`: Default for most transactions
   - `fast`: Only when time-critical

3. **Monitor balances**
   - Keep some USDC in wallet for fees
   - Don't rely on exact balance (need buffer for gas)
   - Check USDC allowance before complex operations

4. **Test with small amounts**
   - Test with 1-10 USDC first
   - Verify behavior on testnet
   - Increase amounts after verification

5. **Keep wallet secure**
   - Never share your private key
   - Use hardware wallet if possible
   - Don't sign messages you don't understand

---

## 📋 Security Roadmap

### Phase 1 (Current) ✅
- [x] AES-256 key encryption
- [x] EIP-712 signature verification
- [x] Nonce-based replay protection
- [x] Rate limiting per address
- [x] Input validation with Zod

### Phase 2 🔄
- [ ] Multi-signature relayer authority
- [ ] Redis-based rate limiting
- [ ] Distributed nonce tracking
- [ ] Private RPC endpoint
- [ ] Comprehensive security audit (3rd party)
- [ ] Bug bounty program

### Phase 3
- [ ] Decentralized relayer network
- [ ] DAO-based governance
- [ ] Insurance pool mechanism
- [ ] Formal verification of contracts
- [ ] Regular penetration testing

---

## 📚 References

### Security Standards
- [EIP-712: Typed Data Hashing](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-3009: Transfer with Authorization](https://eips.ethereum.org/EIPS/eip-3009)
- [ERC-2771: Meta-Transaction Standard](https://eips.ethereum.org/EIPS/erc-2771)
- [OWASP API Security](https://owasp.org/www-project-api-security/)

### Tools & Services
- [Immunefi: Bug Bounty Platform](https://immunefi.com)
- [OpenZeppelin: Audit Services](https://openzeppelin.com)
- [Consensys Diligence: Security](https://consensys.net/diligence/)

### Learning Resources
- [Smart Contract Security Guide](https://secureum.substack.com)
- [Ethereum Development Docs](https://ethereum.org/developers)
- [Web3 Security Best Practices](https://blog.openzeppelin.com)

---

## 🙏 Security Contributors

We thank the security researchers who help keep CroGas safe:

- [Coming soon]

---

**Last Updated**: January 5, 2026  
**Security Version**: 1.0.0
