// Example 1 -- Balances are 64-bit, like on-chain token amounts: `+` WRAPS.
//
// Pieces 1-3 used mathematical integers (unbounded, no overflow). Real money
// lives in fixed-width integers, where a second failure mode hides: a value
// that silently wraps. Here is the AI's deposit, with the spec it "proves" --
// new balance = old + amount.
//
// Run:  dafny verify 01_ai_deposit_wraps.dfy   ->  SUCCEEDS (but says nothing useful)

type u64 = bv64

method Deposit(balance: u64, amount: u64) returns (newBalance: u64)
  ensures newBalance == balance + amount     // <-- only restates the assignment
{
  newBalance := balance + amount;
}
