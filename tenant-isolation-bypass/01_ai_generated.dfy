// Example 1 — The AI-generated access check, and the tests that bless it.
//
// Task given to the agent: "A user may read a document if they are an admin,
// or if the document is in their tenant and they own it."
// The agent returns the function below and the positive checks it writes for
// itself all pass. Green. Looks correct.
//
// Run:  dafny verify 01_ai_generated.dfy   ->  verification SUCCEEDS

datatype Role = User | Admin

function CanRead(userTenant: int, role: Role, docTenant: int, docOwner: int, userId: int): bool
{
  role == Admin || (userTenant == docTenant && docOwner == userId)
}

// The kind of positive cases a test suite (or the agent itself) checks.
lemma OwnerCanReadOwnDoc(t: int, uid: int)
  ensures CanRead(t, User, t, uid, uid)
{}

lemma AdminCanReadDocInOwnTenant(t: int, owner: int, uid: int)
  ensures CanRead(t, Admin, t, owner, uid)
{}
