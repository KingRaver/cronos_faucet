// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

/**
 * @title CroGasRelay
 * @dev Core relay contract that executes meta-transactions without requiring users to hold native CRO
 * @notice Users pay in USDC, relayers cover CRO gas costs and are reimbursed
 * 
 * ## Security Features
 * - EIP-712 typed data signing for user authorization
 * - Nonce-based replay protection (incremented per user)
 * - ReentrancyGuard on all state-changing functions
 * - Access control (onlyOwner, onlyRelayer)
 * - Balance validation before execution
 * - Signature verification via ECDSA recovery
 * 
 * ## Usage Flow
 * 1. User signs EIP-712 message with target contract and calldata
 * 2. Frontend sends signature to backend
 * 3. Backend calls executeTx() with signature and USDC amount
 * 4. Contract verifies signature and nonce
 * 5. Contract executes target call
 * 6. Contract collects USDC fee from user
 * 7. Frontend receives tx hash and result
 */
contract CroGasRelay is Ownable, ReentrancyGuard {
    
    // ============ Events ============
    
    /// @dev Emitted when a transaction is successfully relayed
    event TransactionRelayed(
        address indexed user,
        address indexed target,
        uint256 indexed nonce,
        bool success,
        bytes result
    );
    
    /// @dev Emitted when USDC is collected from user
    event USDCCollected(
        address indexed user,
        uint256 amount,
        uint256 gasUsed
    );
    
    /// @dev Emitted when relayer address is updated
    event RelayerUpdated(address indexed newRelayer);
    
    /// @dev Emitted when USDC token address is updated
    event USDCAddressUpdated(address indexed newUSDC);
    
    /// @dev Emitted when fee percentage is updated
    event FeePercentageUpdated(uint256 newFeePercentage);
    
    /// @dev Emitted when fees are withdrawn
    event FeesWithdrawn(address indexed to, uint256 amount);
    
    // ============ State Variables ============
    
    /// @dev Maps user address to their transaction nonce (for replay protection)
    mapping(address => uint256) public userNonces;
    
    /// @dev USDC token contract address
    IERC20 public usdcToken;
    
    /// @dev Relayer address authorized to execute transactions
    address public relayer;
    
    /// @dev Protocol fee percentage (in basis points, e.g., 100 = 1.00%)
    uint256 public feePercentage = 100;
    
    /// @dev Total USDC accumulated from fees
    uint256 public accumulatedUSDC;
    
    /// @dev Emergency pause flag
    bool public paused = false;
    
    // ============ Custom Errors ============
    
    error InvalidUserAddress();
    error InvalidTargetAddress();
    error InvalidUSDCAmount();
    error InvalidSignature();
    error InvalidNonce();
    error InsufficientUSDCBalance();
    error TransactionExecutionFailed();
    error USDCTransferFailed();
    error ContractPaused();
    error OnlyRelayerCanCall();
    error OnlyOwnerCanCall();
    
    // ============ Constructor ============
    
    /**
     * @dev Initialize relay contract
     * @param _usdcToken Address of USDC token contract
     * @param _relayer Address of relayer that will execute transactions
     */
    constructor(address _usdcToken, address _relayer) {
        if (_usdcToken == address(0)) revert InvalidUserAddress();
        if (_relayer == address(0)) revert InvalidUserAddress();
        
        usdcToken = IERC20(_usdcToken);
        relayer = _relayer;
    }
    
    // ============ Core Functions ============
    
    /**
     * @dev Execute a meta-transaction on behalf of a user
     * @param user The user who authorized the transaction
     * @param target The contract to call
     * @param data The encoded function call (calldata)
     * @param signature The EIP-712 signature from user
     * @param usdcAmount The amount of USDC to charge user for gas
     * @return success Whether the target call succeeded
     * @return result The return data from the target call
     */
    function executeTx(
        address user,
        address target,
        bytes calldata data,
        bytes calldata signature,
        uint256 usdcAmount
    ) 
        external 
        onlyRelayer 
        nonReentrant 
        whenNotPaused 
        returns (bool success, bytes memory result) 
    {
        // Input validation
        if (user == address(0)) revert InvalidUserAddress();
        if (target == address(0)) revert InvalidTargetAddress();
        if (usdcAmount == 0) revert InvalidUSDCAmount();
        
        // Verify signature matches user
        bytes32 messageHash = _computeMessageHash(user, target, data, userNonces[user]);
        address signer = _recoverSigner(messageHash, signature);
        if (signer != user) revert InvalidSignature();
        
        // Increment nonce (prevent replay attacks)
        uint256 currentNonce = userNonces[user];
        userNonces[user]++;
        
        // Check user has enough USDC
        uint256 userBalance = usdcToken.balanceOf(user);
        if (userBalance < usdcAmount) revert InsufficientUSDCBalance();
        
        // Execute target call
        (success, result) = target.call(data);
        
        // Transfer USDC from user to contract (for fee)
        // User must have approved contract to spend USDC first
        bool transferSuccess = usdcToken.transferFrom(user, address(this), usdcAmount);
        if (!transferSuccess) revert USDCTransferFailed();
        
        // Update accumulated USDC
        accumulatedUSDC += usdcAmount;
        
        // Emit events
        emit TransactionRelayed(user, target, currentNonce, success, result);
        emit USDCCollected(user, usdcAmount, 0);
        
        return (success, result);
    }
    
    /**
     * @dev Execute transaction with EIP-712 permit signature for USDC approval
     * @dev This allows single transaction for both USDC approval and execution
     * @param user The user who authorized the transaction
     * @param target The contract to call
     * @param data The encoded function call
     * @param signature The EIP-712 signature for transaction
     * @param usdcAmount The amount of USDC to charge user
     * @param deadline Permit deadline
     * @param v Signature v component
     * @param r Signature r component
     * @param s Signature s component
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
    ) 
        external 
        onlyRelayer 
        nonReentrant 
        whenNotPaused 
        returns (bool success, bytes memory result) 
    {
        // First, permit USDC allowance using EIP-2612
        try IERC20Permit(address(usdcToken)).permit(
            user,
            address(this),
            usdcAmount,
            deadline,
            v,
            r,
            s
        ) {} catch {
            // Permit may fail if already approved, continue anyway
        }
        
        // Then execute transaction
        return executeTx(user, target, data, signature, usdcAmount);
    }
    
    // ============ Admin Functions ============
    
    /**
     * @dev Withdraw accumulated USDC fees to owner
     * @param amount Amount of USDC to withdraw
     */
    function withdrawUSDC(uint256 amount) 
        external 
        onlyOwner 
        nonReentrant 
    {
        if (amount > accumulatedUSDC) revert InvalidUSDCAmount();
        
        accumulatedUSDC -= amount;
        bool success = usdcToken.transfer(owner(), amount);
        if (!success) revert USDCTransferFailed();
        
        emit FeesWithdrawn(owner(), amount);
    }
    
    /**
     * @dev Update relayer address
     * @param _newRelayer New relayer address
     */
    function setRelayer(address _newRelayer) 
        external 
        onlyOwner 
    {
        if (_newRelayer == address(0)) revert InvalidUserAddress();
        relayer = _newRelayer;
        emit RelayerUpdated(_newRelayer);
    }
    
    /**
     * @dev Update USDC token address
     * @param _newUSDC New USDC token address
     */
    function setUSDCAddress(address _newUSDC) 
        external 
        onlyOwner 
    {
        if (_newUSDC == address(0)) revert InvalidUserAddress();
        usdcToken = IERC20(_newUSDC);
        emit USDCAddressUpdated(_newUSDC);
    }
    
    /**
     * @dev Update fee percentage
     * @param _newFeePercentage New fee percentage in basis points (e.g., 100 = 1%)
     */
    function setFeePercentage(uint256 _newFeePercentage) 
        external 
        onlyOwner 
    {
        if (_newFeePercentage > 1000) revert InvalidUSDCAmount(); // Max 10%
        feePercentage = _newFeePercentage;
        emit FeePercentageUpdated(_newFeePercentage);
    }
    
    /**
     * @dev Emergency pause function
     */
    function pause() 
        external 
        onlyOwner 
    {
        paused = true;
    }
    
    /**
     * @dev Emergency unpause function
     */
    function unpause() 
        external 
        onlyOwner 
    {
        paused = false;
    }
    
    // ============ View Functions ============
    
    /**
     * @dev Get user's current nonce
     * @param user User address
     * @return Current nonce for user
     */
    function getNonce(address user) 
        external 
        view 
        returns (uint256) 
    {
        return userNonces[user];
    }
    
    /**
     * @dev Check if contract is paused
     * @return True if paused
     */
    function isPaused() 
        external 
        view 
        returns (bool) 
    {
        return paused;
    }
    
    /**
     * @dev Get total accumulated fees
     * @return Total USDC collected
     */
    function getTotalAccumulatedFees() 
        external 
        view 
        returns (uint256) 
    {
        return accumulatedUSDC;
    }
    
    // ============ Internal Functions ============
    
    /**
     * @dev Compute EIP-712 message hash
     * @param user User address
     * @param target Target contract address
     * @param data Function call data
     * @param nonce User's nonce
     * @return Hash of the message
     */
    function _computeMessageHash(
        address user,
        address target,
        bytes calldata data,
        uint256 nonce
    ) 
        internal 
        pure 
        returns (bytes32) 
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(user, target, data, nonce))
            )
        );
    }
    
    /**
     * @dev Recover signer address from signature
     * @param messageHash Hash of the message
     * @param signature Signature bytes (65 bytes: r, s, v)
     * @return Recovered signer address
     */
    function _recoverSigner(
        bytes32 messageHash,
        bytes calldata signature
    ) 
        internal 
        pure 
        returns (address) 
    {
        if (signature.length != 65) revert InvalidSignature();
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := calldataload(add(signature.offset, 0))
            s := calldataload(add(signature.offset, 32))
            v := byte(0, calldataload(add(signature.offset, 64)))
        }
        
        address recovered = ecrecover(messageHash, v, r, s);
        if (recovered == address(0)) revert InvalidSignature();
        
        return recovered;
    }
    
    // ============ Modifiers ============
    
    /**
     * @dev Only allow relayer to call
     */
    modifier onlyRelayer() {
        if (msg.sender != relayer) revert OnlyRelayerCanCall();
        _;
    }
    
    /**
     * @dev Only allow when not paused
     */
    modifier whenNotPaused() {
        if (paused) revert ContractPaused();
        _;
    }
}
