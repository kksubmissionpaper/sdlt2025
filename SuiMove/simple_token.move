/// Simple Token implementation in Sui Move (2024 edition)
module simple_token::simple_token {
    use sui::coin::{Self, Coin};

    /// Token Treasury capability
    public struct TokenCap has key {
        id: UID,
        total_supply: u64,
    }

    /// Simple Token type
    public struct SIMPLE_TOKEN has drop {}

    /// Error codes
    const EInsufficientBalance: u64 = 1;

    /// Initialize the token (similar to constructor)
    fun init(witness: SIMPLE_TOKEN, ctx: &mut TxContext) {
        // Create currency and get treasury cap
        let (mut treasury_cap, metadata) = coin::create_currency(
            witness,
            9, // decimals
            b"SIMPLE", // symbol
            b"Simple Token", // name
            b"A test simple token for demonstration", // description
            option::none(), // icon url
            ctx
        );

        // Transfer metadata to sender
        transfer::public_transfer(metadata, tx_context::sender(ctx));

        // Mint initial supply (1000 tokens)
        let initial_coin = coin::mint(&mut treasury_cap, 1000_000_000_000, ctx); // 1000 with 9 decimals
        
        // Transfer initial tokens to deployer
        transfer::public_transfer(initial_coin, tx_context::sender(ctx));

        // Create and transfer treasury capability
        let token_cap = TokenCap {
            id: object::new(ctx),
            total_supply: 1000_000_000_000,
        };
        
        transfer::transfer(token_cap, tx_context::sender(ctx));
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx));
    }

    /// Transfer tokens 
    #[allow(lint(self_transfer))]
    public fun transfer_tokens(
        mut coin: Coin<SIMPLE_TOKEN>,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        // Check if we have enough balance
        assert!(coin::value(&coin) >= amount, EInsufficientBalance);

        // Split the coin
        let transfer_coin = coin::split(&mut coin, amount, ctx);
        
        // Transfer to recipient
        transfer::public_transfer(transfer_coin, recipient);
        
        // Return remaining coins to sender
        if (coin::value(&coin) > 0) {
            transfer::public_transfer(coin, tx_context::sender(ctx));
        } else {
            coin::destroy_zero(coin);
        }
    }

    /// Get balance of a coin
    public fun balance(coin: &Coin<SIMPLE_TOKEN>): u64 {
        coin::value(coin)
    }

    /// Mint additional tokens (only treasury cap holder can call)
    public fun mint(
        treasury_cap: &mut coin::TreasuryCap<SIMPLE_TOKEN>,
        amount: u64,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let new_coin = coin::mint(treasury_cap, amount, ctx);
        transfer::public_transfer(new_coin, recipient);
    }

    /// Burn tokens
    public fun burn(
        treasury_cap: &mut coin::TreasuryCap<SIMPLE_TOKEN>,
        coin: Coin<SIMPLE_TOKEN>
    ) {
        coin::burn(treasury_cap, coin);
    }
}
