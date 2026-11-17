// Example 3 -- The checked deposit, carrying a proof.
//
// Detect the wrap and refuse it -- exactly what SafeMath and Solidity >= 0.8 do
// (revert on overflow). The check `balance + amount >= balance` holds in
// unsigned arithmetic precisely when the addition did NOT wrap. Now "no funds
// lost" is a theorem over every pair of 64-bit inputs.
//
// Run:  dafny verify 03_checked_deposit.dfy   ->  SUCCEEDS

type u64 = bv64

method Deposit(balance: u64, amount: u64) returns (newBalance: u64, ok: bool)
  ensures ok ==> newBalance == balance + amount
  ensures ok ==> balance <= newBalance        // credited, and no funds lost
  ensures !ok ==> newBalance == balance        // overflow rejected, balance unchanged
{
  if balance + amount >= balance {
    newBalance := balance + amount;
    ok := true;
  } else {
    newBalance := balance;
    ok := false;
  }
}
