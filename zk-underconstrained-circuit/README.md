# Under-constrained: the circuit that proves a lie

**Piece 5 of a series on formal guarantees for security-critical code.**
This one is aimed squarely at the market that pays the most for formal methods —
zero-knowledge auditing. The dominant vulnerability class in ZK is the
**under-constrained circuit**: a constraint system loose enough that a prover can
satisfy it with a witness that was never meant to be valid, and thereby "prove"
something false. Here it is, machine-checked in Lean 4.

## The gadget

A 2-to-1 multiplexer — "if `sel` then `a` else `b`" — compiles to a single
arithmetic constraint:

```lean
def muxConstraint (sel a b out : Int) : Prop :=
  out = b + sel * (a - b)
```

With `sel = 1` it gives `out = a`; with `sel = 0`, `out = b`. The intended
guarantee (soundness) is that an accepted `out` is always one of `a` or `b`:

```lean
def muxSound (sel a b out : Int) : Prop := out = a ∨ out = b
```

## The circuit proves a lie

Nothing in the constraint forces `sel` to be a bit. A prover is free to choose
`sel = 2`, and the one constraint still holds — with `out = 2a - b`, which is
neither `a` nor `b`. That is a soundness break, and it is a theorem:

```lean
theorem mux_is_unsound :
    ∃ (sel a b out : Int), muxConstraint sel a b out ∧ ¬ muxSound sel a b out := by
  refine ⟨2, 1, 0, 2, ?_, ?_⟩
  · unfold muxConstraint; decide    -- 2 = 0 + 2*(1-0)   ✓ the constraint holds
  · unfold muxSound; decide         -- 2 = 1 ∨ 2 = 0     ✗ soundness violated
```

Lean confirms the witness `sel = 2, a = 1, b = 0, out = 2` satisfies the circuit
and breaks the intended relation. The proof such a circuit would accept is a lie.

## The fix, carrying a proof

Add the booleanity constraint `sel * (sel - 1) = 0` — the standard way a circuit
pins a signal to a bit:

```lean
def muxFixed (sel a b out : Int) : Prop :=
  out = b + sel * (a - b) ∧ sel * (sel - 1) = 0

theorem mux_fixed_is_sound (sel a b out : Int) (h : muxFixed sel a b out) :
    muxSound sel a b out := by
  obtain ⟨hout, hbit⟩ := h
  rcases Int.mul_eq_zero.mp hbit with h0 | h1
  · subst h0; right; omega           -- sel = 0  =>  out = b
  · have : sel = 1 := by omega
    subst this; left; omega          -- sel = 1  =>  out = a
```

`sel * (sel - 1) = 0` forces `sel ∈ {0, 1}` — this is exactly where the
*no-zero-divisors* property of the field does the work. With it, `out = a ∨ out = b`
holds for **every** witness, proved once and for all.

## The point

- Under-constraint is invisible to testing: every honest run picks `sel ∈ {0,1}`
  and passes. The attack is a witness no test generates — which is precisely what
  a soundness proof quantifies over.
- The argument rests on a field property (no zero divisors). That is the kind of
  statement a ZK auditor must get exactly right, and the kind formal methods
  settle rather than eyeball.
- Under-constrained circuits are *the* thing ZK audit firms (Veridise,
  zkSecurity, Certora) are paid to find. This is a miniature of that work.

## Modeling note

Signals are modeled over `Int`. A real circuit lives in a prime field `F_p`; the
only property used here is the absence of zero divisors, which `Z` and `F_p`
share, so the argument transfers unchanged. The malicious `sel = 2` is just as
available to a prover in `F_p`.

## Reproduce it

```bash
lean zk_underconstrained.lean    # exit 0 == every theorem accepted by the kernel
```

Core Lean 4 and `omega` only — no mathlib. (It prints one harmless
unused-variable style lint; the exit code is 0.)
