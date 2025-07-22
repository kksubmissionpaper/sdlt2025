// SPDX-License-Identifier: GPL-3.0
 pragma solidity >=0.8.2 <0.9.0;

contract ArrayUtils {
    // Searches for a value in a memory array
    function contains(uint[] memory arr, uint x) public pure returns (bool) {
        for (uint i = 0; i < arr.length; i++) {
            if (arr[i] == x) return true;
        }
        return false;
    }
}