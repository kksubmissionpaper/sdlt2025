
/// Module: multisig_wallet
///module multisig::multisig_wallet;

/// For Move coding conventions, see
/// https://docs.sui.io/concepts/sui-move-concepts/conventions

#[allow(lint(coin_field))]
module multisig::multisig_wallet {
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::table::{Self, Table};
    use sui::event;

    // error codes
    const ENotOwner: u64 = 0;
    const EInvalidThreshold: u64 = 1;
    const ETransactionNotFound: u64 = 2;
    const ETransactionAlreadyExecuted: u64 = 3;
    const EAlreadyConfirmed: u64 = 4;
    const ENotConfirmed: u64 = 5;
    const EInsufficientConfirmations: u64 = 6;
    const EInsufficientBalance: u64 = 7;

    // event definition
    public struct TransactionSubmitted has copy, drop {
        wallet_id: address,
        tx_id: u64,
        to: address,
        amount: u64,
        submitter: address,
    }

    public struct TransactionConfirmed has copy, drop {
        wallet_id: address,
        tx_id: u64,
        confirmer: address,
    }

    public struct TransactionExecuted has copy, drop {
        wallet_id: address,
        tx_id: u64,
        executor: address,
    }

    public struct ConfirmationRevoked has copy, drop {
        wallet_id: address,
        tx_id: u64,
        revoker: address,
    }

    // transaction
    public struct Transaction has store {
        id: u64,
        to: address,
        amount: u64,
        executed: bool,
        confirmations: vector<address>,
        confirmation_count: u64,
    }

    // multi sig wallet
    public struct MultiSigWallet has key {
        id: UID,
        owners: vector<address>,
        threshold: u64,
        transactions: Table<u64, Transaction>,
        next_tx_id: u64,
        balance: Coin<SUI>,
    }

    // create a wallet
    public fun create_wallet(
        owners: vector<address>,
        threshold: u64,
        ctx: &mut TxContext
    ): MultiSigWallet {
        let owner_count = vector::length(&owners);
        assert!(threshold > 0 && threshold <= owner_count, EInvalidThreshold);

        MultiSigWallet {
            id: object::new(ctx),
            owners,
            threshold,
            transactions: table::new(ctx),
            next_tx_id: 0,
            balance: coin::zero(ctx),
        }
    }

    // wallet is as shared object
    public fun share_wallet(wallet: MultiSigWallet) {
        transfer::share_object(wallet);
    }

    // deposit
    public fun deposit(
        wallet: &mut MultiSigWallet,
        payment: Coin<SUI>
    ) {
        coin::join(&mut wallet.balance, payment);
    }

    // checking an owner
    fun is_owner(wallet: &MultiSigWallet, addr: address): bool {
        vector::contains(&wallet.owners, &addr)
    }

    // submit transaction
    public fun submit_transaction(
        wallet: &mut MultiSigWallet,
        to: address,
        amount: u64,
        ctx: &mut TxContext
    ): u64 {
        let sender = tx_context::sender(ctx);
        assert!(is_owner(wallet, sender), ENotOwner);
        assert!(coin::value(&wallet.balance) >= amount, EInsufficientBalance);

        let tx_id = wallet.next_tx_id;
        let transaction = Transaction {
            id: tx_id,
            to,
            amount,
            executed: false,
            confirmations: vector::empty(),
            confirmation_count: 0,
        };

        table::add(&mut wallet.transactions, tx_id, transaction);
        wallet.next_tx_id = tx_id + 1;

        // publish an event
        event::emit(TransactionSubmitted {
            wallet_id: object::uid_to_address(&wallet.id),
            tx_id,
            to,
            amount,
            submitter: sender,
        });

        tx_id
    }

    // confirm transaction
    public fun confirm_transaction(
        wallet: &mut MultiSigWallet,
        tx_id: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(is_owner(wallet, sender), ENotOwner);
        assert!(table::contains(&wallet.transactions, tx_id), ETransactionNotFound);

        let transaction = table::borrow_mut(&mut wallet.transactions, tx_id);
        assert!(!transaction.executed, ETransactionAlreadyExecuted);
        assert!(!vector::contains(&transaction.confirmations, &sender), EAlreadyConfirmed);

        vector::push_back(&mut transaction.confirmations, sender);
        transaction.confirmation_count = transaction.confirmation_count + 1;

        // publish an event
        event::emit(TransactionConfirmed {
            wallet_id: object::uid_to_address(&wallet.id),
            tx_id,
            confirmer: sender,
        });
    }

    // execute transaction
    public fun execute_transaction(
        wallet: &mut MultiSigWallet,
        tx_id: u64,
        ctx: &mut TxContext
    ): Coin<SUI> {
        let sender = tx_context::sender(ctx);
        assert!(is_owner(wallet, sender), ENotOwner);
        assert!(table::contains(&wallet.transactions, tx_id), ETransactionNotFound);

        let transaction = table::borrow_mut(&mut wallet.transactions, tx_id);
        assert!(!transaction.executed, ETransactionAlreadyExecuted);
        assert!(transaction.confirmation_count >= wallet.threshold, EInsufficientConfirmations);

        transaction.executed = true;

        // split coin
        let payment = coin::split(&mut wallet.balance, transaction.amount, ctx);

        // publish an event
        event::emit(TransactionExecuted {
            wallet_id: object::uid_to_address(&wallet.id),
            tx_id,
            executor: sender,
        });

        payment
    }

    // revoke confirmation
    public fun revoke_confirmation(
        wallet: &mut MultiSigWallet,
        tx_id: u64,
        ctx: &mut TxContext
    ) {
        let sender = tx_context::sender(ctx);
        assert!(is_owner(wallet, sender), ENotOwner);
        assert!(table::contains(&wallet.transactions, tx_id), ETransactionNotFound);

        let transaction = table::borrow_mut(&mut wallet.transactions, tx_id);
        assert!(!transaction.executed, ETransactionAlreadyExecuted);

        let (found, index) = vector::index_of(&transaction.confirmations, &sender);
        assert!(found, ENotConfirmed);

        vector::remove(&mut transaction.confirmations, index);
        transaction.confirmation_count = transaction.confirmation_count - 1;

        // publish an event
        event::emit(ConfirmationRevoked {
            wallet_id: object::uid_to_address(&wallet.id),
            tx_id,
            revoker: sender,
        });
    }

    // getter functions
    public fun get_owners(wallet: &MultiSigWallet): &vector<address> {
        &wallet.owners
    }

    public fun get_threshold(wallet: &MultiSigWallet): u64 {
        wallet.threshold
    }

    public fun get_balance(wallet: &MultiSigWallet): u64 {
        coin::value(&wallet.balance)
    }

    public fun get_transaction_count(wallet: &MultiSigWallet): u64 {
        wallet.next_tx_id
    }

    public fun get_transaction_details(
        wallet: &MultiSigWallet, 
        tx_id: u64
    ): (address, u64, bool, u64) {
        assert!(table::contains(&wallet.transactions, tx_id), ETransactionNotFound);
        let transaction = table::borrow(&wallet.transactions, tx_id);
        (transaction.to, transaction.amount, transaction.executed, transaction.confirmation_count)
    }

    // checking if transaction is confirmed
    public fun is_transaction_confirmed_by(
        wallet: &MultiSigWallet,
        tx_id: u64,
        addr: address
    ): bool {
        if (!table::contains(&wallet.transactions, tx_id)) {
            return false
        };
        let transaction = table::borrow(&wallet.transactions, tx_id);
        vector::contains(&transaction.confirmations, &addr)
    }
}