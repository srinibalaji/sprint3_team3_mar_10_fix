# STAR ELZ V1 — Sprint 1: IAM, Governance & Tagging

## Sprint Overview

| Field        | Value                                                                                                        |
| ------------ | ------------------------------------------------------------------------------------------------------------ |
| **Sprint**   | Sprint 1 of 4                                                                                                |
| **Duration** | 2 weeks (10 working days)                                                                                    |
| **Goal**     | Provision 10 TF-managed compartments + 2 manual, 10 TF IAM groups + 2 manual IAM groups, policies, ELZ tags. |
| **Outcome**  | Complete governance skeleton. Zero compute. Zero networking. All IAM proven correct before Sprint 2.         |
| **ORM Zip**  | `STAR_ELZ_Sprint1_IAM.zip`                                                                                   |

---

## Compartment Split — 10 TF + 2 Manual

**Why 2 are manual:** `star-sim-ext-cmp` and `star-sim-child-cmp` are TEMP V1 ONLY simulation compartments — created once, never touched by TF again, deleted entirely in V2. Their OCIDs are passed back as input variables consumed by `sim_temp.tf` in Sprint 4.

### Team Compartment Assignments

| Team       | File                 | Compartments                                                                             | Count  |
| ---------- | -------------------- | ---------------------------------------------------------------------------------------- | ------ |
| **Team 1** | `iam_cmps_team1.tf`  | `star-r-elz-nw-cmp`, `star-r-elz-sec-cmp`                                                | 2      |
| **Team 2** | `iam_cmps_team2.tf`  | `star-r-elz-soc-cmp`, `star-r-elz-ops-cmp`                                               | 2      |
| **Team 3** | `iam_cmps_team3.tf`  | `star-r-elz-csvcs-cmp`, `star-r-elz-devt-csvcs-cmp`                                      | 2      |
| **Team 4** | `iam_cmps_team4.tf`  | `star-os-elz-nw-cmp`, `star-ss-elz-nw-cmp`, `star-ts-elz-nw-cmp`, `star-devt-elz-nw-cmp` | 4      |
| **Team 4** | OCI Console (manual) | `star-sim-ext-cmp`, `star-sim-child-cmp`                                                 | 2      |
|            |                      | **Total**                                                                                | **12** |

`iam_compartments.tf` is the orchestrator — it merges all 4 team maps into one module call. Each team edits only their own `iam_cmps_teamN.tf`. Zero merge conflicts between teams.

---

## Group Split — 10 TF + 2 Manual

**Same orchestrator pattern as compartments.** `iam_groups.tf` merges all 4 team group maps and calls `lz_groups`. Each team owns only their file.

### Team Group Assignments

| Team       | File                  | Groups                                                                               | Count  |
| ---------- | --------------------- | ------------------------------------------------------------------------------------ | ------ |
| **Team 1** | `iam_groups_team1.tf` | `star-ug-elz-nw`, `star-ug-elz-sec`                                                  | 2      |
| **Team 2** | `iam_groups_team2.tf` | `star-ug-elz-soc`, `star-ug-elz-ops`                                                 | 2      |
| **Team 3** | `iam_groups_team3.tf` | `star-ug-elz-csvcs`, `star-ug-devt-csvcs`                                            | 2      |
| **Team 4** | `iam_groups_team4.tf` | `star-ug-os-elz-nw`, `star-ug-ss-elz-nw`, `star-ug-ts-elz-nw`, `star-ug-devt-elz-nw` | 4      |
| **Team 4** | OCI Console (manual)  | `star-ug-sim-ext`, `star-ug-sim-child`                                               | 2      |
|            |                       | **Total**                                                                            | **12** |

---

## Policy Split — 9 Policy Objects across 4 Teams

**Same orchestrator pattern as compartments and groups.** `iam_policies.tf` merges all 4 team policy maps and calls `lz_policies`.

### Team Policy Assignments

| Team       | File                    | Policy Objects                                                                 | Statements |
| ---------- | ----------------------- | ------------------------------------------------------------------------------ | ---------- |
| **Team 1** | `iam_policies_team1.tf` | NW-ADMIN-ROOT-POLICY, NW-ADMIN-POLICY, SEC-ADMIN-ROOT-POLICY, SEC-ADMIN-POLICY | 21         |
| **Team 2** | `iam_policies_team2.tf` | SOC-POLICY, OPS-ADMIN-POLICY                                                   | 10         |
| **Team 3** | `iam_policies_team3.tf` | CSVCS-POLICY, OCI-SERVICES-POLICY                                              | 23         |
| **Team 4** | `iam_policies_team4.tf` | SPOKE-NW-ADMIN-POLICY                                                          | 4          |
|            |                         | **Total**                                                                      | **58**     |

