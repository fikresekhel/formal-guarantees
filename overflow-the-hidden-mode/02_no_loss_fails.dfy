// Example 2 -- The property that matters: a deposit must never REDUCE a balance.
// No funds may be lost. Same code as Example 1.
//
// Run:  dafny verify 02_no_loss_fails.dfy   ->  FAILS
//
// Counterexample (unsigned 64-bit):
//   balance = 0xFFFFFFFFFFFFFFFF, amount = 1  =>  newBalance = 0  <  balance
// The deposit wrapped past the 64-bit ceiling and the funds vanished. No crash,
// no runtime error -- just a wrong number.

type u64 = bv64

method Deposit(balance: u64, amount: u64) returns (newBalance: u64)
  ensures balance <= newBalance              // <-- no funds lost to overflow
{
  newBalance := balance + amount;
}
