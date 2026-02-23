# STAR ELZ V1 — Sprint 1: IAM, Governance & Tagging

## Sprint Overview

| Field | Value |
|-------|-------|
| **Sprint** | Sprint 1 of 4 |
| **Duration** | 2 weeks (10 working days) |
| **Goal** | Provision 10 TF-managed compartments + 2 manual, 12 IAM groups, 38 policies, ELZ tags. |
| **Outcome** | Complete governance skeleton. Zero compute. Zero networking. All IAM proven correct before Sprint 2. |
| **ORM Zip** | `STAR_ELZ_Sprint1_IAM.zip` |

---

## Compartment Split — 10 TF + 2 Manual

**Why 2 are manual:** `star-sim-ext-cmp` and `star-sim-child-cmp` are TEMP V1 ONLY simulation compartments — created once, never touched by TF again, deleted entirely in V2. Their OCIDs are passed back as input variables consumed by `sim_temp.tf` in Sprint 4.

### Team Compartment Assignments

| Team | File | Compartments | Count |
|------|------|-------------|-------|
| **Team 1** | `iam_cmps_team1.tf` | `star-r-elz-nw-cmp`, `star-r-elz-sec-cmp` | 2 |
| **Team 2** | `iam_cmps_team2.tf` | `star-r-elz-soc-cmp`, `star-r-elz-ops-cmp` | 2 |
| **Team 3** | `iam_cmps_team3.tf` | `star-r-elz-csvcs-cmp`, `star-r-elz-devt-csvcs-cmp` | 2 |
| **Team 4** | `iam_cmps_team4.tf` | `star-os-elz-nw-cmp`, `star-ss-elz-nw-cmp`, `star-ts-elz-nw-cmp`, `star-devt-elz-nw-cmp` | 4 |
| **Team 4** | OCI Console (manual) | `star-sim-ext-cmp`, `star-sim-child-cmp` | 2 |
| | | **Total** | **12** |

`iam_compartments.tf` is the orchestrator — it merges all 4 team maps into one module call. Each team edits only their own `iam_cmps_teamN.tf`. Zero merge conflicts between teams.

---

## Files in This Sprint

| File | Team | Purpose |
|------|------|---------|
| `providers.tf` | All | OCI provider + home region alias |
| `data_sources.tf` | All | Tenancy, region, AD lookups |
| `variables_general.tf` | All | Core variables |
| `variables_iam.tf` | All | Compartment name overrides + `sim_*_compartment_id` |
| `locals.tf` | All | Region helpers, landing zone tags |
| `iam_compartments.tf` | All (read-only) | Module orchestrator — merges team maps, calls module |
| `iam_cmps_team1.tf` | **Team 1** | NW + SEC |
| `iam_cmps_team2.tf` | **Team 2** | SOC + OPS |
| `iam_cmps_team3.tf` | **Team 3** | CSVCS + DEVT_CSVCS |
| `iam_cmps_team4.tf` | **Team 4** | OS + SS + TS + DEVT spokes |
| `iam_groups.tf` | Team 2 (all review) | 12 IAM groups |
| `iam_policies.tf` | **Team 2** | 38 policy statements |
| `mon_tags.tf` | **Team 3** | ELZ tag namespace + 5 tags |
| `terraform.tfvars.template` | All | Copy → `terraform.tfvars` and fill in |

> `iam_compartments.tf` requires approval from all 4 team leads on any PR that touches it. It should only change if a compartment is added or a key renamed.

---

## Week 1, Day 1 — Manual Compartments First (Team 4, 10 min)

Do this before any Terraform runs. These two sim compartments are created once in Console.

**Create star-sim-ext-cmp:**
```
OCI Console → Identity → Compartments → Create Compartment
  Name:        star-sim-ext-cmp
  Description: TEMP V1 ONLY - Simulated External (Dummy AD, DNS). Delete in V2.
  Parent:      (root)
  Tags:        ELZ.Environment = POC  |  ELZ.ManagedBy = Manual
```
Copy OCID.

**Create star-sim-child-cmp:**
```
OCI Console → Identity → Compartments → Create Compartment
  Name:        star-sim-child-cmp
  Description: TEMP V1 ONLY - Simulated Child Tenancy (Hello World). Delete in V2.
  Parent:      (root)
  Tags:        ELZ.Environment = POC  |  ELZ.ManagedBy = Manual
```
Copy OCID.

