# STAR Enterprise Landing Zone (ELZ) V1
**Private · Sovereign Cloud · OCI Infrastructure-as-Code**

---

## Overview

This repository contains the Terraform infrastructure-as-code for the STAR Enterprise Landing Zone V1 — a sovereign OCI deployment covering IAM, networking, security, and monitoring across a hub-and-spoke architecture.

**Region:** ap-singapore-2 · **CIS Level:** 1 · **Architecture:** Hub-and-Spoke via DRG · **State of Record:** [`sprint_state_ledger.json`](./sprint_state_ledger.json)

---

## Sprint Schedule

| Sprint | Scope | Dates | Status |
|--------|-------|-------|--------|
| **Sprint 1** | IAM, Compartments, Groups, Policies, Tagging | 24–27 Feb 2026 | ✅ Code complete — TC-01 to TC-06 validation in progress |
| **Sprint 2** | VCN, Subnets, DRG, Routing, Sim Firewall, Bastion | 2–5 Mar 2026 | 🔄 In progress |
| Sprint 3 | Security (NSGs, SLs, Cloud Guard, Vault), Logging, Flow Logs | 9–10 Mar 2026 | ⏳ Not started |
| Sprint 4 | Compute, AD Bridge, OCI Private DNS, Hello World, E2E Validation | 13–18 Mar 2026 | ⏳ Not started |

---

## Team Structure

### Sprint 1 — IAM (Complete · Validation Pending)

| Team | File | Compartments Provisioned | Groups & Policies |
|------|------|--------------------------|-------------------|
| **Team 1** | `sprint1/iam_cmps_team1.tf` | `C1_R_ELZ_NW`, `C1_R_ELZ_SEC` | — |
| **Team 2** | `sprint1/iam_cmps_team2.tf` | `C1_R_ELZ_SOC`, `C1_R_ELZ_OPS` | `iam_groups.tf` (12 groups), `iam_policies.tf` (38 statements) |
| **Team 3** | `sprint1/iam_cmps_team3.tf` | `C1_R_ELZ_CSVCS`, `C1_R_ELZ_DEVT_CSVCS` | `mon_tags.tf` (ELZ tag namespace, 5 tags) |
| **Team 4** | `sprint1/iam_cmps_team4.tf` | `C1_OS_ELZ_NW`, `C1_SS_ELZ_NW`, `C1_TS_ELZ_NW`, `C1_DEVT_ELZ_NW` + **manual**: `C1_SIM_EXT`, `C1_SIM_CHILD` | GitHub + CI/CD setup |

> **Sprint 1 gate:** TC-01 through TC-06 must all PASS before Sprint 2 Phase 2 apply.
> Validations are tracked in [`sprint_state_ledger.json`](./sprint_state_ledger.json) → `test_cases`.

### Sprint 2 — Networking (In Progress)

Same teams — each team now owns the networking file for the compartment(s) they created in Sprint 1.
Sprint 2 uses a **two-phase apply** — Phase 1 (VCNs + subnets) is simultaneous across all teams; Phase 2 (DRG attachments, route tables, Sim FW, Bastion) requires Team 4 to output `hub_drg_id` first.

| Team | File | Networking Scope | Phase |
|------|------|-----------------|-------|
| **Team 1** | `sprint2/nw_team1.tf` | `C1_OS_ELZ_NW` — OS VCN (10.1.0.0/24), app subnet, DRG attach, Sim FW | Phase 1 + 2 |
| **Team 2** | `sprint2/nw_team2.tf` | `C1_TS_ELZ_NW` — TS VCN (10.3.0.0/24), app subnet, DRG attach, Sim FW | Phase 1 + 2 |
| **Team 3** | `sprint2/nw_team3.tf` | `C1_SS_ELZ_NW` + `C1_DEVT_ELZ_NW` — SS VCN (10.2.0.0/24), DEVT VCN (10.4.0.0/24), subnets, DRG attaches, Sim FW (SS only) | Phase 1 + 2 |
| **Team 4** | `sprint2/nw_team4.tf` | `C1_R_ELZ_NW` — Hub VCN (10.0.0.0/16), FW + MGMT subnets, `drg_r_hub`, `drg_r_ew_hub` (placeholder), Sim FW, OCI Bastion | Phase 1 (outputs `hub_drg_id`) then Phase 2 |

**Two-phase apply — Team 4 runs this after Phase 1:**
```bash
terraform output hub_drg_id
# Share this OCID with Teams 1, 2, 3 before they run Phase 2
```

