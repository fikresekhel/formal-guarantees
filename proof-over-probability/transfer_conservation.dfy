// Bonus — stating a stronger invariant than any test suite encodes:
// conservation of funds. Money is neither created nor destroyed by a transfer.
//
// The postcondition  newFrom + newTo == from + to  is a GLOBAL invariant that
// matters for a wallet/ledger and that example-based testing can never
// establish — it holds for ALL inputs, or Dafny shows you where it breaks.
//
// Run:  dafny verify transfer_conservation.dfy   ->  verification SUCCEEDS

method Transfer(from: int, to: int, amount: int)
    returns (newFrom: int, newTo: int)
  requires from >= 0 && to >= 0
  ensures  newFrom >= 0 && newTo >= 0
  ensures  newFrom + newTo == from + to      // conservation of funds
{
  if 0 <= amount <= from {
    newFrom := from - amount;
    newTo   := to + amount;
  } else {
    newFrom := from;
    newTo   := to;
  }
}
