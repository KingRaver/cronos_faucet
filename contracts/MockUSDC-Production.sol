// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDC
 * @dev Mock USDC token for testing CroGas on Cronos testnet
 * @notice This is for TESTNET ONLY - NOT for production use on mainnet
 * 
 * Features:
 * - ERC20 standard token interface
 * - EIP-2612 Permit support (gasless approvals)
 * - Burnable token support
 * - Ownable for admin functions
 * - Testnet faucet for claiming tokens
 * 
 * Use Case:
 * - Testing CroGas relay functionality
 * - Simulating USDC on Cronos testnet
 * - Running integration tests
 */
contract MockUSDC is ERC20, ERC20Permit, ERC20Burnable, Ownable {
    
    // ============ Constants ============
    
    /// @dev Standard USDC decimals
    uint8 private constant DECIMALS = 6;
    
    /// @dev Faucet limit per claim (1000 USDC)
    uint256 private constant FAUCET_LIMIT = 1000 * 10 ** DECIMALS;
    
    // ============ State Variables ============
    
    /// @dev Maps address to last faucet claim timestamp
    mapping(address => uint256) public lastFaucetClaim;
    
    /// @dev Faucet cooldown period (1 hour)
    uint256 public faucetCooldown = 1 hours;
    
    // ============ Events ============
    
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    event FaucetClaimed(address indexed user, uint256 amount);
    event FaucetCooldownUpdated(uint256 newCooldown);
    
    // ============ Custom Errors ============
    
    error FaucetLimitExceeded();
    error FaucetOnCooldown(uint256 secondsUntilNext);
    error InvalidAmount();
    
    // ============ Constructor ============
    
    /**
     * @dev Initialize MockUSDC with initial supply
     */
    constructor() 
        ERC20("Mock USD Coin", "USDC") 
        ERC20Permit("Mock USD Coin") 
    {
        // Mint initial supply to deployer (1M USDC)
        _mint(msg.sender, 1_000_000 * 10 ** DECIMALS);
    }
    
    // ============ Admin Functions ============
    
    /**
     * @dev Mint new USDC tokens (admin only)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mint(address to, uint256 amount) 
        public 
        onlyOwner 
    {
        if (amount == 0) revert InvalidAmount();
        _mint(to, amount);
        emit Minted(to, amount);
    }
    
    /**
     * @dev Batch mint to multiple addresses
     * @param recipients Array of recipient addresses
     * @param amounts Array of amounts to mint
     */
    function batchMint(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) 
        external 
        onlyOwner 
    {
        if (recipients.length != amounts.length) revert InvalidAmount();
        
        for (uint256 i = 0; i < recipients.length; i++) {
            mint(recipients[i], amounts[i]);
        }
    }
    
    /**
     * @dev Update faucet cooldown period
     * @param _newCooldown New cooldown in seconds
     */
    function setFaucetCooldown(uint256 _newCooldown) 
        external 
        onlyOwner 
    {
        faucetCooldown = _newCooldown;
        emit FaucetCooldownUpdated(_newCooldown);
    }
    
    // ============ Public Functions ============
    
    /**
     * @dev Claim testnet USDC from faucet (anyone can call)
     * @param amount Amount to claim (capped at FAUCET_LIMIT)
     */
    function claimTestnetUSDC(uint256 amount) 
        external 
    {
        if (amount == 0) revert InvalidAmount();
        if (amount > FAUCET_LIMIT) revert FaucetLimitExceeded();
        
        // Check faucet cooldown
        uint256 lastClaim = lastFaucetClaim[msg.sender];
        if (lastClaim != 0 && block.timestamp < lastClaim + faucetCooldown) {
            uint256 secondsUntilNext = (lastClaim + faucetCooldown) - block.timestamp;
            revert FaucetOnCooldown(secondsUntilNext);
        }
        
        // Update last claim timestamp
        lastFaucetClaim[msg.sender] = block.timestamp;
        
        // Mint tokens to user
        _mint(msg.sender, amount);
        
        emit FaucetClaimed(msg.sender, amount);
    }
    
    /**
     * @dev Claim maximum amount from faucet with cooldown
     */
    function claimMaxTestnetUSDC() 
        external 
    {
        claimTestnetUSDC(FAUCET_LIMIT);
    }
    
    /**
     * @dev Get time until next faucet claim is available
     * @param user User address
     * @return Seconds until next claim (0 if ready)
     */
    function getTimeUntilNextClaim(address user) 
        external 
        view 
        returns (uint256) 
    {
        uint256 lastClaim = lastFaucetClaim[user];
        if (lastClaim == 0) return 0;
        
        uint256 nextClaimTime = lastClaim + faucetCooldown;
        if (block.timestamp >= nextClaimTime) return 0;
        
        return nextClaimTime - block.timestamp;
    }
    
    // ============ Override Functions ============
    
    /**
     * @dev Return token decimals
     */
    function decimals() 
        public 
        pure 
        override 
        returns (uint8) 
    {
        return DECIMALS;
    }
    
    /**
     * @dev Override burn to emit event
     */
    function burn(uint256 amount) 
        public 
        override 
    {
        super.burn(amount);
        emit Burned(msg.sender, amount);
    }
    
    /**
     * @dev Override burnFrom to emit event
     */
    function burnFrom(address account, uint256 amount) 
        public 
        override 
    {
        super.burnFrom(account, amount);
        emit Burned(account, amount);
    }
    
    // ============ Required Overrides ============
    
    /**
     * @dev Required override for ERC20 + ERC20Permit
     */
    function _update(
        address from,
        address to,
        uint256 value
    ) 
        internal 
        override(ERC20) 
    {
        super._update(from, to, value);
    }
    
    /**
     * @dev Required override for ERC20 + ERC20Permit
     */
    function nonces(address owner) 
        public 
        view 
        override(ERC20Permit) 
        returns (uint256) 
    {
        return super.nonces(owner);
    }
}
