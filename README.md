# STAR Enterprise Landing Zone (ELZ) V1

**Private · Sovereign Cloud · OCI Infrastructure-as-Code**

Terraform IaC for the STAR ELZ V1 — a sovereign OCI deployment covering IAM, networking, security, and monitoring in a hub-and-spoke architecture.

**Region:** `ap-singapore-2` · **CIS Level:** 1 · **Architecture:** Hub-and-Spoke via DRG · **State of Record:** `sprint_state_ledger.json`

---

## Sprint Schedule

| Sprint | Scope | Dates | Status |
|---|---|---|---|
| Sprint 1 | IAM — Compartments, Groups, Policies, Tags | 24–27 Feb 2026 | ✅ Code complete |
| Sprint 2 | Networking — VCN, Subnet, DRG, Routing, Sim FW, Bastion | 2–5 Mar 2026 | 🔄 In progress |
| Sprint 3 | Security — NSGs, SLs, Cloud Guard, Vault, Logging | 9–10 Mar 2026 | ⏳ Not started |
| Sprint 4 | Compute — AD Bridge, DNS, Hello World, E2E Validation | 13–18 Mar 2026 | ⏳ Not started |

---

## Team Structure

### Sprint 1 — IAM

| Team | Compartment File | Compartments | Other |
|---|---|---|---|
| T1 | `iam_cmps_team1.tf` | C1_R_ELZ_NW, C1_R_ELZ_SEC | `iam_groups_team1.tf` |
| T2 | `iam_cmps_team2.tf` | C1_R_ELZ_SOC, C1_R_ELZ_OPS | `iam_groups_team2.tf`, `iam_policies_team2.tf` |
| T3 | `iam_cmps_team3.tf` | C1_R_ELZ_CSVCS, C1_R_ELZ_DEVT_CSVCS | `iam_groups_team3.tf`, `iam_policies_team3.tf`, `mon_tags.tf` |
| T4 | `iam_cmps_team4.tf` | C1_OS/SS/TS/DEVT_ELZ_NW + manual: C1_SIM_EXT, C1_SIM_CHILD | `iam_groups_team4.tf`, `iam_policies_team4.tf` |

10 TF-managed compartments, 10 TF-managed groups, 7 policies (60 statements), 1 tag namespace + 5 tags. 2 manual compartments (C1_SIM_EXT, C1_SIM_CHILD) and 2 manual groups (UG_SIM_EXT, UG_SIM_CHILD) created via OCI Console.

**Gate:** TC-01 through TC-06b all PASS before Sprint 2 Phase 2 apply.

### Sprint 2 — Networking

| Team | File | Scope | Phase |
|---|---|---|---|
| T1 | `nw_team1.tf` | C1_OS_ELZ_NW — vcn_os_elz_nw (10.1.0.0/24), subnet, DRG attach, Sim FW | 1 + 2 |
| T2 | `nw_team2.tf` | C1_TS_ELZ_NW — vcn_ts_elz_nw (10.3.0.0/24), subnet, DRG attach, Sim FW | 1 + 2 |
| T3 | `nw_team3.tf` | C1_SS + DEVT_ELZ_NW — vcn_ss/devt_elz_nw (10.2/10.4), subnets, DRG attaches, Sim FW (SS only) | 1 + 2 |
| T4 | `nw_team4.tf` | C1_R_ELZ_NW — vcn_r_elz_nw (10.0.0.0/16), FW+MGMT subnets, drg_r_hub, drg_r_ew_hub, Sim FW, Bastion | 1 → 2 |

Two-phase apply: Phase 1 creates VCNs + subnets + DRG. T4 outputs `hub_drg_id`, shares with T1/T2/T3. Phase 2 creates DRG attachments, route tables, Sim FW, Bastion.

**Phase 1 gate:** TC-07, TC-08 PASS (5 VCNs, 6 subnets). **Phase 2 gate:** TC-09 through TC-19 all PASS.

---

## Repository Structure

```
star/
├── README.md
├── sprint_state_ledger.json       ← Source of truth: resources, names, CIDRs, TCs, gaps
├── .gitignore
│
├── docs/
│   ├── ARCHITECT_RUNBOOK.md       ← Sprint-by-sprint deployment guide + CLI commands
│   ├── HANDOFF.md                 ← Sprint 1→2→3 handoff requirements
│   └── SPRINT1_RETRO_QA.md       ← Sprint 1 retro, naming audit, QA answers
│
├── sprint1/                       ← IAM — compartments, groups, policies, tags
│   ├── locals.tf                  (all name constants — single source of truth)
│   ├── iam_cmps_team[1-4].tf      (compartments per team)
│   ├── iam_compartments.tf        (module call — aggregates all team compartments)
│   ├── iam_groups_team[1-4].tf    (groups per team)
│   ├── iam_groups.tf              (module call — aggregates all team groups)
│   ├── iam_policies_team[1-4].tf  (policy statements per team)
│   ├── iam_policies.tf            (module call — aggregates all team policies)
│   ├── mon_tags.tf                (C0-star-elz-v1 namespace, 5 tags)
│   ├── schema.yaml                (ORM UI)
│   └── terraform.tfvars.template
│
└── sprint2/                       ← Networking — hub-and-spoke VCN topology
    ├── locals.tf                  (name constants, DNS labels, CIDRs, phase2 gate, cloud-init)
    ├── nw_main.tf                 (tag merge locals, architecture notes)
    ├── nw_team[1-4].tf            (VCN/subnet/DRG/RT/SimFW per team)
    ├── iam_sprint1_ref.tf         (Sprint 1 IAM reference — read-only, no resources)
    ├── variables_iam.tf           (10 compartment OCIDs from Sprint 1)
    ├── variables_net.tf           (CIDRs, hub_drg_id, Sim FW shape)
    ├── outputs.tf                 (hub_drg_id + all VCN/subnet OCIDs for Sprint 3)
    ├── schema.yaml                (ORM UI — Phase 1/2 labels)
    └── terraform.tfvars.template
```

---

## State of Record

`sprint_state_ledger.json` is the single source of truth — not a spreadsheet. It contains:

- All 12 compartments with canonical names, TF display names, team ownership
- All 12 groups and 60 policy statements across 7 policies
- All 5 VCNs, 2 DRGs, 6 subnets with CIDRs and sprint scope
- 19 test cases (TC-01 to TC-19) with phase gates and CLI commands
- Architecture gaps with actions and owners

Update `test_cases[].status` to PASS/FAIL as validations complete.

---

## Workflow

1. Pick up your issue from the Kanban board
2. Create branch from `main`: `sprint2/nw-team1`, `sprint2/nw-team2`, etc.
3. Edit **only your team's file** — never touch another team's file
4. `terraform fmt` and `terraform validate` before pushing
5. Open PR — reviewer from a different team
6. After approval + green CI → merge to `main`
7. Update issue status and TC in `sprint_state_ledger.json`

---

## Deployment

Sprints deploy via OCI Resource Manager (ORM). Each sprint directory is a standalone ORM stack. Sprint 2 requires two Plan → Apply runs — see `sprint2/README.md` for step-by-step.

---

## Important

- Never commit `terraform.tfvars` — it contains OCIDs and credentials
- Never push directly to `main` — always use a PR
- State of record: `sprint_state_ledger.json` — keep it updated
- All resource display names are defined in `locals.tf` — never hardcode names in team files

---

**Repository owner:** Oracle and STAR Team
