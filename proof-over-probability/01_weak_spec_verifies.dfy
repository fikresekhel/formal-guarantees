// Example 1 — The trap: code that "verifies", but against the wrong property.
//
// This is the kind of withdraw() an AI agent happily generates, carrying the
// obvious-looking postcondition "the balance never goes negative".
// Dafny PROVES it. Unit tests with positive amounts pass. A scanner sees a
// bounds check guarding the subtraction and is satisfied.
//
// Run:  dafny verify 01_weak_spec_verifies.dfy   ->  verification SUCCEEDS

method Withdraw(balance: int, amount: int) returns (newBalance: int)
  requires balance >= 0
  ensures  newBalance >= 0          // <-- the only property anyone stated
{
  if amount <= balance {
    newBalance := balance - amount;
  } else {
    newBalance := balance;
  }
}
