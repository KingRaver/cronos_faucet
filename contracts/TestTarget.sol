// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TestTarget
 * @dev Simple test contract for CroGas relay testing
 * @notice Used to verify meta-transactions work correctly
 */
contract TestTarget {
    
    // ============ State Variables ============
    
    /// @dev Simple counter for testing
    uint256 public counter = 0;
    
    /// @dev Stores last caller address
    address public lastCaller;
    
    /// @dev Maps address to interaction count
    mapping(address => uint256) public interactions;
    
    /// @dev Stores amounts sent
    mapping(address => uint256) public amounts;
    
    // ============ Events ============
    
    event CounterIncremented(address indexed caller, uint256 newValue);
    event ValueStored(address indexed caller, uint256 value);
    event ETHReceived(address indexed sender, uint256 amount);
    
    // ============ Core Functions ============
    
    /**
     * @dev Increment counter - tests simple state change
     */
    function increment() external {
        counter++;
        lastCaller = msg.sender;
        interactions[msg.sender]++;
        emit CounterIncremented(msg.sender, counter);
    }
    
    /**
     * @dev Store a value - tests parameterized function
     */
    function storeValue(uint256 value) external {
        amounts[msg.sender] = value;
        interactions[msg.sender]++;
        emit ValueStored(msg.sender, value);
    }
    
    /**
     * @dev Get stored value - tests reading state
     */
    function getValue(address user) external view returns (uint256) {
        return amounts[user];
    }
    
    /**
     * @dev Get interaction count - tests counting
     */
    function getInteractionCount(address user) external view returns (uint256) {
        return interactions[user];
    }
    
    /**
     * @dev Revert test - tests error handling
     */
    function revertingFunction() external pure {
        revert("This function always reverts");
    }
    
    /**
     * @dev Complex operation - tests multi-step execution
     */
    function complexOperation(
        uint256 amount,
        address recipient,
        bytes calldata data
    ) external returns (bool) {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be positive");
        
        lastCaller = msg.sender;
        interactions[msg.sender]++;
        amounts[msg.sender] = amount;
        
        // Emit event with data
        emit ValueStored(msg.sender, amount);
        
        return true;
    }
    
    // ============ Fallback Functions ============
    
    receive() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }
    
    fallback() external payable {
        emit ETHReceived(msg.sender, msg.value);
    }
}
