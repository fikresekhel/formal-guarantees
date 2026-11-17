# The admin who could read every tenant

**Piece 2 of a series on formal guarantees for security-critical code.**
[Piece 1 — Proof over probability](../proof-over-probability) showed a
scanner-clean `withdraw()` that mints money. This one is pure "AI-native": an
agent writes a plausible authorization check, its tests pass, and a single
formal invariant proves it lets an admin read every other tenant's data.

## The task

*"Write an access check: a user may read a document if they are an admin, or if
the document is in their tenant and they own it."* An AI agent returns:

```dafny
function CanRead(userTenant: int, role: Role, docTenant: int, docOwner: int, userId: int): bool
{
  role == Admin || (userTenant == docTenant && docOwner == userId)
}
```

It reads perfectly: admins can read everything, owners can read their own
documents. The positive tests the agent writes for itself all pass
(`01_ai_generated.dfy`):

- an owner reading their own document in their tenant → allowed ✓
- an admin reading a document in their tenant → allowed ✓

Green. Ship it.

## The property nobody encoded

In a multi-tenant system the non-negotiable invariant is **tenant isolation**:
being granted access to a document implies you are in its tenant. No
exceptions — not even for admins, whose power is scoped to their own tenant.

State it (`02_tenant_isolation_fails.dfy`):

```dafny
ensures CanRead(userTenant, role, docTenant, docOwner, userId) ==> userTenant == docTenant
```

Verification **fails**, on exactly that invariant. The input that breaks it:

```
role = Admin, userTenant = 0, docTenant = 1   =>   CanRead = true, but 0 != 1
```

The `role == Admin` branch grants access **before** the tenant is ever checked.
An admin in tenant 0 reads documents in tenant 1 — a cross-tenant data breach,
written by an agent, passing every positive test, because no test and no scanner
was reasoning about the invariant "access implies same tenant." The whole bug is
one misplaced `||`.

## The fix, carrying a proof

Tenant first, role second (`03_fixed_verified.dfy`):

```dafny
function CanRead(userTenant: int, role: Role, docTenant: int, docOwner: int, userId: int): bool
{
  userTenant == docTenant && (role == Admin || docOwner == userId)
}
```

Now `CanRead ==> userTenant == docTenant` holds for **every** input — tenant
isolation is a theorem, not a hope. The same file also proves the fix did not
over-restrict: an owner and an in-tenant admin are still granted access. A good
security fix has to prove both directions — that the attack is gone *and* that
the feature still works.

## The point

- The bug was not a missing check; it was a correct-looking check in the wrong
  order. Pattern-based tools see the pieces (`Admin`, tenant equality,
  ownership) and have no reason to object.
- Positive tests confirm the cases you imagined. The invariant
  `access ⇒ same tenant` is a statement over **all** inputs; the prover either
  establishes it or hands you the escalation scenario.
- This is the flaw multiplying as agents write authorization code: plausible,
  test-passing, and catastrophic. The defense is to state the invariant for the
  critical paths and let a solver decide — no probability.

## Reproduce it

```bash
dafny verify 01_ai_generated.dfy           # SUCCEEDS — positive tests pass
dafny verify 02_tenant_isolation_fails.dfy # FAILS   — prints the cross-tenant counterexample
dafny verify 03_fixed_verified.dfy         # SUCCEEDS — isolation proved, access preserved
```

Dafny: <https://dafny.org>. Playground: <https://dafny.org/dafny/OnlineTutorial/>
