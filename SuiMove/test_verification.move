module sui_eval::array_utils {
   /// example - contains func using for u64.
   /// Checks if the vector `xs` contains the element `e`.
   /// Returns true if `e` is found; false otherwise.
    public fun contains(xs: &vector<u64>, e: u64): bool {
        let mut i = 0;
        while (i < vector::length(xs)) {
            if (*vector::borrow(xs, i) == e) {
                return true
            };
            i = i + 1;
        };
        false
    }
}
