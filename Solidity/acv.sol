// SPDX-License-Identifier: GPL-3.0
 pragma solidity >=0.8.2 <0.9.0;

contract AccessControlFlaw {
    address public owner;
    address public withdrawAddress;
    
    constructor() {
        owner = msg.sender;
    }

modifier onlyOwner() {
    require(msg.sender == owner, "Not owner");
    _;
}

// Only owner can do
function setWithdrawAddress(address addr) public onlyOwner {
    withdrawAddress = addr;
}
}