---

## Files in This Sprint

| File                        | Owner           | Purpose                                                   |
| --------------------------- | --------------- | --------------------------------------------------------- |
| `providers.tf`              | All             | OCI provider + home region alias                          |
| `data_sources.tf`           | All             | Tenancy, region, AD lookups                               |
| `variables_general.tf`      | All             | Core variables                                            |
| `variables_iam.tf`          | All             | Compartment name overrides + `sim_*_compartment_id`       |
| `locals.tf`                 | All             | Region helpers, landing zone tags                         |
| `iam_compartments.tf`       | All (read-only) | Compartment orchestrator — merges team maps, calls module |
| `iam_cmps_team1.tf`         | **Team 1**      | NW + SEC compartments                                     |
| `iam_cmps_team2.tf`         | **Team 2**      | SOC + OPS compartments                                    |
| `iam_cmps_team3.tf`         | **Team 3**      | CSVCS + DEVT_CSVCS compartments                           |
| `iam_cmps_team4.tf`         | **Team 4**      | OS + SS + TS + DEVT spoke compartments                    |
| `iam_groups.tf`             | All (read-only) | Group orchestrator — merges team maps, calls module       |
| `iam_groups_team1.tf`       | **Team 1**      | NW-ADMIN-GROUP, SEC-ADMIN-GROUP                           |
| `iam_groups_team2.tf`       | **Team 2**      | SOC-GROUP, OPS-ADMIN-GROUP                                |
| `iam_groups_team3.tf`       | **Team 3**      | CSVCS-ADMIN-GROUP, DEVT-CSVCS-ADMIN-GROUP                 |
| `iam_groups_team4.tf`       | **Team 4**      | OS/SS/TS/DEVT-NW-ADMIN-GROUPs                             |
| `iam_policies.tf`           | All (read-only) | Policy orchestrator — merges team maps, calls module      |
| `iam_policies_team1.tf`     | **Team 1**      | NW + SEC policy objects (4 objects)                       |
| `iam_policies_team2.tf`     | **Team 2**      | SOC + OPS policy objects (2 objects)                      |
| `iam_policies_team3.tf`     | **Team 3**      | CSVCS + OCI service policy objects (2 objects)            |
| `iam_policies_team4.tf`     | **Team 4**      | Spoke NW admin policy object (1 object)                   |
| `mon_tags.tf`               | **Team 3**      | ELZ tag namespace + 5 tags                                |
| `terraform.tfvars.template` | All             | Copy → `terraform.tfvars` and fill in                     |

> Orchestrator files (`iam_compartments.tf`, `iam_groups.tf`, `iam_policies.tf`) require approval from all 4 team leads on any PR that touches them.

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

## Week 1, Day 1 — Manual IAM Groups (Team 4, 10 min)

After creating the two sim compartments above, Team 4 creates two IAM groups manually in OCI Console. These groups correspond to the sim compartments and are **not managed by Terraform** — they are TEMP V1 ONLY and will be deleted in V2.

**Create UG_SIM_EXT:**

```
OCI Console → Identity → Groups → Create Group
  Name:        star-ug-sim-ext
  Description: TEMP V1 ONLY - User group for Simulated External compartment (Dummy AD, DNS). Delete in V2.
```

**Create UG_SIM_CHILD:**

```
OCI Console → Identity → Groups → Create Group
  Name:        star-ug-sim-child
  Description: TEMP V1 ONLY - User group for Simulated Child Tenancy (Hello World). Delete in V2.
```

**Record OCIDs in State Book:**
After creating both groups, copy their OCIDs from the group detail page and record them in the State Book under V1_Manual_Resources tab.

> **Policy note:** UG_SIM_EXT and UG_SIM_CHILD are not covered by the TF-managed policy statements. Team 4 is responsible for determining what policy statements these groups need and adding them — either manually in OCI Console or via a new `iam_policies_sim.tf` file on branch `sprint1/iam-policies-sim`. Hint: at minimum each group needs `manage all-resources in compartment <their-compartment>`.

**TC-02 validation will check for all 12 groups:**

```bash
oci iam group list --compartment-id <tenancy-ocid> --all \
  --query "data[?contains(name,'star')].name | sort(@)" --output table
# Expected: 12 groups — 10 from Terraform + star-ug-sim-ext + star-ug-sim-child
```

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

