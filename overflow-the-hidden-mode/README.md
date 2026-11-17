# Overflow: the second failure mode

**Piece 4 of a series on formal guarantees for security-critical code.**
Pieces [1](../proof-over-probability) and [3](../llm-proof-lean) reasoned over
*mathematical* integers — unbounded, no overflow. Real money lives in
fixed-width integers, and that is where a second class of vulnerability hides: a
value that silently wraps. It is the single most expensive bug class in the
history of on-chain tokens.

## The code

Balances are 64-bit, exactly like on-chain token amounts. An AI writes a deposit
and the spec it "proves":

```dafny
type u64 = bv64

method Deposit(balance: u64, amount: u64) returns (newBalance: u64)
  ensures newBalance == balance + amount
{
  newBalance := balance + amount;
}
```

Dafny verifies it (`01_ai_deposit_wraps.dfy`). But the postcondition only
restates the assignment, and `+` on a 64-bit value **wraps modulo 2^64**. The
proof is green and says nothing a user would care about.

## The property that matters

A deposit must never *reduce* a balance — no funds may be lost
(`02_no_loss_fails.dfy`):

```dafny
  ensures balance <= newBalance
```

Verification **fails**, on exactly that postcondition. The input that breaks it:

```
balance = 0xFFFFFFFFFFFFFFFF, amount = 1   =>   newBalance = 0  <  balance
```

The deposit wrapped past the 64-bit ceiling and the balance collapsed to zero.
No crash, no runtime error — just a wrong number. Pieces 1–3 could never surface
this, because mathematical integers do not wrap; it appears only once the model
matches the machine.

## The fix, carrying a proof

Detect the wrap and refuse it — exactly what SafeMath and Solidity ≥ 0.8 do,
revert on overflow (`03_checked_deposit.dfy`):

```dafny
  if balance + amount >= balance {        // true iff the addition did not wrap
    newBalance := balance + amount; ok := true;
  } else {
    newBalance := balance;               // overflow rejected
    ok := false;
  }
```

Now `ok ==> balance <= newBalance` holds for **every** pair of 64-bit inputs,
proved by Z3's bitvector reasoning — there is no `balance`, no `amount`, that
makes a credited deposit lose funds.

## The point

- The bug is invisible to tests on small numbers and to a scanner: the code is a
  plain addition. It lives at the boundary of the type.
- It is the same lesson as the rest of the series, one level down: state the real
  invariant (*no funds lost*) and the solver either proves it over the whole
  64-bit space or hands you the value at the edge that breaks it.
- This is the exact class — integer overflow in token arithmetic — that formal
  verification is paid to rule out in smart-contract audits.

## Reproduce it

```bash
dafny verify 01_ai_deposit_wraps.dfy    # SUCCEEDS — but the spec is worthless
dafny verify 02_no_loss_fails.dfy       # FAILS   — the wrap loses funds
dafny verify 03_checked_deposit.dfy     # SUCCEEDS — no funds lost, over all 2^64
```

Dafny needs Z3; the files use 64-bit bitvectors (`bv64`), which Z3 decides exactly.
