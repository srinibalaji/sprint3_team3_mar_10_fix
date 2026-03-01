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

## Getting Started — Reading Order

Each sprint README is self-contained. Read your sprint README, then your team file — that's enough to start coding.

**Sprint 1 → Sprint 2 path:**

| Step | File | What You'll Learn | Time |
|---|---|---|---|
| 1 | **This file** (`README.md`) | Repo layout, team assignments, sprint schedule | 5 min |
| 2 | [`sprint1/README.md`](sprint1/README.md) | IAM scope, issue list, file map, all test cases (TC-01 to TC-06b), handoff checklist | 10 min |
| 3 | [`sprint1/locals.tf`](sprint1/locals.tf) | All compartment, group, and policy name constants | 5 min |
| 4 | Your team file: `sprint1/iam_cmps_teamN.tf` + `iam_groups_teamN.tf` + `iam_policies_teamN.tf` | Your compartments, groups, policy statements | 5 min |
| 5 | [`sprint2/README.md`](sprint2/README.md) | Networking topology, two-phase apply, issue list, all test cases (TC-07 to TC-19) | 15 min |
| 6 | [`sprint2/locals.tf`](sprint2/locals.tf) | All networking name constants, DNS labels, CIDR plan, phase2 gate | 5 min |
| 7 | Your team file: `sprint2/nw_teamN.tf` | Your VCN, subnet, DRG attachment, route table, Sim FW | 10 min |

Total onboarding: ~55 minutes to full context.

**Supplemental docs (optional — for background and rationale only):**

| File | What It Covers |
|---|---|
| [`docs/ARCHITECT_RUNBOOK.md`](docs/ARCHITECT_RUNBOOK.md) | Detailed deployment script with CLI commands — useful for the architect running ORM |
| [`docs/HANDOFF.md`](docs/HANDOFF.md) | Sprint boundary requirements — what to verify before moving to next sprint |
| [`docs/SPRINT1_RETRO_QA.md`](docs/SPRINT1_RETRO_QA.md) | Naming convention rationale, architecture QA, Sprint 1 retro notes |
| [`sprint_state_ledger.json`](sprint_state_ledger.json) | TC status tracking, resource inventory, architecture gaps |

> **Key principle:** All resource names live in `locals.tf` — never hardcode a display_name string in your team file. Your team file only references `local.*_name` constants.

---

## Team Structure

### Sprint 1 — IAM

**Pre-sprint:** Cloud Guard provisioned by Oracle (23 Feb, manual, tenancy-level).

| # | Task | Team | File | Date |
|---|---|---|---|---|
| S1-T1 | NW + SEC compartments | T1 | `iam_cmps_team1.tf` | 24 Feb |
| S1-T2 | SOC + OPS compartments | T2 | `iam_cmps_team2.tf` | 24 Feb |
| S1-T3 | CSVCS + DEVT_CSVCS compartments | T3 | `iam_cmps_team3.tf` | 24 Feb |
| S1-T4 | OS + SS + TS + DEVT spoke compartments | T4 | `iam_cmps_team4.tf` | 24 Feb |
| S1-T4 | MANUAL: C1_SIM_EXT, C1_SIM_CHILD, UG_SIM_EXT, UG_SIM_CHILD | T4 | Console | 24 Feb |
| S1-T1–T4 | 2 IAM groups each | T1–T4 | `iam_groups_teamN.tf` | 25 Feb |
| S1-T1–T4 | Policy statements each | T1–T4 | `iam_policies_teamN.tf` | 25 Feb |
| S1-T3 | ELZ tag namespace + 5 tags | T3 | `mon_tags.tf` | 25 Feb |

10 TF-managed compartments, 10 TF-managed groups, 11 policies, 1 tag namespace + 5 tags. 2 manual compartments (C1_SIM_EXT, C1_SIM_CHILD) and 2 manual groups (UG_SIM_EXT, UG_SIM_CHILD) created via OCI Console.

**Gate:** TC-01 through TC-06b all PASS before Sprint 2 Phase 2 apply.

### Sprint 2 — Networking

| # | Task | Team | File | Resource |
|---|---|---|---|---|
| S2-T1 | OS: VCN + Subnet + RT + Sim FW | T1 | `nw_team1.tf` | vcn_os_elz_nw (10.1.0.0/24) |
| S2-T2 | TS: VCN + Subnet + RT + Sim FW | T2 | `nw_team2.tf` | vcn_ts_elz_nw (10.3.0.0/24) |
| S2-T3 | SS+DEVT: VCNs + Subnets + RTs + Sim FW (SS) | T3 | `nw_team3.tf` | vcn_ss/devt_elz_nw (10.2/10.4) |
| S2-T4 | Hub: VCN + Subnets + DRGs + RTs + Sim FW + Bastion | T4 | `nw_team4.tf` | vcn_r_elz_nw (10.0.0.0/16) |

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
- All 12 groups and 11 policies
- All 5 VCNs, 2 DRGs, 6 subnets with CIDRs and sprint scope
- 19 test cases (TC-01 to TC-19) with phase gates and CLI commands
- Architecture gaps with actions and owners

Update `test_cases[].status` to PASS/FAIL as validations complete.

---

## Workflow

**ORM Apply is collective — one shared stack per sprint, one Apply for all teams.**

| Action | Who | How Often |
|---|---|---|
| Write your team file, push PR | Each team member | Daily |
| `terraform fmt` + `terraform validate` | Each team member | Before every PR |
| ORM **Plan** (preview only) | Any team member | Anytime — Plan is read-only |
| ORM **Apply** | Oracle / Architect only | Once per phase, after all PRs merged |
| TC validation | All teams | Immediately after each Apply |

Each team writes and tests their own file, but Apply is a single coordinated event. This is because all team resources share one Terraform state. See `sprint1/README.md` and `sprint2/README.md` for phase-specific orchestration.

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
