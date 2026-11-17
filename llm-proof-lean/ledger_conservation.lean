/-
Piece 3 of a series on formal guarantees for security-critical code.
Lean 4, no external dependencies (core + `omega` only).

Showcase: a security invariant proved by INDUCTION over every possible history,
not tested on sample traces. Conservation of funds -- no sequence of transfers,
however long or adversarial, creates or destroys money.

Check it:  lean ledger_conservation.lean   (no output == every theorem accepted)
-/

structure Ledger where
  a : Int
  b : Int

def total (l : Ledger) : Int := l.a + l.b

/-- Move `amount` from account a to account b, only if the amount is
    non-negative and covered by a. Otherwise leave the ledger unchanged. -/
def transfer (l : Ledger) (amount : Int) : Ledger :=
  if 0 ≤ amount ∧ amount ≤ l.a then
    { a := l.a - amount, b := l.b + amount }
  else
    l

/-- One transfer conserves the total. -/
theorem transfer_conserves (l : Ledger) (amt : Int) :
    total (transfer l amt) = total l := by
  unfold transfer
  split
  · show (l.a - amt) + (l.b + amt) = l.a + l.b
    omega
  · rfl

/-- Apply a whole list of transfers, left to right. -/
def applyAll (l : Ledger) : List Int → Ledger
  | []          => l
  | amt :: rest => applyAll (transfer l amt) rest

/-- The real guarantee: NO sequence of transfers changes the total.
    Proved by induction on the list -- it holds for all histories at once. -/
theorem applyAll_conserves (l : Ledger) (amts : List Int) :
    total (applyAll l amts) = total l := by
  induction amts generalizing l with
  | nil => rfl
  | cons amt rest ih =>
      simp only [applyAll]
      rw [ih (transfer l amt)]
      exact transfer_conserves l amt
