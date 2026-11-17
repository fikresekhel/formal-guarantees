# Formal guarantees for security-critical code

A short series on the difference between *detecting* a vulnerability — a
scanner's confidence score — and *guaranteeing* its absence with a
machine-checked proof, on the small critical core where "probably safe" is not
good enough: the money path, the authorization check, the cryptography, the
AI-generated hot path.

- **[Proof over probability](proof-over-probability)** — a wallet `withdraw()`
  that passes its tests, satisfies a scanner, and even carries a proof, yet lets
  a user mint money. One line of specification turns it into an exact
  counterexample.
- **[The admin who could read every tenant](tenant-isolation-bypass)** — an
  AI-generated authorization check that passes its tests while letting an admin
  read every other tenant's data. Tenant isolation, stated as a single
  invariant, refutes it.
- **[The LLM proposes, the kernel disposes](llm-proof-lean)** — a Lean 4 piece:
  an inductive proof that no sequence of transfers ever changes the total, and a
  demonstration that a confident but false LLM proof is rejected by the kernel,
  while the counterexample checks as a theorem.

Each piece is self-contained. Run `dafny verify` (Dafny pieces) or `lean` (the
Lean piece) on the files to reproduce the SUCCEEDS / FAILS yourself.

Built with [Dafny](https://dafny.org) and [Lean 4](https://lean-lang.org).
