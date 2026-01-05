sequenceDiagram
    participant User as 👤 Creator/User
    participant Frontend as 🖥️ Frontend<br/>Next.js
    participant Backend as 🔄 Backend<br/>Express
    participant Blockchain as ⛓️ Cronos<br/>Testnet
    
    User->>Frontend: 1. Connect Wallet
    Frontend->>Frontend: Detect MetaMask on Cronos
    Frontend-->>User: Wallet Connected ✅
    
    User->>Frontend: 2. Enter Target Contract<br/>+ Calldata + Gas Tier
    Frontend->>Frontend: Validate inputs
    Frontend-->>User: Ready to Execute
    
    User->>Frontend: 3. Sign EIP-712 Message
    Frontend->>Frontend: Create TypedData<br/>(domain, types, message)
    Frontend->>User: Open Wallet Signature
    User-->>Frontend: Signature Signed ✅
    
    Frontend->>Backend: 4. POST /x402/facilitate<br/>(signature + request)
    
    Backend->>Backend: Verify EIP-712 Signature
    Backend->>Backend: Check Nonce (prevent replay)
    Backend->>Backend: Validate Request (Zod schema)
    Backend->>Backend: Estimate Gas
    Backend->>Backend: Calculate USDC charge
    Backend->>Backend: Check User USDC Balance
    Backend->>Backend: Check Relayer CRO Balance
    
    alt All Checks Pass
        Backend->>Blockchain: Execute Meta-Transaction
        Blockchain->>Blockchain: Relay Contract<br/>executeTx()
        Blockchain->>Blockchain: Target Contract<br/>Execute User Calldata
        Blockchain-->>Backend: Execution Success
        
        Backend->>Blockchain: Settle Payment<br/>USDC Transfer
        Blockchain->>Blockchain: EIP-3009<br/>transferWithAuthorization()
        Blockchain-->>Backend: Payment Confirmed
        
        Backend->>Backend: Increment User Nonce
        Backend-->>Frontend: 5. Return Success<br/>(txHash + explorer URL)
        Frontend-->>User: Transaction Confirmed
        Frontend->>Frontend: Update Dashboard
        Frontend->>Frontend: Show Notification
        User->>Frontend: View Transaction<br/>on Cronoscan
        
    else Signature Invalid
        Backend-->>Frontend: Erro