> **Sprint 2 Phase 1 gate:** TC-07 and TC-08 PASS (5 VCNs, 6 subnets confirmed) before `hub_drg_id` is shared.
> **Sprint 2 Phase 2 gate:** TC-09 through TC-17 all PASS.

---

## Repository Structure

```
star/
├── sprint_state_ledger.json     ← Source of truth: all resources, names, CIDRs, TCs, gaps
├── sprint1/                     ← IAM — compartments, groups, policies, tags
│   ├── iam_cmps_team1.tf        (T1: C1_R_ELZ_NW, C1_R_ELZ_SEC)
│   ├── iam_cmps_team2.tf        (T2: C1_R_ELZ_SOC, C1_R_ELZ_OPS)
│   ├── iam_cmps_team3.tf        (T3: C1_R_ELZ_CSVCS, C1_R_ELZ_DEVT_CSVCS)
│   ├── iam_cmps_team4.tf        (T4: C1_OS_ELZ_NW, C1_SS_ELZ_NW, C1_TS_ELZ_NW, C1_DEVT_ELZ_NW)
│   ├── iam_groups.tf            (T2: 12 UG_ groups)
│   ├── iam_policies.tf          (T2: 38 policy statements)
│   └── mon_tags.tf              (T3: ELZ tag namespace)
├── sprint1-solutions/           ← Reference solutions with all Sprint 1 fixes applied
└── sprint2/                     ← Networking — hub-and-spoke VCN topology
    ├── locals.tf                (all name constants, DNS labels, CIDRs, cloud-init)
    ├── nw_main.tf               (architecture diagram + shared tag locals)
    ├── nw_team1.tf              (T1: OS spoke)
    ├── nw_team2.tf              (T2: TS spoke)
    ├── nw_team3.tf              (T3: SS + DEVT spokes)
    ├── nw_team4.tf              (T4: Hub VCN, both DRGs, Sim FW, Bastion)
    ├── variables_iam.tf         (10 compartment OCIDs — paste from Sprint 1 outputs)
    ├── variables_net.tf         (CIDRs, hub_drg_id, Sim FW shape)
    ├── outputs.tf               (hub_drg_id + all VCN/subnet OCIDs for Sprint 3)
    ├── schema.yaml              (ORM UI — Phase 1/2 labels on hub_drg_id field)
    └── terraform.tfvars.template
```

---

## State of Record

**[`sprint_state_ledger.json`](./sprint_state_ledger.json)** is the single source of truth for this project — not a spreadsheet.

It contains:
- All 12 compartments with canonical names, TF display names, team ownership, and Sprint 1→Sprint 2 variable mappings
- All 12 groups and 38 policy statements
- All 5 VCNs, 2 DRGs, 12 subnets, 12 security lists, 7 NSGs with CIDRs and sprint scope
- 35 test cases (TC-01 to TC-33) with `run_after` phase, commands, and current status
- 6 architecture gaps with actions and owners
- Sprint gates and handoff requirements

Update `test_cases[].status` to `PASS` or `FAIL` as validations are completed.

---

## Branch Naming

```
sprint1/iam-compartments-team1
sprint1/iam-compartments-team2
sprint1/iam-policies
sprint2/nw-team1
sprint2/nw-team2
sprint2/nw-team3
sprint2/nw-team4
```

---

## Workflow

1. Pick up your issue from the Kanban board
2. Create your branch from `main` using the naming convention above
3. Edit **only your team's file** — never touch another team's file
4. Run `terraform fmt` and `terraform validate` locally before pushing
5. Open a PR — reviewer must be from a **different team**
6. After 1 approval + green CI: merge to `main`
7. Update your issue status on the board and mark the corresponding TC in `sprint_state_ledger.json`

---

## Deployment

Sprints are deployed via OCI Resource Manager (ORM). Each sprint directory is a standalone ORM stack. Sprint 2 requires two separate Plan → Apply runs per the two-phase pattern — see `sprint2/README.md` for step-by-step instructions.

---

## Important

- **Never commit `terraform.tfvars`** — it contains compartment OCIDs and secrets
- **Never push directly to `main`** — always use a PR
- **State of record:** [`sprint_state_ledger.json`](./sprint_state_ledger.json) — update it as TCs are validated
- Sprint 2 spoke VCN CIDRs must be set explicitly in `terraform.tfvars` — defaults in variables are `/16` but architecture requires `/24` (see `gaps_and_actions[GAP-01]` in the ledger)

---

## Contact

Repository owner: Oracle and STAR Team

