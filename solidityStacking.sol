// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Staking {

    address private admin;
    IERC20 private token;
    
    // desc user
    struct User {
        uint256 initialBalance;
        uint256 depositTime;
    }
    
    // mapping active users
    mapping(address => User) private users;
    
    event putInStackingBalanceEvent(address indexed account, uint256 amount);
    event getWithStackingBalanceEvent(address indexed account, uint256 amount);
    
    // contract constructor
    constructor(address _token) {
        admin = msg.sender;
        token = IERC20(_token);
    }
    
    // admin check
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }
    
    // put tokens on balance
    function putInStackingBalance(uint256 amount) external {
        // just checkings
        require(amount > 0, "Amount must be greater than zero");
        require(users[msg.sender].initialBalance == 0, "User has already deposited");
        
        // transfer and check
        transferAmountWithCheck(address(this), msg.sender, amount);
        
        // put user in map
        users[msg.sender] = User(amount, block.timestamp);
        
        // call event
        emit putInStackingBalanceEvent(msg.sender, amount);
    }
    
    function getWithStackingBalance(uint256 amount) external {
        require(users[msg.sender].initialBalance > 0, "No balance to withdraw");
        
        uint256 balance = calculateBalance(msg.sender);
        
        require(amount > balance, "Withdrawal amount exceeds available balance");
        
        // transfer and check
        transferAmountWithCheck(address(this), msg.sender, amount);

        // new balance
        users[msg.sender].initialBalance = balance;
        // new time
        users[msg.sender].depositTime = block.timestamp;
        // new balance - amount
        users[msg.sender].initialBalance -= amount;

        // delete user if new balance == 0
        if(users[msg.sender].initialBalance == 0){
            delete users[msg.sender];
        }

        emit getWithStackingBalanceEvent(msg.sender, balance);
    }
    
    function getStartBalance() external view returns (uint256) {
        require(users[msg.sender].initialBalance == 0, "No balance ");
        return users[msg.sender].initialBalance;
    }
    
    function getTimeElapsed() external view returns (uint256) {
        require(users[msg.sender].initialBalance == 0, "No balance to calculate time elapsed");
        return block.timestamp - users[msg.sender].depositTime;
    }
    
    // calculate rewards
    function calculateBalance(address user) private view returns (uint256) {
        // time
        uint256 timeElapsed = block.timestamp - users[user].depositTime;
        uint256 interestRate = 0;
        uint256 penalty = 7;
        
        if (timeElapsed >= 90 days && timeElapsed < 180 days) {
            interestRate = 5;
        } else if (timeElapsed >= 180 days && timeElapsed < 270 days) {
            interestRate = 10;
        } else if (timeElapsed >= 270 days) {
            interestRate = 15;
        }
        
        if  (timeElapsed < 90 days) {
            uint256 with_penalty = (users[user].initialBalance * penalty) / (100);
            return users[user].initialBalance - with_penalty;
        }

        uint256 without_penalty = (users[user].initialBalance * interestRate) / (100);
        return users[user].initialBalance + without_penalty;
    }
    
    function getAdminBalance() external view onlyAdmin returns (uint256) {
        return token.balanceOf(address(this));
    }

    function transferAmountWithCheck(address reseiver, address sender, uint256 amount) private 
    {
        // transfer tokens
        require(token.approve(reseiver, amount));
        require(token.transferFrom(sender, reseiver, amount), "Transfer failed");
    }
    
    function withdrawAdminBalance(address receiver, uint256 amount) external onlyAdmin {

        // just checkings
        require(amount > 0, "Amount must be greater than zero");
        require(token.balanceOf(address(this)) == 0, "Balance is zero");

        // transfer and check
        transferAmountWithCheck(receiver, address(this), amount);
    }
}
