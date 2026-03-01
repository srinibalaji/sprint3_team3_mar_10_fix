# STAR ELZ V1 — Sprint 1

**Branch:** `sprint1`  
**Module:** `github.com/oci-landing-zones/terraform-oci-modules-iam @ v0.3.1`  
**CIS Benchmark:** OCI Foundations v2.0, Level 1

## What This Is

Sprint 1 reference implementation. Fixes all naming drift, policy syntax, and 409 conflict issues.

| Sprint | Folder | Purpose |
|--------|--------|---------|
| `sprint1/` | **This folder** | Full solutions, all fixes applied |

---

## Key Changes from sprint1-solutions/

### SPRINT1-FIX: naming-drift
All 10 compartment names, 10 group names, 9 policy names moved to canonical constants in `locals.tf`. Replaced `"${var.service_label}-r-elz-nw-cmp"` (lowercase, variable-interpolated) with `"C1_R_ELZ_NW"` (uppercase constant). `service_label` now used **only** in tags and descriptions — never in resource names.

### SPRINT1-FIX: empty-collection-crash
Group name output locals changed from `[module.lz_groups.groups[key].name]` to direct constant references `[local.nw_group_name]`. Prevents plan failure during incremental workshop apply when a team's group map is `{}`.

### SPRINT1-FIX: policy-naming
9 policy objects now use canonical names (`UG_ELZ_NW-Policy`, `UG_ELZ_SEC-Policy`, etc.) derived from group name constants. Flattened from 4 objects to 2 for Team 1 (root vs compartment scope is in the WHERE clause, not the policy name).

### SPRINT1-FIX: module-dependency
`mon_tags.tf` replaced `lz_tags` module with direct resources. Tag namespace name is now the constant `"C0-star-elz-v1"` — immutable, never drifts with `service_label` changes.

### SPRINT1-FIX: enclosing-compartment
Replaced `iam_enclosing_compartment.tf` hard-creation with opt-in `iam_opt_in_enclosing.tf`. Default: all C1 compartments at tenancy root. Set `enable_enclosing_compartment = true` in ORM for workshop isolation.

### C2 Sub-Compartments (modular, opt-in)
Every team file has `children : {}` populated and documented. Set `enable_c2_compartments = true` and populate `children` in any team file to add Level 2 compartments without touching the orchestrator.

---

## C0/C1 Hierarchy Convention

| Level | Scope | Naming Pattern | Example |
|-------|-------|----------------|---------|
| C0 | Tenancy Root | No compartment — tag namespace lives here | `C0-star-elz-v1` |
| C1 | Level 1 compartments | `C1_<AGENCY>_ELZ_<FUNCTION>` | `C1_R_ELZ_NW` |
| C2 | Level 2 sub-compartments | `C2_<AGENCY>_<FUNCTION>` | `C2_SOC_LOGS` |
| Groups | Tenancy-scoped singletons | `UG_ELZ_<FUNCTION>` | `UG_ELZ_NW` |
| Policies | At tenancy root | `<GROUP_NAME>-Policy` | `UG_ELZ_NW-Policy` |

---

## File Map

| File | Team | Description |
|------|------|-------------|
| `locals.tf` | — | All canonical name constants. Single source of truth. |
| `variables_general.tf` | — | Tenancy, region, service_label, CIS level, tagging inputs |
| `variables_iam.tf` | — | Compartment overrides, enclosing, C2, sim compartment OCIDs |
| `providers.tf` | — | OCI + OCI home providers, Terraform ≥ 1.3.0 |
| `data_sources.tf` | — | Regions, tenancy, ADs, images |
| `iam_opt_in_enclosing.tf` | — | Enclosing compartment (count conditional) |
| `iam_compartments.tf` | — | lz_compartments module orchestrator |
| `iam_cmps_team1.tf` | T1 | C1_R_ELZ_NW, C1_R_ELZ_SEC |
| `iam_cmps_team2.tf` | T2 | C1_R_ELZ_SOC, C1_R_ELZ_OPS |
| `iam_cmps_team3.tf` | T3 | C1_R_ELZ_CSVCS, C1_R_ELZ_DEVT_CSVCS |
| `iam_cmps_team4.tf` | T4 | C1_OS_ELZ_NW, C1_SS_ELZ_NW, C1_TS_ELZ_NW, C1_DEVT_ELZ_NW |
| `iam_groups.tf` | — | lz_groups module orchestrator |
| `iam_groups_team1.tf` | T1 | UG_ELZ_NW, UG_ELZ_SEC |
| `iam_groups_team2.tf` | T2 | UG_ELZ_SOC, UG_ELZ_OPS |
| `iam_groups_team3.tf` | T3 | UG_ELZ_CSVCS, UG_DEVT_CSVCS |
| `iam_groups_team4.tf` | T4 | UG_OS_ELZ_NW, UG_SS_ELZ_NW, UG_TS_ELZ_NW, UG_DEVT_ELZ_NW |
| `iam_policies.tf` | — | lz_policies module orchestrator |
| `iam_policies_team1.tf` | T1 | UG_ELZ_NW-Policy, UG_ELZ_SEC-Policy |
| `iam_policies_team2.tf` | T2 | UG_ELZ_SOC-Policy, UG_ELZ_OPS-Policy |
| `iam_policies_team3.tf` | T3 | UG_ELZ_CSVCS-Policy, OCI-SERVICES-Policy |
| `iam_policies_team4.tf` | T4 | UG-SPOKE-NW-Policy |
| `mon_tags.tf` | T3 | Tag namespace C0-star-elz-v1, 4 tags, CreatedBy tag default |
| `outputs.tf` | — | 10 compartment OCIDs, group names, tag namespace OCID |
| `schema.yaml` | — | ORM UI schema — 5 sections |
| `terraform.tfvars.template` | — | Clean template — copy to terraform.tfvars |

