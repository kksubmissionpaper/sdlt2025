// SPDX-License-Identifier: GPL-3.0
 pragma solidity >=0.8.2 <0.9.0;

contract AccessControlFlaw {
    address public withdrawAddress;

//Lacks access control
//any user can change the withdraw address
   
function setWithdrawAddress(address addr) public {
    withdrawAddress = addr;
	}
}