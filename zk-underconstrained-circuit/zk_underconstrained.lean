/-
Piece 5 of a series on formal guarantees for security-critical code.
Lean 4, no external dependencies (core + `omega`).

ZK circuit soundness -- the #1 bug class in zero-knowledge audits: the
UNDER-CONSTRAINED circuit. If a circuit's constraints can be satisfied by a
witness that was never meant to be valid, a prover can "prove" a false
statement. We model a 2-to-1 multiplexer gadget and show, machine-checked, that
the naive version is UNSOUND and the booleanity-constrained version is SOUND for
every witness.

Signals are modeled over the integers. A real circuit lives in a prime field
F_p; the only property this argument uses is the absence of zero divisors
(x * y = 0  ->  x = 0 or y = 0), which Z and F_p share. The "malicious" witness
sel = 2 is just as available to a prover in F_p.

Check it:  lean zk_underconstrained.lean   (no output == every theorem accepted)
-/

-- A 2-to-1 multiplexer gadget, as compiled to one R1CS constraint:
--   out = b + sel * (a - b)
-- Intended behavior: sel = 1 selects a, sel = 0 selects b.
def muxConstraint (sel a b out : Int) : Prop :=
  out = b + sel * (a - b)

-- Soundness: any witness accepted by the circuit has out equal to a or to b.
def muxSound (sel a b out : Int) : Prop :=
  out = a ∨ out = b

-- The naive circuit is UNDER-CONSTRAINED: a witness satisfies the one
-- constraint yet breaks soundness. The prover simply chooses sel = 2 (never
-- forbidden), giving out = 2*a - b, which is neither a nor b.
theorem mux_is_unsound :
    ∃ (sel a b out : Int), muxConstraint sel a b out ∧ ¬ muxSound sel a b out := by
  refine ⟨2, 1, 0, 2, ?_, ?_⟩
  · unfold muxConstraint; decide
  · unfold muxSound; decide

-- The fix: constrain sel to be a bit with  sel * (sel - 1) = 0.
def muxFixed (sel a b out : Int) : Prop :=
  out = b + sel * (a - b) ∧ sel * (sel - 1) = 0

-- With the booleanity constraint, the circuit is SOUND for every witness.
theorem mux_fixed_is_sound (sel a b out : Int) (h : muxFixed sel a b out) :
    muxSound sel a b out := by
  obtain ⟨hout, hbit⟩ := h
  rcases Int.mul_eq_zero.mp hbit with h0 | h1
  · -- sel = 0  =>  out = b
    subst h0
    right; omega
  · -- sel - 1 = 0, i.e. sel = 1  =>  out = a
    have hs : sel = 1 := by omega
    subst hs
    left; omega