---

## Sprint 1 → Sprint 2 Handoff Checklist

Run all test cases before declaring Sprint 1 complete.

### TC-01 — 10 TF-managed Compartments
```
terraform state list | grep compartments | wc -l
# Expected: 10
```
Verify in OCI Console: Identity → Compartments. All 10 names match `C1_*` constants.

### TC-01b — 2 Manual Compartments (Team 4)
- [ ] `C1_SIM_EXT` created in OCI Console
- [ ] `C1_SIM_CHILD` created in OCI Console
- [ ] OCIDs pasted into `terraform.tfvars`: `sim_ext_compartment_id`, `sim_child_compartment_id`
- [ ] `terraform output sim_ext_compartment_id` → non-empty
- [ ] `terraform output sim_child_compartment_id` → non-empty

### TC-02 — 12 Groups (10 TF + 2 Manual)
```
terraform state list | grep groups | wc -l
# Expected: 10 TF-managed groups
```
Console verification: Identity → Groups. All 10 `UG_ELZ_*` and `UG_*_ELZ_NW` groups present.  
Manual: `UG_SIM_EXT` and `UG_SIM_CHILD` visible in Console (not in TF state).

### TC-03 — Segregation of Duties (SoD) NEGATIVE Test
```bash
# Log in as a user in UG_DEVT_ELZ_NW
oci iam group create --compartment-id <C1_R_ELZ_SEC_OCID> --name test-group --description test
# Expected: HTTP 403 Authorization failed
# PASS if: error message contains "Authorization failed"
# FAIL if: group is created
```

### TC-04 — SOC Read-Only NEGATIVE Test
```bash
# Log in as a user in UG_ELZ_SOC
oci logging log-group delete --log-group-id <any_log_group_ocid>
# Expected: HTTP 403 Authorization failed
# PASS if: 403 received
# FAIL if: delete succeeds
```

### TC-05 — ELZ Tags Applied
```bash
terraform output tag_namespace_id
# Expected: non-empty OCID starting with ocid1.tagnamespace
```
Console: Governance → Tag Namespaces → `C0-star-elz-v1` → 4 tags present:
- `Environment`, `Owner`, `ManagedBy`, `CostCenter` (CostCenter has cost tracking = true)

Tag Default: Governance → Tag Defaults → `CreatedBy` applied to tenancy root.

### TC-06 — ORM Stack Apply Succeeded
- [ ] ORM Stack Apply Job status = **SUCCEEDED**
- [ ] No errors in Apply job log
- [ ] Apply job shows `Apply complete! Resources: N added, 0 changed, 0 destroyed`

### TC-06b — ORM Plan Shows Zero Drift
Immediately after a successful apply, run a new Plan job:
- [ ] Plan job status = **SUCCEEDED**
- [ ] Plan output shows `No changes. Infrastructure is up-to-date.`
- [ ] Zero resources to add, change, or destroy

---

## Sprint 1 Completion Steps

After all TCs pass:

```bash
# 1. Export Sprint 1 outputs for Sprint 2 team
terraform output -json > sprint1_outputs.json

# 2. Share sprint1_outputs.json with Sprint 2 networking lead
#    Sprint 2 pastes compartment OCIDs into sprint2/terraform.tfvars

# 3. Record in State Book: V1_Validation tab — TC-01 through TC-06b
#    Status: PASS/FAIL, Date, Tester name

# 4. Tag the commit
git add -A
git commit -m "Sprint 1 complete — all TCs passed"
git tag v1-sprint1-complete
git push origin main --tags
```

---

## ORM Deployment

1. OCI Console → Developer Services → Resource Manager → Stacks → Create Stack
2. Source: Git → connect to your GitHub repo → select `sprint1/` folder
3. Working Directory: `sprint1`
4. Name: `STAR-ELZ-V1-Sprint1`
5. Fill in ORM UI form:
   - Section 1: Tenancy OCID + Region
   - Section 2: Service Label = `C1`, CIS Level = `1`, Environment = `poc`
   - Sections 3-5: leave defaults unless workshop isolation needed
6. Plan → Apply
7. After Apply: verify TC-01 through TC-06b

---

## Adding C2 Sub-Compartments (Future)

When you need Level 2 compartments under any C1 compartment:

1. ORM UI → Section 3 → Enable Level 2 Sub-Compartments = `true`
2. In the relevant `iam_cmps_team*.tf`, populate `children : {}`:

```hcl
# Example: add C2_SOC_LOGS under C1_R_ELZ_SOC in iam_cmps_team2.tf
(local.soc_compartment_key) : {
  name     : local.provided_soc_compartment_name,
  children : {
    "SOC-LOGS-CMP" : {
      name        : var.c2_soc_logs_name   # "C2_SOC_LOGS"
      description : "${local.lz_description} — SOC log archive sub-compartment"
    }
  }
}
```

3. `terraform plan` → `terraform apply`
4. No changes needed to `iam_compartments.tf` — the orchestrator merges children automatically.
5. C3 follows the same pattern: add `children : {}` inside the C2 block.
