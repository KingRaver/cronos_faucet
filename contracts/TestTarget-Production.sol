// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TestTarget
 * @dev Simple test contract for CroGas relay testing
 * @notice Used to verify meta-transactions work correctly
 * 
 * Features:
 * - Counter increment (test simple state change)
 * - Value storage (test parameterized functions)
 * - Interaction tracking (test state queries)
 * - Complex operations (test multi-step logic)
 * - Error scenarios (test error handling)
 * 
 * This contract is designed to thoroughly test relay functionality
 * before deploying to production with real user contracts.
 */
contract TestTarget {
    
    // ============ State Variables ============
    
    /// @dev Simple counter for testing state changes
    uint256 public counter = 0;
    
    /// @dev Address of last caller
    address public lastCaller;
    
    /// @dev Timestamp of last call
    uint256 public lastCallTime;
    
    /// @dev Maps address to their interaction count
    mapping(address => uint256) public interactions;
    
    /// @dev Maps address to stored values
    mapping(address => uint256) public amounts;
    
    /// @dev Total transactions executed
    uint256 public totalTransactions = 0;
    
    // ============ Events ============
    
    /// @dev Emitted when counter is incremented
    event CounterIncremented(
        address indexed caller,
        uint256 newValue,
        uint256 timestamp
    );
    
    /// @dev Emitted when value is stored
    event ValueStored(
        address indexed caller,
        uint256 value,
        uint256 timestamp
    );
    
    /// @dev Emitted when ETH is received
    event ETHReceived(
        address indexed sender,
        uint256 amount
    );
    
    /// @dev Emitted for complex operations
    event ComplexOperationExecuted(
        address indexed user,
        uint256 amount,
        address recipient,
        bool success
    );
    
    // ============ Core Functions ============
    
    /**
     * @dev Increment counter - tests simple state change
     * @return New counter value
     */
    function increment() 
        external 
        returns (uint256) 
    {
        counter++;
        lastCaller = msg.sender;
        lastCallTime = block.timestamp;
        interactions[msg.sender]++;
        totalTransactions++;
        
        emit CounterIncremented(msg.sender, counter, block.timestamp);
        
        return counter;
    }
    
    /**
     * @dev Decrement counter (test negative operations)
     * @return New counter value
     */
    function decrement() 
        external 
        returns (uint256) 
    {
        require(counter > 0, "Counter cannot go below 0");
        counter--;
        lastCaller = msg.sender;
        lastCallTime = block.timestamp;
        interactions[msg.sender]++;
        totalTransactions++;
        
        emit CounterIncremented(msg.sender, counter, block.timestamp);
        
        return counter;
    }
    
    /**
     * @dev Store a value for caller - tests parameterized functions
     * @param value Value to store
     */
    function storeValue(uint256 value) 
        external 
    {
        amounts[msg.sender] = value;
        lastCaller = msg.sender;
        lastCallTime = block.timestamp;
        interactions[msg.sender]++;
        totalTransactions++;
        
        emit ValueStored(msg.sender, value, block.timestamp);
    }
    
    /**
     * @dev Add to stored value (test arithmetic)
     * @param value Value to add
     * @return New total value
     */
    function addToValue(uint256 value) 
        external 
        returns (uint256) 
    {
        amounts[msg.sender] += value;
        lastCaller = msg.sender;
        lastCallTime = block.timestamp;
        interactions[msg.sender]++;
        totalTransactions++;
        
        emit ValueStored(msg.sender, amounts[msg.sender], block.timestamp);
        
        return amounts[msg.sender];
    }
    
    /**
     * @dev Multiply stored value (test complex math)
     * @param factor Multiplication factor
     * @return New value
     */
    function multiplyValue(uint256 factor) 
        external 
        returns (uint256) 
    {
        require(factor > 0, "Factor must be positive");
        amounts[msg.sender] *= factor;
        lastCaller = msg.sender;
        lastCallTime = block.timestamp;
        interactions[msg.sender]++;
        totalTransactions++;
        
        emit ValueStored(msg.sender, amounts[msg.sender], block.timestamp);
        
        return amounts[msg.sender];
    }
    
    /**
     * @dev Get stored value for address - tests reading state
     * @param user User address
     * @return Stored value
     */
    function getValue(address user) 
        external 
        view 
        returns (uint256) 
    {
        return amounts[user];
    }
    
    /**
     * @dev Get interaction count - tests tracking
     * @param user User address
     * @return Number of interactions
     */
    function getInteractionCount(address user) 
        external 
        view 
        returns (uint256) 
    {
        return interactions[user];
    }
    
    /**
     * @dev Get counter value
     * @return Current counter
     */
    function getCounter() 
        external 
        view 
        returns (uint256) 
    {
        return counter;
    }
    
    /**
     * @dev Get contract state snapshot
     * @return Current state as tuple
     */
    function getState() 
        external 
        view 
        returns (
            uint256 currentCounter,
            address currentLastCaller,
            uint256 totalTxs
        ) 
    {
        return (counter, lastCaller, totalTransactions);
    }
    
    // ============ Error Testing Functions ============
    
    /**
     * @dev Function that always reverts - tests error handling
     */
    function revertingFunction() 
        external 
        pure 
    {
        revert("This function always reverts");
    }
    
    /**
     * @dev Function that reverts with custom message
     * @param message Revert message
     */
    function revertWithMessage(string memory message) 
        external 
        pure 
    {
        require(false, message);
    }
    
    /**
     * @dev Test assertion failures
     * @param condition Condition that must be true
     */
    function testAssert(bool condition) 
        external 
        pure 
    {
        assert(condition);
    }
    
    // ============ Complex Operations ============
    
    /**
     * @dev Complex operation - tests multi-step execution
     * @param amount Amount to process
     * @param recipient Recipient address
     * @param multiplier Multiplier factor
     * @return success Whether operation succeeded
     */
    function complexOperation(
        uint256 amount,
        address recipient,
        uint256 multiplier
    ) 
        external 
        returns (bool success) 
    {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Amount must be positive");
        require(multiplier > 0, "Multiplier must be positive");
        
        // Step 1: Update state
        lastCaller = msg.sender;
        lastCallTime = block.timestamp;
        interactions[msg.sender]++;
        
        // Step 2: Store calculation
        uint256 calculated = amount * multiplier;
        amounts[msg.sender] = calculated;
        
        // Step 3: Increment counter
        counter++;
        
        // Step 4: Track transaction
        totalTransactions++;
        
        emit ComplexOperationExecuted(msg.sender, amount, recipient, true);
        
        return true;
    }
    
    /**
     * @dev Batch operation - test multiple updates
     * @param value Value to apply
     * @param iterations Number of iterations
     * @return Final counter value
     */
    function batchIncrement(
        uint256 value,
        uint256 iterations
    ) 
        external 
        returns (uint256) 
    {
        require(iterations > 0, "Iterations must be positive");
        require(iterations <= 100, "Too many iterations");
        
        for (uint256 i = 0; i < iterations; i++) {
            counter += value;
        }
        
        lastCaller = msg.sender;
        lastCallTime = block.timestamp;
        interactions[msg.sender]++;
        totalTransactions++;
        
        return counter;
    }
    
    // ============ Fallback Functions ============
    
    /**
     * @dev Receive ETH
     */
    receive() 
        external 
        payable 
    {
        emit ETHReceived(msg.sender, msg.value);
    }
    
    /**
     * @dev Fallback for any other calls
     */
    fallback() 
        external 
        payable 
    {
        emit ETHReceived(msg.sender, msg.value);
    }
    
    // ============ Admin Functions ============
    
    /**
     * @dev Reset counter to zero
     */
    function resetCounter() 
        external 
    {
        counter = 0;
        lastCaller = msg.sender;
        lastCallTime = block.timestamp;
        interactions[msg.sender]++;
        totalTransactions++;
    }
    
    /**
     * @dev Clear all stored values (WARNING: destructive)
     */
    function clearAllData() 
        external 
    {
        counter = 0;
        totalTransactions = 0;
    }
}
