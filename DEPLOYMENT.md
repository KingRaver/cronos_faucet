# Deployment Guide

Complete instructions for deploying CroGas to production on Vercel.

---

## 📋 Pre-Deployment Checklist

### Code Quality
- [ ] All tests passing (`npm run test`)
- [ ] No linting errors (`npm run lint`)
- [ ] TypeScript strict mode passes (`npm run build`)
- [ ] Environment variables documented
- [ ] Secrets not committed to git

### Security
- [ ] Private keys encrypted (AES-256)
- [ ] Rate limiting configured
- [ ] CORS headers set correctly
- [ ] Input validation on all endpoints
- [ ] Error messages don't leak sensitive info

### Testing
- [ ] Tested on testnet locally
- [ ] Verified relayer balance sufficient
- [ ] Tested faucet distribution
- [ ] Tested meta-transaction flow end-to-end

---

## 🚀 Vercel Deployment (Production)

### Step 1: Prerequisites

```bash
# Install Vercel CLI
npm install -g vercel

# Login to Vercel
vercel login

# Verify you're in the repo root
cd /path/to/CroGas
```

### Step 2: Configure Environment Variables

Create production environment variables in Vercel Dashboard:

1. Go to [vercel.com/dashboard](https://vercel.com/dashboard)
2. Select your CroGas project
3. Settings → Environment Variables
4. Add all variables from `.env.example`:

```
# Relayer & Blockchain
RELAYER_PRIVATE_KEY_ENCRYPTED=<your-encrypted-key>
RELAYER_ENCRYPTION_KEY=<32-byte-hex-key>
CRONOS_RPC_URL=https://evm-t3.cronos.org
CRONOS_CHAIN_ID=338

# USDC Configuration
USDC_TOKEN_ADDRESS=0x<mainnet-or-testnet-address>
USDC_DECIMALS=6

# Facilitator Settings
FACILITATOR_FEE_PERCENT=1
GAS_PRICE_MULTIPLIER_SLOW=0.8
GAS_PRICE_MULTIPLIER_NORMAL=1.0
GAS_PRICE_MULTIPLIER_FAST=1.3

# Rate Limiting
RATE_LIMIT_WINDOW_MS=3600000
RATE_LIMIT_MAX_REQUESTS=100

# Node Environment
NODE_ENV=production
```

**Important**: Use `CRONOS_RPC_URL=https://evm-t3.cronos.org` for testnet. For mainnet, use mainnet RPC endpoint.

### Step 3: Deploy

```bash
# Option A: Interactive deployment
vercel

# Option B: Automated deployment (CI/CD)
vercel deploy --prod

# Verify deployment
vercel deployments
```

### Step 4: Post-Deployment Verification

```bash
# Test health endpoint
curl https://cro-gas.vercel.app/api/health

# Test faucet
curl -X POST https://cro-gas.vercel.app/api/faucet/usdc \
  -H "Content-Type: application/json" \
  -d '{"address":"0x...","amount":"100"}'

# Check logs
vercel logs [deployment-url]
```

---

## 🔧 Environment Variable Management

### Encryption Setup

```bash
# Generate 32-byte hex encryption key
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Output: a1b2c3d4e5f6...

# Save to secure location (password manager)
RELAYER_ENCRYPTION_KEY=a1b2c3d4e5f6...
```

### Encrypting Private Key

```bash
# Use provided script
cd crogas_backend/scripts

# Get relayer address from private key
node get-address.js

# Encrypt private key
node encrypt-existing-key.js

# Script will output:
# RELAYER_PRIVATE_KEY_ENCRYPTED=...
# Store this in Vercel environment
```

### Env Variable Validation

```bash
# Test env variables locally before deploying
npm run validate:env

# Should output:
# ✓ RELAYER_PRIVATE_KEY_ENCRYPTED
# ✓ RELAYER_ENCRYPTION_KEY
# ✓ CRONOS_RPC_URL
# ✓ All required vars present
```

---

## 🌐 Custom Domain Setup

### Connect Custom Domain

1. **Buy domain** from registrar (Namecheap, GoDaddy, etc.)
2. **In Vercel Dashboard**:
   - Project Settings → Domains
   - Add domain: `cro-gas.com`
3. **Update DNS** at registrar:
   - Point nameservers to Vercel (provided in dashboard)
   - Or use CNAME pointing to Vercel
4. **Verify**:
   ```bash
   curl https://cro-gas.com/api/health
   ```

---

## 📊 Monitoring & Logging

### Vercel Analytics

```bash
# View real-time logs
vercel logs --follow

# Filter by endpoint
vercel logs | grep '/x402/facilitate'

# Export logs
vercel logs > deployment-logs.txt
```

### Custom Monitoring (Future)

```typescript
// Option 1: Datadog
import dd_trace from 'dd-trace';

dd_trace.init();
dd_trace.use('express', { blacklist: ['/health'] });

// Option 2: Sentry
import * as Sentry from "@sentry/node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  integrations: [
    new Sentry.Integrations.Http({ tracing: true })
  ],
  tracesSampleRate: 0.1
});
```

### Alerting

Set up alerts in Vercel for:
- Deployment failures
- Function errors (500 status)
- High latency (>10s)
- Memory usage >512MB

---

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Vercel

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      
      - run: npm ci
      - run: npm run lint
      - run: npm run test
      - run: npm run build
      
      - name: Deploy to Vercel
        uses: vercel/action@v4
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          github-token: ${{ secrets.GITHUB_TOKEN }}
          vercel-org-id: ${{ secrets.VERCEL_ORG_ID }}
          vercel-project-id: ${{ secrets.VERCEL_PROJECT_ID }}
```

**Setup secrets in GitHub**:
1. Settings → Secrets and variables → Actions
2. Add:
   - `VERCEL_TOKEN` (from [vercel.com/account/tokens](https://vercel.com/account/tokens))
   - `VERCEL_ORG_ID` (from Vercel dashboard)
   - `VERCEL_PROJECT_ID` (from project settings)

---

## 🔐 Security Hardening

### Rate Limiting

```bash
# Production rate limits (stricter than dev)
RATE_LIMIT_WINDOW_MS=3600000      # 1 hour window
RATE_LIMIT_MAX_REQUESTS=100       # 100 requests per hour per address
```

### CORS Configuration

```typescript
// Backend Express app
app.use(cors({
  origin: ['https://cro-gas.com', 'https://cro-gas.vercel.app'],
  credentials: true,
  methods: ['GET', 'POST'],
  allowedHeaders: ['Content-Type']
}));
```

### Headers Security

```typescript
// Security headers middleware
app.use((req, res, next) => {
  res.setHeader('X-Content-Type-Options', 'nosniff');
  res.setHeader('X-Frame-Options', 'DENY');
  res.setHeader('X-XSS-Protection', '1; mode=block');
  res.setHeader('Strict-Transport-Security', 'max-age=31536000');
  next();
});
```

---

## 🚨 Rollback Procedure

### If Deployment Fails

```bash
# View previous deployments
vercel deployments

# Rollback to previous version
vercel promote <deployment-id>

# Verify rollback
curl https://cro-gas.vercel.app/api/health
```

### Manual Rollback (Git)

```bash
# Revert commit
git revert <commit-id>
git push origin main

# Vercel auto-deploys from main branch
```

---

## 📈 Scaling to Mainnet

### Network Changes

```bash
# Testnet
CRONOS_RPC_URL=https://evm-t3.cronos.org
CRONOS_CHAIN_ID=338

# Mainnet (when ready)
CRONOS_RPC_URL=https://mainnet.cronos.org
CRONOS_CHAIN_ID=25
```

### Contract Deployment

```bash
# 1. Deploy Meta-Transaction Relay contract
npx hardhat deploy --network cronos-mainnet

# 2. Deploy USDC integration (or use existing contract)

# 3. Fund relayer account with CRO + USDC
# Amount depends on expected transaction volume

# 4. Update contract addresses in .env
RELAY_CONTRACT_ADDRESS=0x...
USDC_TOKEN_ADDRESS=0x... (mainnet version)
```

### Testing Mainnet

```bash
# Test with small amounts first
FACILITATOR_FEE_PERCENT=0.5  # Reduce fees for testing

# Monitor metrics closely
npm run logs:live

# Gradually increase rate limits as confidence grows
```

---

## 🐛 Debugging Production Issues

### Common Issues

**1. "RPC connection failed"**
```bash
# Check RPC endpoint availability
curl -X POST https://evm-t3.cronos.org \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'

# If down, use backup RPC or contact Cronos team
```

**2. "Invalid signature"**
```bash
# Check domain config matches frontend
RELAY_CONTRACT_ADDRESS=0x... (must be correct)
CRONOS_CHAIN_ID=338           (must match)

# Verify EIP-712 domain in frontend code
```

**3. "Insufficient relayer balance"**
```bash
# Check relayer CRO balance
vercel logs | grep "relayer.*balance"

# Fund relayer account
send_cro_to_relayer_address()

# Or reduce rate limit temporarily
RATE_LIMIT_MAX_REQUESTS=50
```

**4. Rate limiting too aggressive**
```bash
# Check rate limit settings
RATE_LIMIT_WINDOW_MS=3600000     # 1 hour
RATE_LIMIT_MAX_REQUESTS=100      # Increase if needed

# Monitor actual request patterns
vercel logs | grep "rate_limited"
```

### Viewing Logs

```bash
# Stream production logs
vercel logs --follow

# Filter by error
vercel logs | grep -i error

# Search for specific user
vercel logs | grep "0x1234567890..."

# Export for analysis
vercel logs > logs-$(date +%Y%m%d).txt
```

---

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] All tests passing
- [ ] No security vulnerabilities
- [ ] Environment variables configured
- [ ] Relayer funded with CRO + USDC
- [ ] Contract addresses correct
- [ ] CORS properly configured

### During Deployment
- [ ] Monitor deployment progress
- [ ] Check build logs for errors
- [ ] Verify environment variables set
- [ ] Ensure secrets not exposed

### Post-Deployment
- [ ] Test `/health` endpoint
- [ ] Test `/faucet/usdc` endpoint
- [ ] Test `/x402/facilitate` with real transaction
- [ ] Check error logs for issues
- [ ] Monitor uptime + response times

### Maintenance
- [ ] Review logs daily
- [ ] Update dependencies monthly
- [ ] Rotate encryption keys quarterly
- [ ] Audit rate limits bi-weekly
- [ ] Test disaster recovery monthly

---

## 🆘 Support & Troubleshooting

### Resources
- [Vercel Docs](https://vercel.com/docs)
- [Next.js Deployment](https://nextjs.org/docs/deployment)
- [Cronos Docs](https://docs.cronos.org)
- [GitHub Issues](https://github.com/KingRaver/CroGas/issues)

### Emergency Contacts
- Vercel Support: [support.vercel.com](https://support.vercel.com)
- Cronos Discord: [cronos.org/discord](https://cronos.org/discord)
- Team: [contact-info-coming]

---

**Last Updated**: January 5, 2026  
**Deployment Version**: 1.0.0
