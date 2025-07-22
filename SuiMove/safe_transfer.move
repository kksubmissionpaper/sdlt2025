module safe_transfer::safe_transfer {
    use sui::coin::Coin;
    ///sensing a coin (like external call)
    public entry fun send_coin(recipient: address, coin: Coin<u64>, _ctx: &mut TxContext) {
        transfer::public_transfer(coin, recipient);
        // No state update is necessary: the Coin resource is consumed, making double spending impossible.
    }
}
