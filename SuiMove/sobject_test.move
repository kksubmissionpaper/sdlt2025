///This is a sample code intended to illustrate insecure design in the use of shared objects.

///create_bank() – Once calling share_object(), test "Bank" becomes a shared object, allowing anyone to obtain a mutable reference to it.
///deposit() / withdraw() – There are no owner checks in these functions, so anyone can arbitrarily increase or decrease the balance regardless of ownership.
module vulnerable_bank::vul_bank {
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;

    // Vulnerability: can be accessed by anyone as it is a shared object
    public struct Bank has key {
        id: UID,
        balance: Balance<SUI>,
        owner: address,  // Although there is an owner field, it is not actually enforced
    }

    // Create a test bank (shared as a shared object)
    public fun create_bank(ctx: &mut TxContext) {
        let bank = Bank {
            id: object::new(ctx),
            balance: balance::zero(),
            owner: tx_context::sender(ctx),
        };
        // Problem!: sharing the object via share_object makes it accessible to anyone
        transfer::share_object(bank);
    }

    // Vulnerability: deposit function has no owner check
    public fun deposit(bank: &mut Bank, payment: Balance<SUI>) {
        balance::join(&mut bank.balance, payment);
    }

    // Vulnerability: withdraw function has no owner check
    public fun withdraw(bank: &mut Bank, amount: u64, _ctx: &mut TxContext): Balance<SUI> {
        // No check whatsoever to ensure the caller is the owner!
        balance::split(&mut bank.balance, amount)
    }

}
