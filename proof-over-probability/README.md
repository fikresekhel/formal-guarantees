# Proof over probability

**A small, self-contained demonstration: a wallet `withdraw()` that passes its
tests, satisfies a scanner, and even carries a machine-checked proof — while
still letting a user mint money. And how one line of formal specification turns
that silent vulnerability into an exact counterexample.**

AI agents now write a large share of production code. The tooling that reviews
it — SAST, DAST, SCA, AI triage — reports *findings*, ranked by confidence.
State-of-the-art precision sits around 97%: about 97 of every 100 alerts are
real vulnerabilities. That is excellent for the volume problem. It says nothing
about the bug that was never raised as an alert, because no tool was reasoning
about the property it violates.

This repository shows one such bug, on ~8 lines of code, and the difference
between *detecting* and *guaranteeing*.

## The code

An AI agent is asked for a withdrawal function. It produces the obvious thing:

```dafny
method Withdraw(balance: int, amount: int) returns (newBalance: int)
  requires balance >= 0
  ensures  newBalance >= 0
{
  if amount <= balance {
    newBalance := balance - amount;
  } else {
    newBalance := balance;
  }
}
```

It even states the postcondition everyone expects: *the balance never goes
negative.* Dafny **proves it** (`01_weak_spec_verifies.dfy`). Unit tests with
positive amounts pass. A scanner sees a bounds check guarding the subtraction
and moves on.

Everything is green. The code is wrong.

## The property nobody stated

What a withdrawal must actually guarantee is not only "balance stays
non-negative" — it is that **a withdrawal cannot leave you richer than you
started**:

```dafny
  ensures newBalance <= balance
```

Add that one line to the *same code* (`02_real_property_fails.dfy`) and
verification **fails**. Dafny does not return a hunch; it returns a witness:

```
balance = 0, amount = -1   =>   newBalance = 1
```

A negative "withdrawal" passes the `amount <= balance` check and runs
`balance - (-1)`, creating funds out of nothing. The weak postcondition
`newBalance >= 0` was *true* the whole time (`1 >= 0`) — which is exactly why
the first proof, every test, and the scanner all stayed green. The
vulnerability lived in the gap between the code and a property no one had
written down.

(If this feels abstract: it is the shape of bug that drains real ledgers — a
signed amount, a crafted or replayed request, an integer that wraps. A wallet
that debits on an unvalidated amount is a withdrawal that mints money.)

## The fix, carrying a proof

Stop trusting the caller; enforce the bound in code
(`03_fixed_verified.dfy`):

```dafny
  if 0 <= amount <= balance {
    newBalance := balance - amount;
  } else {
    newBalance := balance;
  }
```

Now both `newBalance >= 0` and `newBalance <= balance` hold for **every**
`(balance, amount)` — not for the inputs a test happened to try, but for all of
them, checked by the solver. `transfer_conservation.dfy` goes one step further
and proves *conservation of funds* across a two-account transfer
(`newFrom + newTo == from + to`): money is neither created nor destroyed, a
global invariant example-based testing can never establish.

## The point

- A scanner's 97% precision is about the findings that *exist*. It cannot rank
  a finding it never generated.
- Tests check the inputs you thought of. A proof checks the inputs you didn't —
  and hands you the exact one that breaks the invariant.
- The engineering that matters here is **naming the real property**
  (`newBalance <= balance`, conservation of funds, constant-time, "this
  authorization check cannot be bypassed"). Once stated, it is either proved for
  all inputs or refuted with a concrete counterexample. No probability.

This does not replace scanners or AI review. It sits on top of them, on the
small critical core where "probably safe" is not good enough: the money path,
the authorization check, the cryptography, the AI-generated hot path. That core
is exactly where a guarantee is worth paying for.

## Reproduce it

Install Dafny (<https://dafny.org>) and run:

```bash
dafny verify 01_weak_spec_verifies.dfy    # SUCCEEDS — but against the wrong property
dafny verify 02_real_property_fails.dfy   # FAILS   — prints the counterexample
dafny verify 03_fixed_verified.dfy        # SUCCEEDS — guarantee established
dafny verify transfer_conservation.dfy    # SUCCEEDS — conservation of funds
```

Or paste each file into the Dafny playground: <https://dafny.org/dafny/OnlineTutorial/>

*Note on integers:* Dafny's `int` is unbounded (mathematical). Fixed-width
machine integers add a second failure mode — overflow/underflow — which the
same method of stating and proving the invariant catches. That is the natural
next example.
