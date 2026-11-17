/-
Piece 3, part 2 -- "The LLM proposes, the kernel disposes."

An LLM is asked to prove a security property about a BUGGY transfer (the guard
on the amount is missing). It returns a confident proof. Lean does not care how
sure the model was: a proof counts only if the kernel checks it.

Check it:  lean llm_proposes.lean
-/

structure Ledger where
  a : Int
  b : Int

/-- Buggy transfer: the `0 ≤ amount` guard is missing. -/
def transferBuggy (l : Ledger) (amount : Int) : Ledger :=
  if amount ≤ l.a then
    { a := l.a - amount, b := l.b + amount }
  else
    l

/-
The LLM claims: "account b never goes negative, as long as it started
non-negative -- a transfer only moves money around." It emits, confidently:

    theorem b_stays_nonneg (l : Ledger) (amt : Int) (h : 0 ≤ l.b) :
        0 ≤ (transferBuggy l amt).b := by
      unfold transferBuggy
      split
      · omega          -- claims the goal `0 ≤ l.b + amt` here
      · exact h

Lean REJECTS it. In the `then` branch the goal is `0 ≤ l.b + amt`, and with a
NEGATIVE amt that is not provable: `omega` reports "unsolved goals" and the file
does not compile. "The model was sure" is not an input the kernel accepts.
(Uncomment to watch it fail.)
-/

/-- And the claim is not merely unproven -- it is false. We prove the negation,
    with a witness: l = ⟨0, 0⟩, amt = -1 drives account b to -1. A negative
    "transfer" drains the account. The counterexample is itself a theorem. -/
theorem b_can_go_negative :
    ∃ (l : Ledger) (amt : Int), 0 ≤ l.b ∧ (transferBuggy l amt).b < 0 := by
  refine ⟨{ a := 0, b := 0 }, -1, by decide, by decide⟩
