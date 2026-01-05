// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/**
 * @title CroGasRelay
 * @dev Core relay contract that executes meta-transactions without requiring users to hold CRO
 * @notice Users pay in USDC, relayers cover CRO gas costs
 */
contract CroGasRelay is Ownable, ReentrancyGuard {
    
    // ============ Events ============
    event TransactionRelayed(
        address indexed user,
        address indexed target,
        uint256 indexed nonce,
        bool success,
        bytes result
    );
    
    event USDCCollected(
        address indexed user,
        uint256 amount,
        uint256 gasUsed
    );
    
    event RelayerUpdated(address indexed newRelayer);
    event USDCAddressUpdated(address indexed newUSDC);
    event FeePercentageUpdated(uint256 newFeePercentage);
    
    // ============ State Variables ============
    
    /// @dev Maps user address to their nonce for replay protection
    mapping(address => uint256) public userNonces;
    
    /// @dev USDC token contract address
    IERC20 public usdcToken;
    
    /// @dev Relayer address authorized to execute transactions
    address public relayer;
    
    /// @dev Fee percentage (e.g., 100 = 1.00%)
    uint256 public feePercentage = 100; // 1% default
    
    /// @dev Accumulated USDC in contract
    uint256 public accumulatedUSDC;
    
    // ============ Constructor ============
    
    constructor(address _usdcToken, address _relayer) {
        require(_usdcToken != address(0), "Invalid USDC address");
        require(_relayer != address(0), "Invalid relayer address");
        
        usdcToken = IERC20(_usdcToken);
        relayer = _relayer;
    }
    
    // ============ Core Functions ============
    
    /**
     * @dev Execute a meta-transaction on behalf of a user
     * @param user The user who authorized the transaction
     * @param target The contract to call
     * @param data The encoded function call
     * @param signature The EIP-712 signature from user
     * @param usdcAmount The amount of USDC to charge user
     * @return success Whether the target call succeeded
     * @return result The return data from the target call
     */
    function executeTx(
        address user,
        address target,
        bytes calldata data,
        bytes calldata signature,
        uint256 usdcAmount
    ) external onlyRelayer nonReentrant returns (bool success, bytes memory result) {
        require(user != address(0), "Invalid user address");
        require(target != address(0), "Invalid target address");
        require(usdcAmount > 0, "Invalid USDC amount");
        
        // Verify signature matches user
        bytes32 messageHash = keccak256(
            abi.encodePacked(user, target, data, userNonces[user])
        );
        address signer = recoverSigner(messageHash, signature);
        require(signer == user, "Invalid signature");
        
        // Increment nonce (prevent replay attacks)
        userNonces[user]++;
        
        // Check user has enough USDC
        uint256 userBalance = usdcToken.balanceOf(user);
        require(userBalance >= usdcAmount, "Insufficient USDC balance");
        
        // Execute target call
        (success, result) = target.call(data);
        
        // Transfer USDC from user to contract
        // NOTE: User must have approved contract to spend USDC first
        bool transferSuccess = usdcToken.transferFrom(user, address(this), usdcAmount);
        require(transferSuccess, "USDC transfer failed");
        
        // Update accumulated USDC
        accumulatedUSDC += usdcAmount;
        
        emit TransactionRelayed(user, target, userNonces[user] - 1, success, result);
        emit USDCCollected(user, usdcAmount, 0); // Gas tracking done off-chain
        
        return (success, result);
    }
    
    /**
     * @dev Execute transaction with EIP-712 permit signature
     * @dev Allows single transaction for both USDC approval and execution
     */
    function executeTxWithPermit(
        address user,
        address target,
        bytes calldata data,
        bytes calldata signature,
        uint256 usdcAmount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyRelayer nonReentrant returns (bool success, bytes memory result) {
        // First, permit USDC allowance
        IERC20Permit(address(usdcToken)).permit(
            user,
            address(this),
            usdcAmount,
            deadline,
            v,
            r,
            s
        );
        
        // Then execute transaction
        return executeTx(user, target, data, signature, usdcAmount);
    }
    
    // ============ Admin Functions ============
    
    /**
     * @dev Withdraw accumulated USDC to owner
     */
    function withdrawUSDC(uint256 amount) external onlyOwner nonReentrant {
        require(amount <= accumulatedUSDC, "Insufficient accumulated USDC");
        
        accumulatedUSDC -= amount;
        bool success = usdcToken.transfer(owner(), amount);
        require(success, "USDC transfer failed");
    }
    
    /**
     * @dev Update relayer address
     */
    function setRelayer(address _newRelayer) external onlyOwner {
        require(_newRelayer != address(0), "Invalid relayer address");
        relayer = _newRelayer;
        emit RelayerUpdated(_newRelayer);
    }
    
    /**
     * @dev Update USDC token address
     */
    function setUSDCAddress(address _newUSDC) external onlyOwner {
        require(_newUSDC != address(0), "Invalid USDC address");
        usdcToken = IERC20(_newUSDC);
        emit USDCAddressUpdated(_newUSDC);
    }
    
    /**
     * @dev Update fee percentage
     */
    function setFeePercentage(uint256 _newFeePercentage) external onlyOwner {
        require(_newFeePercentage <= 1000, "Fee too high"); // Max 10%
        feePercentage = _newFeePercentage;
        emit FeePercentageUpdated(_newFeePercentage);
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Get user's current nonce
     */
    function getNonce(address user) external view returns (uint256) {
        return userNonces[user];
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Recover signer address from EIP-712 signature
     */
    function recoverSigner(
        bytes32 messageHash,
        bytes calldata signature
    ) internal pure returns (address) {
        require(signature.length == 65, "Invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := calldataload(add(signature.offset, 0))
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }
        
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        
        return ecrecover(ethSignedMessageHash, v, r, s);
    }
    
    // ============ Modifiers ============
    
    modifier onlyRelayer() {
        require(msg.sender == relayer, "Only relayer can call this");
        _;
    }
}
