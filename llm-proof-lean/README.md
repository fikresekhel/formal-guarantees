# The LLM proposes, the kernel disposes

**Piece 3 of a series on formal guarantees for security-critical code.**
Pieces [1](../proof-over-probability) and [2](../tenant-isolation-bypass) used
Dafny to verify code. This one uses **Lean 4** and makes the AI-native point
directly: as language models start writing not just code but *proofs*, what
makes a proof trustworthy is not the model's confidence — it is that a kernel
checked it. The model may hallucinate; the kernel cannot be fooled.

## A guarantee over every history, not every test

`ledger_conservation.lean` models a two-account ledger and a `transfer` that
moves money only when the amount is non-negative and covered. The headline is
not the single-step property — it is this:

```lean
theorem applyAll_conserves (l : Ledger) (amts : List Int) :
    total (applyAll l amts) = total l
```

*No sequence of transfers — of any length, including adversarial ones — changes
the total.* It is proved by induction over the list, so it holds for **all**
histories at once. A test suite runs the traces you thought of; this is a
statement about every trace there will ever be.

## The part that matters for AI-written proofs

`llm_proposes.lean` is the real point. An LLM is asked to prove a security claim
about a *buggy* transfer (the `0 ≤ amount` guard is missing): *"account b never
goes negative — a transfer only moves money around."* It returns, confidently:

```lean
theorem b_stays_nonneg (l : Ledger) (amt : Int) (h : 0 ≤ l.b) :
    0 ≤ (transferBuggy l amt).b := by
  unfold transferBuggy
  split
  · omega        -- claims the goal `0 ≤ l.b + amt` here
  · exact h
```

Lean **rejects it**. In the `then` branch the goal is `0 ≤ l.b + amt`, and with
a negative `amt` that is false — `omega` reports *unsolved goals*, and the file
does not compile. The confident proof never ships, because "the model was sure"
is not an input the kernel accepts.

And the claim is not just unproven — it is false. We prove the negation, with a
witness:

```lean
theorem b_can_go_negative :
    ∃ (l : Ledger) (amt : Int), 0 ≤ l.b ∧ (transferBuggy l amt).b < 0 := by
  refine ⟨{ a := 0, b := 0 }, -1, by decide, by decide⟩
```

`l = ⟨0,0⟩, amt = -1` drives account b to `-1`: a negative "transfer" drains it.
The counterexample is itself a checked theorem.

## The point

- This is the workflow behind AI-assisted verification (AlphaProof, LeanDojo,
  and why AWS's Automated Reasoning group builds on Lean): let a model *propose*
  specs and proofs — fast, creative, often wrong — and let the kernel *dispose*.
  Acceptance equals truth; everything else is rejected, loudly.
- It is exactly the guarantee a 97%-precision scanner, or an LLM reviewing its
  own code, cannot give: there is no confidence score here, only a proof the
  kernel checked or a goal it refused to close.
- The scarce, non-automatable skill is stating the right theorem and closing the
  proof. The model accelerates it; it does not replace the person who guarantees it.

## Reproduce it

Install Lean 4 (<https://lean-lang.org>) and run:

```bash
lean ledger_conservation.lean   # no output == every theorem accepted by the kernel
lean llm_proposes.lean          # the counterexample checks; see the comment for the rejected proof
```

No mathlib required — core Lean 4 and `omega` only. These proofs are meant to be
run: the kernel is the arbiter, so if your toolchain wants a tactic spelled
differently (e.g. a `by decide` swapped for `by unfold transferBuggy; simp; omega`),
that is the guarantee layer doing its job, not a flaw in the claim.
