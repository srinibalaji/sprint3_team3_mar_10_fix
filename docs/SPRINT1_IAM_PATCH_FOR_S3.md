# ─────────────────────────────────────────────────────────────
# STAR ELZ V1 — Sprint 1 IAM Patch for Sprint 3
# File: SPRINT1_IAM_PATCH_FOR_S3.md
#
# Sprint 3 requires IAM grants that don't exist in Sprint 1.
# These must be added BEFORE Sprint 3 ORM apply.
# ─────────────────────────────────────────────────────────────

## Problem

Sprint 2 created the Bastion service (`bas_r_elz_nw_hub`) in compartment
`C1_R_ELZ_NW`. Sprint 3 creates Bastion **sessions** on that service.

The Sprint 1 `UG_ELZ_SEC-Policy` has:
```
allow UG_ELZ_SEC to manage bastion-family in compartment C1_R_ELZ_SEC
```

But the Bastion service is in `C1_R_ELZ_NW`, not `C1_R_ELZ_SEC`.
No existing policy grants `manage bastion-session-family` in `C1_R_ELZ_NW`.

**This gap also affects Sprint 2:** The Bastion service was created successfully
via ORM (admin principal), but `UG_ELZ_NW` team members cannot manage it via CLI
(would get HTTP 403). The patch below fixes both Sprint 2 CLI access and Sprint 3
session creation in one shot.

## Sprint 1 ↔ Sprint 2 IAM Verification (Complete)

Every Sprint 2 resource was audited against Sprint 1 policies:

| Sprint 2 Resource | OCI Verb | Compartment | Policy | Status |
|---|---|---|---|---|
| VCNs (5) | manage virtual-network-family | C1_R_ELZ_NW + spoke cmps | UG_ELZ_NW + UG_*_ELZ_NW | ✅ |
| Subnets (6) | manage virtual-network-family | C1_R_ELZ_NW + spoke cmps | UG_ELZ_NW + UG_*_ELZ_NW | ✅ |
| DRGs (2) | manage drgs | C1_R_ELZ_NW | UG_ELZ_NW | ✅ |
| DRG attachments (5) | manage drgs | C1_R_ELZ_NW (DRG location) | UG_ELZ_NW (ORM admin) | ✅ |
| Route tables (6) | manage virtual-network-family | C1_R_ELZ_NW + spoke cmps | UG_ELZ_NW + UG_*_ELZ_NW | ✅ |
| Security lists (6) | manage virtual-network-family | C1_R_ELZ_NW + spoke cmps | UG_ELZ_NW + UG_*_ELZ_NW | ✅ |
| Sim FW instances (4) | manage instances | C1_R_ELZ_NW + spoke cmps | UG_ELZ_NW + UG_*_ELZ_NW | ✅ |
| Bastion service (1) | manage bastion-family | C1_R_ELZ_NW | **MISSING** — ORM works, CLI 403 | ⚡ Fixed by patch |

All Sprint 2 resources work via ORM (admin principal). The only gap is CLI/Console
access for `UG_ELZ_NW` members to the Bastion service — fixed by this patch.

## Required Sprint 1 Policy Changes

### Option A — Add to UG_ELZ_NW-Policy (Recommended)

The NW team owns the Hub compartment. Bastion sessions connect to NW instances.
Add this statement to `iam_policies_team1.tf` inside the NW policy:

```hcl
"allow group UG_ELZ_NW to manage bastion-family in compartment C1_R_ELZ_NW"
```

This lets UG_ELZ_NW create/manage Bastion sessions targeting compute instances
in C1_R_ELZ_NW (Hub Sim FW, spoke Sim FWs). The Bastion service itself was
created by UG_ELZ_NW in Sprint 2 (which worked because T4 used `manage instances`
— but Bastion is a separate resource family in OCI IAM).

### Option B — Cross-compartment grant in UG_ELZ_SEC-Policy

If security team should own Bastion sessions:
```hcl
"allow group UG_ELZ_SEC to manage bastion-family in compartment C1_R_ELZ_NW"
```

### Also needed: Bastion session target access

Bastion sessions targeting Sim FW instances also need the session creator to have
`read instance-family` on the target instance compartment. For spoke instances
(OS Sim FW in C1_OS_ELZ_NW, TS Sim FW in C1_TS_ELZ_NW):

UG_ELZ_NW already has: `read virtual-network-family in C1_OS_ELZ_NW` etc.
But Bastion needs `read instance-agent-plugins` on the target.

