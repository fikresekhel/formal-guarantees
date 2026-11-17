// Example 2 — The real security property: a withdrawal must never INCREASE funds.
//
// Exactly the same code as Example 1. We only add the invariant that actually
// matters: a withdrawal cannot leave you richer than you started.
//
// Run:  dafny verify 02_real_property_fails.dfy   ->  verification FAILS
//
// Dafny does not say "looks suspicious" (a probability). It returns a concrete
// counterexample, e.g.  balance = 0, amount = -1  =>  newBalance = 1.
// A negative "withdrawal" passes `amount <= balance` and runs balance - (-1),
// minting money from nothing. The vulnerability is exhibited as an exact input,
// not a confidence score.

method Withdraw(balance: int, amount: int) returns (newBalance: int)
  requires balance >= 0
  ensures  newBalance >= 0
  ensures  newBalance <= balance    // <-- the property that exposes the bug
{
  if amount <= balance {
    newBalance := balance - amount;
  } else {
    newBalance := balance;
  }
}
