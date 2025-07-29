 // SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.2 <0.9.0;

// A smart contract that initializes the deployer with 1000 tokens and allows transferring tokens between addresses.
contract SimpleToken {
    mapping(address => uint256) public balanceOf;
    
    // Initial issuance only - balance
    constructor() {
        balanceOf[msg.sender] = 1000;
    }
    
    // transfer
    function transfer(address to, uint256 amount) public {
        require(to != address(0), "Invalid recipient address");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }
}