Add to UG_ELZ_NW-Policy:
```hcl
"allow group UG_ELZ_NW to read instance-agent-plugins in compartment C1_OS_ELZ_NW"
"allow group UG_ELZ_NW to read instance-agent-plugins in compartment C1_TS_ELZ_NW"
"allow group UG_ELZ_NW to read instance-agent-plugins in compartment C1_SS_ELZ_NW"
"allow group UG_ELZ_NW to read instance-agent-plugins in compartment C1_DEVT_ELZ_NW"
```

Or, simpler broad approach:
```hcl
"allow group UG_ELZ_NW to read instance-family in compartment C1_OS_ELZ_NW"
"allow group UG_ELZ_NW to read instance-family in compartment C1_TS_ELZ_NW"
"allow group UG_ELZ_NW to read instance-family in compartment C1_SS_ELZ_NW"
"allow group UG_ELZ_NW to read instance-family in compartment C1_DEVT_ELZ_NW"
```

## Summary — Statements to Add

| Policy | New Statement | Reason |
|---|---|---|
| UG_ELZ_NW-Policy | `allow UG_ELZ_NW to manage bastion-family in compartment C1_R_ELZ_NW` | Create Bastion sessions |
| UG_ELZ_NW-Policy | `allow UG_ELZ_NW to read instance-family in compartment C1_OS_ELZ_NW` | Bastion → OS Sim FW target |
| UG_ELZ_NW-Policy | `allow UG_ELZ_NW to read instance-family in compartment C1_TS_ELZ_NW` | Bastion → TS Sim FW target |
| UG_ELZ_NW-Policy | `allow UG_ELZ_NW to read instance-family in compartment C1_SS_ELZ_NW` | Bastion → SS Sim FW target |
| UG_ELZ_NW-Policy | `allow UG_ELZ_NW to read instance-family in compartment C1_DEVT_ELZ_NW` | Bastion → DEVT Sim FW target |
| UG_ELZ_SEC-Policy | `allow UG_ELZ_SEC to manage security-zone in compartment C1_R_ELZ_SEC` | Security Zone on SEC cmp |
| UG_ELZ_SEC-Policy | `allow UG_ELZ_SEC to manage security-zone in compartment C1_R_ELZ_NW` | Security Zone on NW cmp |

**Total: 5 new statements in UG_ELZ_NW-Policy + 2 new statements in UG_ELZ_SEC-Policy = 7 statements**

## When to Apply

**At the start of Sprint 3 day (9 March), before Sprint 3 ORM apply.**

This is a **Sprint 1 ORM re-apply** — not a manual Console change. The process:

1. Add the 5 new statements to Sprint 1 `iam_policies_team1.tf` (in the `nw_admin_grants` list)
2. Commit and push to `main`
3. Go to Sprint 1 ORM stack in OCI Console
4. Plan → verify: "+5 statements added to UG_ELZ_NW-Policy" (no destroy)
5. Apply
6. Verify with CLI (see below)
7. Then proceed to Sprint 3 ORM stack Plan → Apply

This is **additive only** — no existing resources are modified or destroyed.
ORM will show "1 changed" (the policy object gets 5 additional statements).
All existing compartments, groups, tags remain untouched.

**Why re-apply Sprint 1 instead of doing it manually in Console?**

Manual Console edits to IAM policies create Terraform drift. Next time the
Sprint 1 ORM stack is applied (e.g. Sprint 4 adding SIM policies), Terraform
would see the manually-added statements and try to remove them. Keeping
everything in IaC means Sprint 1 state stays clean.

**Does this also fix Sprint 2?**

Yes. Sprint 2 created the Bastion service (`bas_r_elz_nw_hub`) via ORM admin
principal, so creation worked. But if a `UG_ELZ_NW` team member tried to manage
the Bastion via CLI, they'd get 403. The `manage bastion-family` grant fixes
this for both Sprint 2 CLI validation and Sprint 3 session creation.

## Verification

```bash
# Verify the policy was updated
oci iam policy get --policy-id $NW_POLICY_ID --query 'data.statements' --output table

# Test: attempt to create a bastion session as UG_ELZ_NW member
oci bastion session create \
  --bastion-id $BASTION_ID \
  --key-type PUB \
  --session-type MANAGED_SSH \
  --target-resource-id $OS_FW_INSTANCE_ID \
  --target-os-username opc \
  --target-port 22 \
  --ssh-public-key-file ~/.ssh/id_rsa.pub
# Expected: session created (200)
# Without patch: 403 Authorization failed
```
