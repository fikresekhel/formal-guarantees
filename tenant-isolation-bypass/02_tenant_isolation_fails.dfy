// Example 2 — The real security property: tenant isolation.
//
// Same function as Example 1. We add the non-negotiable multi-tenant invariant:
// being granted access to a document implies you are in its tenant. No
// exceptions -- an admin's power is scoped to their own tenant.
//
// Run:  dafny verify 02_tenant_isolation_fails.dfy   ->  verification FAILS
//
// Dafny returns a concrete escalation scenario, e.g.
//   role = Admin, userTenant = 0, docTenant = 1  =>  CanRead = true, but 0 != 1
// The `role == Admin` branch grants access BEFORE the tenant is ever checked:
// a cross-tenant data breach, written by an agent, passing every positive test.

datatype Role = User | Admin

function CanRead(userTenant: int, role: Role, docTenant: int, docOwner: int, userId: int): bool
{
  role == Admin || (userTenant == docTenant && docOwner == userId)
}

lemma TenantIsolation(userTenant: int, role: Role, docTenant: int, docOwner: int, userId: int)
  ensures CanRead(userTenant, role, docTenant, docOwner, userId) ==> userTenant == docTenant
{}
