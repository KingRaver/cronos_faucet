// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSDC
 * @dev Mock USDC token for testing CroGas on Cronos testnet
 * @notice NOT for production use - only for development/testing
 */
contract MockUSDC is ERC20, ERC20Permit, ERC20Burnable, Ownable {
    
    uint8 private constant DECIMALS = 6;
    
    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);
    
    constructor() 
        ERC20("Mock USD Coin", "USDC") 
        ERC20Permit("Mock USD Coin") 
    {
        // Mint initial supply to deployer
        _mint(msg.sender, 1_000_000 * 10 ** DECIMALS);
    }
    
    /**
     * @dev Mint new USDC tokens (testnet only)
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
        emit Minted(to, amount);
    }
    
    /**
     * @dev Faucet function - anyone can claim testnet USDC
     */
    function claimTestnetUSDC(uint256 amount) public {
        require(amount <= 10000 * 10 ** DECIMALS, "Faucet limit exceeded");
        _mint(msg.sender, amount);
        emit Minted(msg.sender, amount);
    }
    
    function decimals() public pure override returns (uint8) {
        return DECIMALS;
    }
}
