// Example 3 — The fix, now carrying a proof.
//
// Stop trusting the caller to pass a sane amount; enforce it in code.
// Both properties now hold for EVERY possible (balance, amount): there is no
// input, anywhere, that makes a withdrawal create money or go negative.
//
// Run:  dafny verify 03_fixed_verified.dfy   ->  verification SUCCEEDS

method Withdraw(balance: int, amount: int) returns (newBalance: int)
  requires balance >= 0
  ensures  newBalance >= 0
  ensures  newBalance <= balance
{
  if 0 <= amount <= balance {
    newBalance := balance - amount;
  } else {
    newBalance := balance;      // reject negative or over-balance amounts
  }
}
