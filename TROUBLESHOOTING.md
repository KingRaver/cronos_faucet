# Troubleshooting Guide

Common issues, diagnostics, and solutions for CroGas users and developers.

---

## 🔧 Quick Diagnostics

### Is CroGas Working?

```bash
# 1. Check health endpoint
curl https://cro-gas.vercel.app/api/health | jq

# Expected response:
{
  "status": "healthy",
  "relayer": { "balance": { "cro": "50.5", "usdcReserves": "1000.25" } },
  "network": { "blockNumber": 1234567 }
}

# 2. If health fails, CroGas is down
# 3. If health succeeds, proceed to specific issue
```

---

## 👤 User Issues

### "Wallet not connecting"

**Symptoms**: Can't connect wallet to CroGas UI

**Diagnosis**:
```javascript
// Check if Wagmi/Viem is configured
console.log(window.ethereum); // Should exist

// Check if MetaMask is installed
if (!window.ethereum) console.log('MetaMask not installed');

// Check network
const chainId = await window.ethereum.request({ method: 'eth_chainId' });
console.log(chainId); // Should be 0x152 (338 in hex)
```

**Solutions**:

1. **Install MetaMask**
   - Go to [metamask.io](https://metamask.io)
   - Click "Install MetaMask"
   - Follow browser instructions

2. **Switch to Cronos Testnet**
   ```javascript
   // Manually add Cronos testnet if not present
   await window.ethereum.request({
     method: 'wallet_addEthereumChain',
     params: [{
       chainId: '0x152',
       chainName: 'Cronos Testnet',
       rpcUrls: ['https://evm-t3.cronos.org'],
       nativeCurrency: { name: 'CRO', symbol: 'CRO', decimals: 18 },
       blockExplorerUrls: ['https://cronoscan.com']
     }]
   });
   ```

3. **Clear browser cache**
   ```bash
   # Press Ctrl+Shift+Delete (Windows) or Cmd+Shift+Delete (Mac)
   # Or use browser DevTools → Storage → Clear All
   ```

---

### "Insufficient USDC balance" error

**Symptoms**: 
```json
{
  "error": "insufficient_balance",
  "message": "User's USDC balance insufficient for transaction"
}
```

**Diagnosis**:
```bash
# Check your USDC balance on Cronoscan
# https://cronoscan.com/token/0xc21223249ca28397b5541df5ae57ea94d3e8346e/holders

# Or check in Cronos Scan:
# 1. Go to cronoscan.com
# 2. Search your address
# 3. Look for USDC token balance
```

**Solutions**:

1. **Get free testnet USDC**
   ```bash
   # Open CroGas and use the faucet
   # Dashboard → Request USDC
   # Amount: 100 USDC (free)
   ```

2. **Check if transaction had time to confirm**
   - Faucet transfers take ~2 seconds
   - Wait 5 seconds before retrying
   - Check Cronoscan to verify receipt

3. **If faucet is empty**
   - Contact team in Discord
   - Request temporary USDC allocation
   - Or use testnet faucet: [cronos.org/faucet](https://cronos.org/faucet)

---

### "Transaction failed" (generic error)

**Symptoms**:
```json
{
  "error": "relay_execution_failed",
  "message": "Transaction execution failed on-chain"
}
```

**Diagnosis**:

1. **Check transaction on Cronoscan**
   ```bash
   # Error response includes txHash
   # Go to: https://cronoscan.com/tx/0x...
   # Look at "Revert reason" for details
   ```

2. **Common revert reasons**
   - "ERC20: transfer amount exceeds balance" → Not enough token
   - "Allowance exceeded" → Token not approved for target contract
   - "Invalid signature" → Message was tampered with
   - "Nonce too low" → You already sent this transaction

3. **Check calldata validity**
   ```javascript
   // Verify you encoded the function correctly
   // Use ethers.js or web3.js to validate:
   const iface = new ethers.utils.Interface(ABI);
   const calldata = iface.encodeFunctionData('functionName', [args]);
   console.log(calldata); // Should start with 0x and be hex
   ```

**Solutions**:

1. **For token approval issues**
   ```javascript
   // First, approve the target contract to spend your tokens
   // Then retry the transaction
   ```

2. **For invalid calldata**
   ```bash
   # Double-check:
   # - Function name is correct (case-sensitive)
   # - All parameters are correct type
   # - All parameters are correctly encoded
   ```

3. **For nonce conflicts**
   ```bash
   # Wait for previous transaction to finish
   # Then try again with fresh data
   ```

---

### "Rate limited" error

**Symptoms**:
```json
{
  "error": "rate_limited",
  "message": "Address has exceeded 100 requests/hour limit",
  "retryAfter": 3600
}
```

**Solution**:
- Wait the number of seconds in `retryAfter`
- Use a different wallet address
- Contact team if limit is too restrictive

**Rate limits**:
- `/faucet/usdc`: 5 requests per hour per address
- `/x402/facilitate`: 100 requests per hour per address

---

## 💻 Developer Issues

### "Invalid signature" error

**Symptoms**:
```json
{
  "error": "invalid_signature",
  "message": "Signature verification failed"
}
```

**Diagnosis**:

```typescript
// Check 1: Are you using correct EIP-712 domain?
const domain = {
  name: 'CroGas',           // Must match backend
  version: '1',             // Must match backend
  chainId: 338,             // Must match Cronos testnet
  verifyingContract: '0x...' // Must match relay contract
};

// Check 2: Are all message fields present?
const message = {
  target: '0x...',          // Required
  calldata: '0x...',        // Required
  gasLevel: 'normal',       // Required
  nonce: 1,                 // Required
  deadline: 1704465000      // Required
};

// Check 3: Did you sign the correct message?
const signature = await signTypedDataAsync({
  domain, types, primaryType: 'MetaTransaction', message
});
```

**Common mistakes**:

1. **Wrong chain ID**
   ```typescript
   // ❌ Wrong
   chainId: 1  // Ethereum mainnet

   // ✅ Correct
   chainId: 338  // Cronos testnet
   ```

2. **Mismatched domain**
   ```typescript
   // Frontend domain must match backend domain exactly
   // Check in: crogas_backend/src/config/viem.ts
   ```

3. **Unsigned calldata**
   ```typescript
   // ❌ Wrong - unsigned
   const message = { target, calldata: '0x', gasLevel, nonce, deadline };

   // ✅ Correct - actual function call
   const iface = new ethers.Interface(ABI);
   const calldata = iface.encodeFunctionData('transfer', [to, amount]);
   ```

**Solutions**:

1. **Verify domain in browser console**
   ```javascript
   // In frontend code, log the domain before signing
   console.log('Domain:', domain);
   console.log('Message:', message);
   // Then compare with backend constants
   ```

2. **Use test vectors**
   ```bash
   # CroGas provides test signatures in docs
   # Compare your signature against known-good example
   ```

3. **Check Wagmi configuration**
   ```typescript
   // Verify Wagmi is configured for Cronos testnet
   import { cronos } from 'viem/chains';
   
   const config = getConfig();
   console.log(config.chains); // Should include cronos
   ```

---

### "RPC connection failed" error

**Symptoms**:
```json
{
  "error": "rpc_connection_failed",
  "message": "Unable to connect to evm-t3.cronos.org"
}
```

**Diagnosis**:

```bash
# Test RPC endpoint directly
curl -X POST https://evm-t3.cronos.org \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "eth_blockNumber",
    "params": [],
    "id": 1
  }' | jq

# Expected response:
# { "jsonrpc": "2.0", "result": "0x...", "id": 1 }

# If you get an error, RPC is down or unreachable
```

**Causes**:

1. **RPC endpoint is down**
   - Cronos testnet maintenance
   - Temporary service outage
   - Check [cronos.org status](https://status.cronos.org)

2. **Network connectivity issue**
   ```bash
   # Test connectivity
   ping evm-t3.cronos.org
   
   # If no response, check your internet connection
   ```

3. **Firewall/proxy blocking**
   - Corporate firewall blocking blockchain RPC
   - VPN required
   - Contact your network admin

**Solutions**:

1. **Wait for RPC recovery**
   - Check Cronos status page
   - Retry after 30 seconds

2. **Use backup RPC** (temporary)
   ```typescript
   // In .env or config
   CRONOS_RPC_URL=https://evm.cronos.org/  // Alternate endpoint
   ```

3. **Report persistent issues**
   ```bash
   # Contact Cronos support
   # Discord: discord.gg/cronos
   ```

---

### "Relayer insufficient balance" error

**Symptoms**:
```json
{
  "error": "relayer_insufficient_balance",
  "message": "Relayer has insufficient CRO reserves for gas",
  "required": "0.5",
  "available": "0.05"
}
```

**Solutions**:

1. **Relayer is low on CRO**
   - Contact team to fund relayer
   - Transactions cannot proceed until funded
   - Check expected resolution time

2. **Try lower gas tier (temporary)**
   ```javascript
   // Use 'slow' tier instead of 'fast'
   // Reduces gas requirement temporarily
   ```

3. **Estimated impact duration**
   - Team usually refunds within 1 hour
   - Critical services expedited

---

## 🔍 Debugging Tools

### Browser DevTools

```javascript
// 1. Check network requests
// DevTools → Network → Filter by 'api'
// Look at request/response for /x402/facilitate

// 2. Monitor console errors
// DevTools → Console
// Look for JavaScript errors or warnings

// 3. Inspect local storage
// DevTools → Application → Local Storage
// Check theme, gasLevel, userPreferences

// 4. Check wallet connection
console.log('Account:', useAccount());
console.log('Chain:', useNetwork());
console.log('Is connected:', useAccount().isConnected);
```

### Backend Logs

```bash
# View production logs (Vercel)
vercel logs --follow

# Filter by endpoint
vercel logs | grep '/x402/facilitate'

# Filter by error
vercel logs | grep -i error

# Filter by user address
vercel logs | grep '0x1234567890...'

# Export for analysis
vercel logs > crogas-logs.txt
```

### Blockchain Explorer (Cronoscan)

```
https://cronoscan.com

# Search for:
# 1. Your wallet address
#    ├─ USDC balance
#    ├─ CRO balance
#    └─ Transaction history
#
# 2. Transaction hash
#    ├─ Input data
#    ├─ Execution status
#    ├─ Gas used
#    └─ Revert reason (if failed)
#
# 3. Relayer address
#    ├─ Current balance
#    ├─ Transaction history
#    └─ Token balances
```

---

## 📋 Debugging Checklist

### For "Invalid Signature"
- [ ] Are you signing the correct message?
- [ ] Does domain match backend config?
- [ ] Is chain ID 338?
- [ ] Are all message fields present?
- [ ] Did you use signTypedDataAsync (not signMessage)?
- [ ] Is nonce correct?
- [ ] Is deadline in future?

### For "Insufficient Balance"
- [ ] Check Cronoscan for actual USDC balance
- [ ] Wait for faucet confirmation (2-5 seconds)
- [ ] Try again with reduced amount
- [ ] Request more USDC if needed

### For "Relay Failed"
- [ ] Check Cronoscan for revert reason
- [ ] Verify calldata is correct
- [ ] Verify target contract is legitimate
- [ ] Ensure token allowances are set
- [ ] Try with smaller amount first

### For "RPC Error"
- [ ] Check Cronos status page
- [ ] Verify internet connectivity
- [ ] Try alternate RPC endpoint
- [ ] Wait and retry

### For "Rate Limited"
- [ ] Check retryAfter value
- [ ] Wait full duration before retrying
- [ ] Use different address if testing
- [ ] Contact team if limit too strict

---

## 🆘 Getting Help

### Resources
- **Documentation**: [README.md](README.md), [API.md](API.md), [ARCHITECTURE.md](ARCHITECTURE.md)
- **Security Info**: [SECURITY.md](SECURITY.md)
- **Deployment**: [DEPLOYMENT.md](DEPLOYMENT.md)
- **Contributing**: [CONTRIBUTING.md](CONTRIBUTING.md)

### Community
- **GitHub Issues**: [Report bugs](https://github.com/KingRaver/CroGas/issues)
- **GitHub Discussions**: [Ask questions](https://github.com/KingRaver/CroGas/discussions)
- **Discord**: [Community chat] (coming soon)
- **Twitter**: [@CroGasRelay] (coming soon)

### Emergency Support
- **Relayer Down**: [Contact info coming]
- **Security Issue**: security@[domain] (responsible disclosure)
- **Urgent Help**: [Escalation procedure coming]

---

## 📝 Logging Issues

When reporting a bug, include:

1. **What you were trying to do**
   ```
   "I was trying to execute a token transfer via /x402/facilitate"
   ```

2. **What happened (actual)**
   ```
   "Got error: invalid_signature"
   ```

3. **What you expected**
   ```
   "Expected transaction to succeed and return txHash"
   ```

4. **Steps to reproduce**
   ```
   1. Connect wallet to CroGas
   2. Fill target: 0x...
   3. Fill calldata: 0x...
   4. Click Execute
   5. Sign message
   6. Error occurs
   ```

5. **Your environment**
   ```
   Browser: Chrome 120
   Wallet: MetaMask 10.34
   Network: Cronos Testnet
   OS: macOS 14
   ```

6. **Error message (full)**
   ```json
   {
     "error": "invalid_signature",
     "message": "Signature verification failed"
   }
   ```

7. **Transaction hash (if applicable)**
   ```
   0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890
   ```

---

**Last Updated**: January 5, 2026  
**Troubleshooting Version**: 1.0.0
