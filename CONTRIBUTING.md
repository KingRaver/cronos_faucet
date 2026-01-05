# Contributing to CroGas

Welcome! We're thrilled you want to contribute to CroGas, the gas station for AI agents. This guide will help you get started.

---

## 🚀 Getting Started

### 1. Fork & Clone

```bash
# Fork the repository on GitHub, then clone your fork
git clone https://github.com/YOUR_USERNAME/CroGas.git
cd CroGas
git remote add upstream https://github.com/KingRaver/CroGas.git
```

### 2. Set Up Development Environment

```bash
# Install Node.js 18+ from https://nodejs.org

# Install dependencies
npm install

# Copy environment template
cp .env.example .env

# Fill in your .env with:
# - RELAYER_PRIVATE_KEY_ENCRYPTED (see scripts/encrypt-existing-key.js)
# - CRONOS_RPC_URL
# - Other required variables (see README.md)

# Run development server
npm run dev
# Frontend: http://localhost:3000
# Backend API: http://localhost:3000/api/*
```

### 3. Install Pre-Commit Hooks (Optional)

```bash
npm run prepare
# Enables automatic linting on commit
```

---

## 📋 Branch Naming Conventions

Use descriptive branch names that start with a type prefix:

```
feat/your-feature-name           # New feature
fix/bug-description              # Bug fix
docs/documentation-update        # Documentation
refactor/component-name          # Code refactoring
test/test-description            # Tests
perf/performance-improvement     # Performance
security/vulnerability-fix       # Security fix
chore/dependency-update          # Dependency updates
```

**Examples:**
```bash
git checkout -b feat/multi-chain-support
git checkout -b fix/relayer-nonce-handling
git checkout -b docs/api-reference
git checkout -b perf/gas-estimation-caching
```

---

## 🧪 Code Quality Standards

### TypeScript
- **Strict Mode**: All code must pass `tsconfig.json` strict mode
- **No `any` types**: Use explicit types everywhere
- **Interfaces over types** for public APIs
- **Meaningful variable names**: `relayerBalance` not `rb`

### Linting & Formatting

```bash
# Run linter
npm run lint

# Auto-fix linting issues
npm run lint:fix

# Check formatting (Prettier)
npm run format:check

# Auto-format code
npm run format
```

### Testing

```bash
# Run test suite
npm run test

# Run with coverage
npm run test:coverage

# Watch mode for development
npm run test:watch
```

**Requirements:**
- Minimum 80% code coverage
- All new features must have tests
- All bug fixes must include regression tests

---

## 📝 Commit Message Format

Follow conventional commits for clarity and automated changelog generation:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type
- `feat` – New feature
- `fix` – Bug fix
- `docs` – Documentation changes
- `style` – Code style (formatting, missing semicolons, etc.)
- `refactor` – Code refactoring
- `perf` – Performance improvement
- `test` – Test additions/changes
- `chore` – Dependency updates, build scripts
- `security` – Security-related changes

### Scope
The area of code affected: `frontend`, `backend`, `x402`, `relayer`, `ui`, `api`, etc.

### Subject
- Imperative mood: "add feature" not "added feature"
- No period at the end
- 50 characters max
- Lowercase

### Body (Optional)
Explain **what** and **why**, not how:

```
fix(x402): prevent double-payment in signature validation

The x402 facilitator was checking EIP-3009 nonce twice,
causing transactions to fail on retry. This fix ensures
nonce is only incremented once per relay.

Fixes #123
```

### Footer (Optional)
Reference issues:

```
Fixes #123
Closes #456
Related to #789
```

### Examples

```
feat(backend): implement dynamic gas pricing based on network load

fix(frontend): resolve dashboard metrics caching issue

docs(api): add x402 endpoint examples with cURL and fetch

refactor(ui): extract card component to reduce duplication

perf(relayer): optimize signature verification with cached keys

test(x402): add integration tests for meta-transaction flow

security(backend): add rate limiting per relayer account
```

---

## 🔄 Pull Request Process

### Before Submitting

1. **Update from upstream**:
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run all checks**:
   ```bash
   npm run lint:fix
   npm run format
   npm run test
   npm run build
   ```

3. **Verify no conflicts**:
   ```bash
   git push origin your-branch-name
   ```

### PR Description Template

