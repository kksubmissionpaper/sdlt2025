// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract MultiSigWallet {
    // event definition
    event SubmitTransaction(uint indexed txIndex, address indexed to, uint value);
    event ConfirmTransaction(address indexed owner, uint indexed txIndex);
    event ExecuteTransaction(uint indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint indexed txIndex);

    // status
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public threshold;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint confirmations;
    }

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    // modifier
    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    // constructor
    constructor(address[] memory _owners, uint _threshold) {
        require(_owners.length > 0 && _threshold > 0 && _threshold <= _owners.length);

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0) && !isOwner[owner]);
            isOwner[owner] = true;
            owners.push(owner);
        }
        threshold = _threshold;
    }

    // receive ETH
    receive() external payable {}

    // submit transaction
    function submitTransaction(address _to, uint _value) external onlyOwner {
        uint txIndex = transactions.length;
        transactions.push(Transaction(_to, _value, false, 0));
        emit SubmitTransaction(txIndex, _to, _value);
    }

    // confirm transaction
    function confirmTransaction(uint _txIndex) external onlyOwner {
        require(_txIndex < transactions.length && !transactions[_txIndex].executed);
        require(!isConfirmed[_txIndex][msg.sender]);

        transactions[_txIndex].confirmations++;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    // execute transaction
    function executeTransaction(uint _txIndex) external onlyOwner {
        require(_txIndex < transactions.length);
        Transaction storage transaction = transactions[_txIndex];
        require(!transaction.executed && transaction.confirmations >= threshold);

        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}("");
        require(success);
        emit ExecuteTransaction(_txIndex);
    }

    // revoke
    function revokeConfirmation(uint _txIndex) external onlyOwner {
        require(_txIndex < transactions.length && !transactions[_txIndex].executed);
        require(isConfirmed[_txIndex][msg.sender]);

        transactions[_txIndex].confirmations--;
        isConfirmed[_txIndex][msg.sender] = false;
        emit RevokeConfirmation(msg.sender, _txIndex);
    }
}