**Record in terraform.tfvars:**
```hcl
sim_ext_compartment_id   = "ocid1.compartment.oc1.ap-singapore-1.xxxxx"
sim_child_compartment_id = "ocid1.compartment.oc1.ap-singapore-1.yyyyy"
```

> These variables are unused in Sprint 1–3. Sprint 1–3 plan output will show them as unused — this is correct. They are only consumed by `sim_temp.tf` in Sprint 4.

---

## ORM Deploy — Step by Step

**Prepare zip:**
```bash
cd sprint1/
zip STAR_ELZ_Sprint1_IAM.zip *.tf terraform.tfvars.template
# Never include terraform.tfvars in the zip — it has your OCID
```

**Create Stack:**
OCI Console → Developer Services → Resource Manager → Stacks → Create Stack → upload zip → Next

**Variables to set:**

| Variable | Value |
|----------|-------|
| `tenancy_ocid` | Your tenancy OCID |
| `region` | `ap-singapore-1` |
| `service_label` | `star` |
| `cis_level` | `1` |
| `lz_provenant_label` | `STAR ELZ Landing Zone` |
| `sim_ext_compartment_id` | OCID from manual step above |
| `sim_child_compartment_id` | OCID from manual step above |
| All `custom_*_compartment_name` | Leave blank |

**Plan then Apply:**
Expected plan: `+10 compartments, +12 groups, +38 policy statements, +6 tags, 0 changes, 0 deletions`

---

## Validation Tests

### TC-01 — ★ 10 TF compartments created
```bash
oci iam compartment list \
  --compartment-id <tenancy-ocid> \
  --compartment-id-in-subtree false --all \
  --query "data[?contains(name,'star')].name | sort(@)" --output table
# Expected: 10 names matching team assignments above (no sim- names)
```
**PASS:** Exactly 10. All names correct. All parent = root.

### TC-01b — 2 manual sim compartments exist + OCIDs in tfvars
```bash
oci iam compartment list --compartment-id <tenancy-ocid> --all \
  --query "data[?contains(name,'sim')].{name:name,id:id}" --output table
# Expected: star-sim-ext-cmp and star-sim-child-cmp both present
```
**PASS:** Both visible. OCIDs match tfvars entries. Tags show `ManagedBy = Manual`.

### TC-02 — ★ 12 IAM groups created
```bash
oci iam group list --compartment-id <tenancy-ocid> --all \
  --query "data[?contains(name,'UG_')].name | sort(@)" --output table
# Expected: 12 groups
```
**PASS:** Exactly 12 groups.

### TC-03 — ★ NEGATIVE: DEVT user cannot write to SEC
```bash
# As UG_DEVT_ELZ_NW member:
oci kms management vault create \
  --compartment-id <star-r-elz-sec-cmp-ocid> \
  --display-name test-sod --vault-type DEFAULT
# Expected: NotAuthorizedOrNotFound (403/404)
```
**PASS:** Error returned. Nothing created.

### TC-04 — ★ NEGATIVE: SOC user read-only
```bash
# As UG_ELZ_SOC member:
oci logging log-group delete --log-group-id <any-ocid>
# Expected: NotAuthorizedOrNotFound (403)
```

### TC-05 — ★ ELZ tags: 5 tags, CostCenter cost-tracking enabled
```bash
oci iam tag list --tag-namespace-id <elz-ns-ocid> \
  --query "data[].{name:name,costTracking:\"is-cost-tracking\"}" --output table
# Expected: CostCenter isCostTracking=true, all others false
```

### TC-06 — ★ terraform plan zero drift
```bash
terraform plan -detailed-exitcode
# Expected: exit code 0, "No changes."
```

---

## 16-Person Sprint 1 Team Structure

| Team | Members | Compartment File | Additional Work |
|------|---------|-----------------|----------------|
| **Team 1** | People 1–4 | `iam_cmps_team1.tf` (NW, SEC) | Review iam_compartments.tf |
| **Team 2** | People 5–8 | `iam_cmps_team2.tf` (SOC, OPS) | `iam_policies.tf` + negative tests |
| **Team 3** | People 9–12 | `iam_cmps_team3.tf` (CSVCS, DEVT_CSVCS) | `mon_tags.tf` + tag validation |
| **Team 4** | People 13–16 | `iam_cmps_team4.tf` (spokes) + Console manual | GitHub setup + CI/CD |

