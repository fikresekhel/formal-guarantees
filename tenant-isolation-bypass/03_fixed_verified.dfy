// Example 3 — The fix, now carrying a proof.
//
// Check the tenant FIRST, then the role. Tenant isolation becomes a theorem
// that holds for every possible input -- and we also prove the fix did not
// over-restrict: legitimate owners and in-tenant admins are still allowed.
// A good security fix has to prove both: the attack is gone AND the feature works.
//
// Run:  dafny verify 03_fixed_verified.dfy   ->  verification SUCCEEDS

datatype Role = User | Admin

function CanRead(userTenant: int, role: Role, docTenant: int, docOwner: int, userId: int): bool
{
  userTenant == docTenant && (role == Admin || docOwner == userId)
}

// Safety: access implies same tenant, for ALL inputs.
lemma TenantIsolation(userTenant: int, role: Role, docTenant: int, docOwner: int, userId: int)
  ensures CanRead(userTenant, role, docTenant, docOwner, userId) ==> userTenant == docTenant
{}

// Liveness: the fix did not break legitimate access.
lemma OwnerCanStillRead(t: int, uid: int)
  ensures CanRead(t, User, t, uid, uid)
{}

lemma AdminCanStillReadOwnTenant(t: int, owner: int, uid: int)
  ensures CanRead(t, Admin, t, owner, uid)
{}
