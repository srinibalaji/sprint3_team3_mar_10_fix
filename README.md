# STAR Enterprise Landing Zone (ELZ) V1

Private · Sovereign Cloud · OCI Infrastructure-as-Code

## Overview

This repository contains the Terraform infrastructure-as-code for the 
STAR Enterprise Landing Zone V1 — a sovereign OCI deployment covering 
IAM, networking, security, and monitoring across hub-spoke architecture.

## Sprint Schedule

| Sprint | Scope | Dates |
|--------|-------|-------|
| Sprint 1 | IAM, Compartments, Policies, Tagging | 24–27 Feb 2026 |
| Sprint 2 | VCN, Subnets, DRG, Routing, Firewall | 2–5 Mar 2026 |
| Sprint 3 | Bastion, Logging, Monitoring, Alarms | 9–10 Mar 2026 |
| Sprint 4 | Compute, AD, DNS, Hello World, Validation | 13–18 Mar 2026 |

## Team Structure

| Team | Terraform File | Compartments |
|------|---------------|--------------|
| Team 1 | `sprint1/iam_cmps_team1.tf` | NW, SEC |
| Team 2 | `sprint1/iam_cmps_team2.tf` | SOC, OPS |
| Team 3 | `sprint1/iam_cmps_team3.tf` | CSVCS, DEVT_CSVCS |
| Team 4 | `sprint1/iam_cmps_team4.tf` | OS_NW, SS_NW, TS_NW, DEVT_NW |

## Branch Naming Convention
```
sprint1/iam-compartments-team1
sprint1/iam-compartments-team2
sprint1/iam-policies
sprint1/tagging
```

## Workflow

1. Pick up your issue from the Kanban board
2. Create your branch from `main` using the naming convention above
3. Edit only your team's file — never touch another team's file
4. Run `terraform fmt` and `terraform validate` locally before pushing
5. Open a PR — reviewer must be from a different team
6. After 1 approval + green CI: merge to main
7. Update your issue status on the board

## Deployment

Sprints are deployed via OCI Resource Manager (ORM).
Oracle team packages and applies each sprint directory after all PRs merge.

## Important

- Never commit `terraform.tfvars` — it contains secrets
- Never push directly to `main` — always use a PR
- State Book: `STAR_ELZ_V1_State_Book_v2.xlsx`

## Contact

Repository owner: @amitpal-source