| Variable                        | Value                       |
| ------------------------------- | --------------------------- |
| `tenancy_ocid`                  | Your tenancy OCID           |
| `region`                        | `ap-singapore-1`            |
| `service_label`                 | `star`                      |
| `cis_level`                     | `1`                         |
| `lz_provenant_label`            | `STAR ELZ Landing Zone`     |
| `sim_ext_compartment_id`        | OCID from manual step above |
| `sim_child_compartment_id`      | OCID from manual step above |
| All `custom_*_compartment_name` | Leave blank                 |

**Plan then Apply:**
Expected plan: `+10 compartments, +10 TF groups, +policy statements, +tags, 0 changes, 0 deletions`

> UG_SIM_EXT and UG_SIM_CHILD are created manually — they will not appear in the TF plan.

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
  --query "data[?contains(name,'star')].name | sort(@)" --output table
# Expected: 12 groups total — 10 TF-managed + 2 manual (UG_SIM_EXT, UG_SIM_CHILD)
```

**PASS:** Exactly 12 groups visible. 10 created by Terraform, 2 created manually by Team 4.

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

### TC-06 — ★ ORM Stack Apply succeeds

```
OCI Console → Developer Services → Resource Manager → Stacks → star-elz-sprint1-iam
→ Terraform Actions → Apply
Expected: Job Status = SUCCEEDED. All resources green.
```

### TC-06b — ★ Zero drift after Apply

```
OCI Console → same Stack → Terraform Actions → Plan
Expected: Job Status = SUCCEEDED. Plan output shows: No changes. Infrastructure is up-to-date.
```

---

## 16-Person Sprint 1 Team Structure

| Team       | Members      | Compartment File              | Groups File                     | Policies File           | Additional Work              |
| ---------- | ------------ | ----------------------------- | ------------------------------- | ----------------------- | ---------------------------- |
| **Team 1** | People 1–4   | `iam_cmps_team1.tf`           | `iam_groups_team1.tf`           | `iam_policies_team1.tf` | Review orchestrators         |
| **Team 2** | People 5–8   | `iam_cmps_team2.tf`           | `iam_groups_team2.tf`           | `iam_policies_team2.tf` | TC-03, TC-04 negative tests  |
| **Team 3** | People 9–12  | `iam_cmps_team3.tf`           | `iam_groups_team3.tf`           | `iam_policies_team3.tf` | `mon_tags.tf` + TC-05        |
| **Team 4** | People 13–16 | `iam_cmps_team4.tf` + Console | `iam_groups_team4.tf` + Console | `iam_policies_team4.tf` | TC-01b manual + GitHub setup |

### Daily Role Rotation (4-day cycle, within each team)

| Day   | Person 1       | Person 2       | Person 3       | Person 4       |
| ----- | -------------- | -------------- | -------------- | -------------- |
| Day 1 | Write code     | Code review    | Run validation | Document       |
| Day 2 | Code review    | Write code     | Document       | Run validation |
| Day 3 | Run validation | Document       | Write code     | Code review    |
| Day 4 | Document       | Run validation | Code review    | Write code     |

### Branch Naming

```
sprint1/iam-compartments-team1   ← Team 1 — compartments
sprint1/iam-compartments-team2   ← Team 2 — compartments
sprint1/iam-compartments-team3   ← Team 3 — compartments
sprint1/iam-compartments-team4   ← Team 4 — compartments
sprint1/iam-groups-team1         ← Team 1 — groups
sprint1/iam-groups-team2         ← Team 2 — groups
sprint1/iam-groups-team3         ← Team 3 — groups
sprint1/iam-groups-team4         ← Team 4 — groups
sprint1/iam-policies-team1       ← Team 1 — policies
sprint1/iam-policies-team2       ← Team 2 — policies
sprint1/iam-policies-team3       ← Team 3 — policies
sprint1/iam-policies-team4       ← Team 4 — policies
sprint1/tagging                  ← Team 3 — tags
sprint1/github-cicd              ← Team 4 — CI/CD
```

**PR rule:** Reviewer must be from a different team. `terraform fmt -check` and `terraform validate` must pass in CI before review can be requested.

---

## GitHub Issues for Sprint 1 Backlog

| #   | Title                                                                                                     | Team   | Priority | Start   | Finish  |
| --- | --------------------------------------------------------------------------------------------------------- | ------ | -------- | ------- | ------- |
| —   | `Provision Cloud Guard`                                                                                   | Oracle | —        | 2/23/26 | 2/23/26 |
| 1   | `[S1-T1] Write & provision NW + SEC compartments (iam_cmps_team1.tf)`                                     | T1     | P0       | 2/24/26 | 2/24/26 |
| 2   | `[S1-T2] Write & provision SOC + OPS compartments (iam_cmps_team2.tf)`                                    | T2     | P0       | 2/24/26 | 2/24/26 |
| 3   | `[S1-T3] Write & provision CSVCS + DEVT_CSVCS compartments (iam_cmps_team3.tf)`                           | T3     | P0       | 2/24/26 | 2/24/26 |
| 4   | `[S1-T4] Write & provision OS + SS + TS + DEVT spoke compartments (iam_cmps_team4.tf)`                    | T4     | P0       | 2/24/26 | 2/24/26 |
| 5   | `[S1-T4] MANUAL: Create star-sim-ext-cmp + star-sim-child-cmp + UG_SIM_EXT + UG_SIM_CHILD in OCI Console` | T4     | P0       | 2/24/26 | 2/24/26 |
| 6   | `[S1-T1] Write & provision 2 IAM groups (iam_groups_team1.tf)`                                            | T1     | P0       | 2/25/26 | 2/25/26 |
| 7   | `[S1-T2] Write & provision 2 IAM groups (iam_groups_team2.tf)`                                            | T2     | P0       | 2/25/26 | 2/25/26 |
| 8   | `[S1-T3] Write & provision 2 IAM groups (iam_groups_team3.tf)`                                            | T3     | P0       | 2/25/26 | 2/25/26 |
| 9   | `[S1-T4] Write & provision 4 IAM groups (iam_groups_team4.tf)`                                            | T4     | P0       | 2/25/26 | 2/25/26 |
| 10  | `[S1-T1] Write & provision policy statements (iam_policies_team1.tf)`                                     | T1     | P0       | 2/25/26 | 2/25/26 |
| 11  | `[S1-T2] Write & provision policy statements (iam_policies_team2.tf)`                                     | T2     | P0       | 2/25/26 | 2/25/26 |
| 12  | `[S1-T3] Write & provision policy statements (iam_policies_team3.tf)`                                     | T3     | P0       | 2/25/26 | 2/25/26 |
| 13  | `[S1-T4] Write & provision policy statements (iam_policies_team4.tf)`                                     | T4     | P0       | 2/25/26 | 2/25/26 |
| 14  | `[S1-T3] Write & provision ELZ tag namespace + 5 tags (mon_tags.tf)`                                      | T3     | P0       | 2/25/26 | 2/25/26 |
| 15  | `[S1-ALL] TC-06: Create ORM Stack and execute Apply Job`                                                  | Oracle | P0       | 2/25/26 | 2/25/26 |
| 16  | `[S1-ALL] TC-06b: Trigger new Plan Job and verify zero drift`                                             | Oracle | P0       | 2/25/26 | 2/25/26 |
| 17  | `[S1-ALL] TC-01: Validate 10 TF compartments`                                                             | All    | P0       | 2/25/26 | 2/25/26 |
| 18  | `[S1-T4] TC-01b: Validate 2 manual sim compartments + OCIDs in tfvars`                                    | T4     | P0       | 2/25/26 | 2/25/26 |
| 19  | `[S1-T2] TC-02: Validate 12 groups (10 TF + 2 manual)`                                                    | All    | P0       | 2/25/26 | 2/25/26 |
| 20  | `[S1-T2] TC-03: NEGATIVE SoD — DEVT cannot write to SEC`                                                  | T2     | P0       | 2/25/26 | 2/25/26 |
| 21  | `[S1-T2] TC-04: NEGATIVE — SOC user read-only`                                                            | T2     | P0       | 2/25/26 | 2/25/26 |
| 22  | `[S1-T3] TC-05: Validate ELZ tags and CostCenter tracking`                                                | T3     | P0       | 2/25/26 | 2/25/26 |

---

## Sprint 1 → Sprint 2 Handoff Checklist

- [ ] TC-01: 10 TF compartments PASS
- [ ] TC-01b: 2 manual compartments + OCIDs in tfvars PASS
- [ ] TC-02: 12 groups PASS (10 TF + 2 manual)
- [ ] TC-03: SoD NEGATIVE PASS (screenshot in Issue #20)
- [ ] TC-04: SOC read-only PASS
- [ ] TC-05: ELZ tags PASS
- [ ] TC-06: ORM Stack Apply Job SUCCEEDED
- [ ] TC-06b: ORM Plan Job shows zero drift PASS
- [ ] `sprint1_outputs.json` exported and shared with Sprint 2 leads
- [ ] All issues moved to **Done**
- [ ] Git tag `v1-sprint1-complete` pushed to main
- [ ] State Book V1_Validation TC-01 to TC-06b updated: PASS/FAIL/date

_Sprint 1 Complete → [Sprint 2 README](../sprint2/README.md)_