### Daily Role Rotation (4-day cycle, within each team)

| Day | Person 1 | Person 2 | Person 3 | Person 4 |
|-----|----------|----------|----------|----------|
| Day 1 | Write code | Code review | Run validation | Document |
| Day 2 | Code review | Write code | Document | Run validation |
| Day 3 | Run validation | Document | Write code | Code review |
| Day 4 | Document | Run validation | Code review | Write code |

### Branch Naming

```
sprint1/iam-compartments-team1   ← Team 1
sprint1/iam-compartments-team2   ← Team 2
sprint1/iam-compartments-team3   ← Team 3
sprint1/iam-compartments-team4   ← Team 4
sprint1/iam-policies             ← Team 2
sprint1/tagging                  ← Team 3
sprint1/github-cicd              ← Team 4
```

**PR rule:** Reviewer must be from a different team. `terraform fmt -check` and `terraform validate` must pass in CI before review can be requested.

---

## GitHub Issues for Sprint 1 Backlog (16 issues)

| # | Title | Team | Priority |
|---|-------|------|---------|
| 1 | `[S1-T1] Provision NW + SEC compartments (iam_cmps_team1.tf)` | T1 | P0 |
| 2 | `[S1-T2] Provision SOC + OPS compartments (iam_cmps_team2.tf)` | T2 | P0 |
| 3 | `[S1-T3] Provision CSVCS + DEVT_CSVCS compartments (iam_cmps_team3.tf)` | T3 | P0 |
| 4 | `[S1-T4] Provision OS + SS + TS + DEVT spoke compartments (iam_cmps_team4.tf)` | T4 | P0 |
| 5 | `[S1-T4] MANUAL: Create star-sim-ext-cmp and star-sim-child-cmp in OCI Console` | T4 | P0 |
| 6 | `[S1-T2] Provision 38 policy statements (iam_policies.tf)` | T2 | P0 |
| 7 | `[S1-T2] Provision 12 IAM groups (iam_groups.tf)` | T2 | P0 |
| 8 | `[S1-T3] Provision ELZ tag namespace + 5 tags (mon_tags.tf)` | T3 | P0 |
| 9 | `[S1-ALL] TC-01: Validate 10 TF compartments` | All | P0 |
| 10 | `[S1-T4] TC-01b: Validate 2 manual sim compartments + OCIDs in tfvars` | T4 | P0 |
| 11 | `[S1-T2] TC-02: Validate 12 groups` | T2 | P0 |
| 12 | `[S1-T2] TC-03: NEGATIVE SoD — DEVT cannot write to SEC` | T2 | P0 |
| 13 | `[S1-T2] TC-04: NEGATIVE — SOC user read-only` | T2 | P0 |
| 14 | `[S1-T3] TC-05: Validate ELZ tags and CostCenter tracking` | T3 | P0 |
| 15 | `[S1-ALL] TC-06: Create ORM Stacks and then execute an APPLY Job` | T4 | P0 |
| 16 | `[S1-ALL] TC-06b: Trigger a new PLAN Job against the existing Stack and review the job logs for any drift` | T4 | P0 |


---

## Sprint 1 → Sprint 2 Handoff Checklist

- [ ] TC-01: 10 TF compartments PASS
- [ ] TC-01b: 2 manual compartments + OCIDs in tfvars PASS
- [ ] TC-02: 12 groups PASS
- [ ] TC-03: SoD NEGATIVE PASS (screenshot in Issue #13)
- [ ] TC-04: SOC read-only PASS
- [ ] TC-05: ELZ tags PASS
- [ ] TC-06: ORM Stack operation and Job both return success PASS
- [ ] TC-06b: ensuring zero drift after full Sprint 1 apply PASS
- [ ] `sprint1_outputs.json` exported and shared with Sprint 2 leads
- [ ] All 16 GitHub issues moved to **Done**
- [ ] Git tag `v1-sprint1-complete` pushed to main
- [ ] State Book V1_Validation TC-01 to TC-06 updated: PASS/FAIL/date

*Sprint 1 Complete → [Sprint 2 README](../sprint2/README.md)*