```markdown
## Description
Brief description of changes.

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Breaking change
- [ ] Documentation update

## Related Issues
Fixes #123

## Testing
- [ ] Added/updated tests
- [ ] All tests passing locally
- [ ] Tested on testnet (if blockchain-related)

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-reviewed code
- [ ] Comments added for complex logic
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests pass locally with my changes

## Screenshots (if UI change)
[Add images if relevant]

## Migration Notes (if applicable)
Any breaking changes or migration steps needed.
```

### Review Process

- At least 1 approval from maintainers required
- All CI checks must pass
- No merge conflicts
- Code coverage must not decrease
- Breaking changes must be clearly documented

---

## 🎯 Contribution Areas

### Frontend (Next.js + React)
- UI/UX improvements
- New dashboard metrics
- Additional theme variants
- Accessibility enhancements
- Performance optimizations
- Component refactoring

**Getting started:**
```bash
cd crogas_frontend
npm run dev
# Edit files in app/ and components/
# Browser auto-refreshes on save
```

### Backend (Express + TypeScript)
- New API endpoints
- Rate limiting improvements
- Error handling enhancements
- Logging improvements
- Security hardening
- Database integration (future)

**Getting started:**
```bash
cd crogas_backend
npm run dev
# Edit files in src/
# API server runs on port 3000
```

### Smart Contracts
- Enhanced meta-transaction relay
- Gas optimization
- Additional safety checks
- New x402 features

### DevOps & Infrastructure
- Vercel deployment optimizations
- Monitoring setup
- Performance metrics
- CI/CD improvements
- Docker containerization

### Documentation
- API documentation
- Tutorial guides
- Troubleshooting guides
- Architecture diagrams
- Community guides

---

## 🔐 Security Guidelines

### Handling Sensitive Data
- **Never commit** `.env` files with real keys
- **Use `.env.example`** as template
- **Encrypt** private keys before storing (see `scripts/encrypt-existing-key.js`)
- **Rotate keys** if accidentally exposed

### Security Review Checklist
- [ ] No hardcoded secrets
- [ ] Input validation implemented
- [ ] Rate limiting considered
- [ ] Signature verification correct
- [ ] No replay attack vulnerabilities
- [ ] Error messages don't leak sensitive info

### Reporting Security Issues
**Do not** open public issues for security vulnerabilities.

Email security concerns to: [Your security contact]

Include:
- Description of vulnerability
- Reproduction steps
- Potential impact
- Suggested fix (optional)

---

## 🤝 Community

### Getting Help
- **GitHub Issues**: For bugs and features
- **GitHub Discussions**: For questions
- **Discord**: [Link coming soon]
- **Twitter/X**: [@YourHandle]

### Code of Conduct

We're committed to providing a welcoming and inclusive environment:

- Be respectful and constructive
- Welcome diverse perspectives
- Report problematic behavior to maintainers
- No harassment, discrimination, or hate speech

---

## 📚 Resources

### Documentation
- [README.md](README.md) – Project overview
- [API.md](API.md) – API reference
- [ARCHITECTURE.md](ARCHITECTURE.md) – System design
- [DEPLOYMENT.md](DEPLOYMENT.md) – Deployment guide
- [SECURITY.md](SECURITY.md) – Security details

### External Links
- [x402 Protocol Docs](https://docs.cdp.coinbase.com/x402/welcome)
- [Cronos Documentation](https://docs.cronos.org)
- [Wagmi Documentation](https://wagmi.sh)
- [Viem Documentation](https://viem.sh)

### Learning Resources
- [EIP-712: Typed Data Hashing](https://eips.ethereum.org/EIPS/eip-712)
- [EIP-3009: USDC Transfer with Authorization](https://eips.ethereum.org/EIPS/eip-3009)
- [ERC-2771: Meta Transactions](https://eips.ethereum.org/EIPS/erc-2771)
- [OpenGSN: Gasless Transactions](https://docs.opengsn.org)

---

## 🎉 Recognition

Contributors are recognized in:
- GitHub contributors page
- Project README
- Release notes for significant contributions
- Community call shout-outs

### Thank You! 🙏

Every contribution—whether code, documentation, bug reports, or suggestions—helps CroGas grow and improve. We appreciate your time and effort!

---

**Happy contributing! 🚀**
