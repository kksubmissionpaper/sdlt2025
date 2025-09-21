/// Module: example_nft2
///module example_nft::example_nft2;

/// For Move coding conventions, see
/// https://docs.sui.io/concepts/sui-move-concepts/conventions

module example_nft2::nft {
    use sui::url::{Self, Url};
    use std::string;
    use sui::event;
    
    /// Declare NFT
    public struct ExampleNFT has key, store {
        id: UID,
        // NFT name
        name: string::String,
        // Desc
        description: string::String,
        // NFT picture URL
        url: Url,
    }
    
    /// Capability - Admin
    public struct AdminCap has key, store {
        id: UID
    }
    
    // Events
    /// when a NFT mints
    public struct NFTMinted has copy, drop {
        // object ID
        object_id: ID,
        // created by
        creator: address,
        // owner
        owner: address,
    }
    
    /// Func to initialize module
    fun init(ctx: &mut TxContext) {
        // Create AdminCap, sent to a user who deployed the NTF
        let admin_cap = AdminCap {
            id: object::new(ctx)
        };
        transfer::transfer(admin_cap, tx_context::sender(ctx));
    }
    
    /// Func to mint NFT（AdminCap only）
    public fun mint(
        _: &AdminCap,
        name: vector<u8>,
        description: vector<u8>,
        url_string: vector<u8>,
        recipient: address,
        ctx: &mut TxContext
    ) {
        let nft = ExampleNFT {
            id: object::new(ctx),
            name: string::utf8(name),
            description: string::utf8(description),
            url: url::new_unsafe_from_bytes(url_string)
        };
        
        // Publish event
        event::emit(NFTMinted {
            object_id: object::id(&nft),
            creator: tx_context::sender(ctx),
            owner: recipient,
        });
        
        // NFT send out to a receiver
        transfer::transfer(nft, recipient);
    }
    
    /// Func to transfer NFT（by an owner）
    #[allow(lint(custom_state_change))]
    public fun transfer_nft(
        nft: ExampleNFT,
        recipient: address,
        _ctx: &mut TxContext
    ) {
        transfer::transfer(nft, recipient);
    }
    
    /// getter functions
    public fun name(nft: &ExampleNFT): &string::String {
        &nft.name
    }
    
    public fun description(nft: &ExampleNFT): &string::String {
        &nft.description
    }
    
    public fun url(nft: &ExampleNFT): &Url {
        &nft.url
    }
}
